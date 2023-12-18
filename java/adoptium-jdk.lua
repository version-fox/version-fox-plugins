local http = require("http")
local json = require("json")

OS_TYPE = ""
ARCH_TYPE = ""

SearchUrl = "https://api.adoptium.net/v3/assets/latest/%s/hotspot?os=%s&architecture=%s"
AvailableVersionsUrl = "https://api.adoptium.net/v3/info/available_releases"
DownloadInfoUrl = "https://api.adoptium.net/v3/assets/feature_releases/%s/ga?architecture=%s&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=%s&page=0&page_size=1&project=jdk&sort_method=DEFAULT&sort_order=DESC&vendor=eclipse"

PLUGIN = {
    name = "adoptium_jdk",
    author = "aooohan",
    version = "0.0.1",
    description = "Adoptium JDK",
    updateUrl = "https://github.com/aooohan/version-fox-plugins/blob/main/java/adoptium-jdk.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    if tonumber(version) == nil then
        error("invalid version: " .. ctx.version)
    end

    local type = getOsTypeAndArch()

    local resp, err = http.get({
        url = DownloadInfoUrl:format(version, type.archType, type.osType)
    })
    if err ~= nil then
        error(err)
    end
    if resp.status_code ~= 200 then
        return nil
    end

    local body = json.decode(resp.body)
    local downloadInfo = body[1]
    local binaryInfo = downloadInfo.binaries[1]

    return {
        version = version,
        url = binaryInfo.package.link,
        sha256 = binaryInfo.package.checksum,
    }

end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "mac"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    elseif ARCH_TYPE == "386" then
        archType = "x32"
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = AvailableVersionsUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local ltsMap = {}
    for _, v in ipairs(body.available_lts_releases) do
        ltsMap[v] = v
    end
    local result = {}
    for _, v in ipairs(body.available_releases) do
        local note = ""
        if ltsMap[v] ~= nil then
            note = "LTS"
        end
        table.insert(result, {
            version = v,
            note = note,
        })
    end
    return result
end

function PLUGIN:EnvKeys(ctx)
    local path = ctx.path
    if OS_TYPE == "darwin" then
        path = path .. "/Contents/Home"
    end
    return {
        {
            key = "JAVA_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
end
