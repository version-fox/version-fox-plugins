---  Default global variable
---  OS_TYPE:  windows, linux, darwin
---  ARCH_TYPE: 386, amd64, arm, arm64  ...
local http = require("http")
local json = require("json")

OS_TYPE = ""
ARCH_TYPE = ""

NodeBaseUrl = "https://nodejs.org/dist/v%s/"
FileName = "node-v%s-%s-%s%s"
npmDownloadUrl = "https://github.com/npm/cli/archive/v%s.%s"

VersionSourceUrl = "https://nodejs.org/dist/index.json"

PLUGIN = {
    name = "node",
    author = "aooohan",
    version = "0.0.1",
    description = "Node.js",
    updateUrl = "https://github.com/aooohan/version-fox-plugins/blob/main/node/node.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    local arch_type = ARCH_TYPE
    local ext = ".tar.gz"
    local osType = OS_TYPE
    if arch_type == "amd64" then
        arch_type = "x64"
    end
    if OS_TYPE == "windows" then
        ext = ".zip"
        osType = "win"
    end
    local filename = FileName:format(version, osType, arch_type, ext)
    local baseUrl = NodeBaseUrl:format(version)

    local resp, err = http.get({
        url = baseUrl .. "SHASUMS256.txt"
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get checksum failed")
    end
    local checksum = get_checksum(resp.body, filename)
    return {
        version = version,
        url = baseUrl .. filename,
        checksum = checksum,
    }
end

function get_checksum(file_content, file_name)
    for line in string.gmatch(file_content, '([^\n]*)\n?') do
        local checksum, name = string.match(line, '(%w+)%s+(%S+)')
        if name == file_name then
            return checksum
        end
    end
    return nil
end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = VersionSourceUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local result = {}
    for _, v in ipairs(body) do
        table.insert(result, {
            version = string.gsub(v.version, "^v", ""),
            note = v.lts and "LTS" or "",
            additional = {
                {
                    name = "npm",
                    version = v.npm,
                }
            }
        })
    end
    return result
end

--- Expansion point
function PLUGIN:PostInstall(ctx)
    local rootPath = ctx.rootPath
    local sdkInfo = ctx.sdkInfo['node']
    local path = sdkInfo.path
    local version = sdkInfo.version
    local name = sdkInfo.name
end

function PLUGIN:EnvKeys(ctx)
    local version_path = ctx.path
    if OS_TYPE == "windows" then
        return {
            {
                key = "PATH",
                value = version_path
            },
        }
    else
        return {
            {
                key = "PATH",
                value = version_path .. "/bin"
            },
        }
    end
end
