
--- Common libraries provided by VersionFox (optional)
local http = require("http")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

PLUGIN = {
    --- Plugin name
    name = "gradle",
    --- Plugin author
    author = "ahai",
    --- Plugin version
    version = "0.0.1",
    --- Plugin description
    description = "gradle",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/gradle/gradle.lua",
    -- minimum compatible vfox version
    minRuntimeVersion = "0.2.3",
}

AvailableVersionsUrl = "https://gradle.org/releases/"
DownloadInfoUrl = "https://services.gradle.org/distributions/gradle-%s-bin.zip"


function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local downloadUrl = DownloadInfoUrl:format(version)

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

function PLUGIN:PostInstall(ctx)
   
end

function compare_versions(v1o, v2o)
    local v1 = v1o.version
    local v2 = v2o.version
    local v1_parts = {}
    for part in string.gmatch(v1, "[^.]+") do
        table.insert(v1_parts, tonumber(part))
    end

    local v2_parts = {}
    for part in string.gmatch(v2, "[^.]+") do
        table.insert(v2_parts, tonumber(part))
    end

    for i = 1, math.max(#v1_parts, #v2_parts) do
        local v1_part = v1_parts[i] or 0
        local v2_part = v2_parts[i] or 0
        if v1_part > v2_part then
            return true
        elseif v1_part < v2_part then
            return false
        end
    end

    return false
end


function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = AvailableVersionsUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local htmlBody = resp.body
    local htmlContent= [[]] .. htmlBody .. [[]]

    local result = {}

    for version in htmlContent:gmatch('<a name="(.-)"></a>') do
        table.insert(result, {version=version,note=""})
    end
    table.sort(result, compare_versions)

    return result
end


function PLUGIN:EnvKeys(ctx)
    local path = ctx.path
    return {
        {
            key = "GRADLE_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
end
