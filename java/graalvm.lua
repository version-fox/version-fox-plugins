
--- Common libraries provided by VersionFox (optional)
local http = require("http")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

AvailableVersionsUrl = "https://www.graalvm.org/downloads/"
DownloadInfoUrl = "https://download.oracle.com/graalvm/%s/latest/graalvm-jdk-%s_%s-%s_bin.%s"

PLUGIN = {
    --- Plugin name
    name = "graalvm",
    --- Plugin author
    author = "ahai",
    --- Plugin version
    version = "0.0.1",
    --- Plugin description
    description = "graalvm JDK",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/java/graalvm.lua",
    -- minimum compatible vfox version
    minRuntimeVersion = "0.2.2",
}


function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local type = getOsTypeAndArch()
    local downloadUrl = DownloadInfoUrl:format(version, version,type.osType,type.archType, type.suffixType)

    print(version)
    print(downloadUrl)
    local resp, err = http.get({
        url = downloadUrl..".sha256"
    })
    if err ~= nil then
        error(err)
    end

    if resp.status_code ~= 200 then
        return nil
    end

    local sha256 = resp.body

    return {
        version = version,
        sha256 = sha256,
        url = downloadUrl,
    }
end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    local suffixType = "tar.gz"
    if OS_TYPE == "darwin" then
        osType = "macos"
    end

    if OS_TYPE == "windows" then
        suffixType = "zip"
    end

    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    elseif ARCH_TYPE == "386" then
        error("win32 is not supported at this time ")
    end
    return {
        osType = osType, archType = archType,suffixType = suffixType
    }
end

function PLUGIN:PostInstall(ctx)

end


function PLUGIN:Available(ctx)
    --- get htmlBody
    local resp, err = http.get({
        url = AvailableVersionsUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local htmlBody = resp.body
    --- get version
    local htmlContent= [[]] .. htmlBody .. [[]]

    local result = {}
    for match in htmlContent:gmatch('<button%s+class="downloads_dropbtn"%s+id="selector%-java%-version">(.-)<div%s+class="downloads_dropdown">') do
        for item in match:gmatch('<a[^>]*>(.-)</a>') do
            for number in item:gmatch("%d+") do
                table.insert(result, {version=tonumber(number),note="latest"})
            end
        end
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
            key = "GRAALVM_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
end