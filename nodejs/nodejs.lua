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
    name = "nodejs",
    author = "Aooohan",
    version = "0.0.4",
    description = "Node.js",
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/nodejs/nodejs.lua",
}

local is_debug = os.getenv("DEBUG")

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if version == "latest" then
        local result = self:Available({})
        version = result['list'][1].version
    end

    if not is_semver_simple(version) then
        local result = self:Available({})
        version = result['versions_shorthand'][version]
        if is_debug then
            print_table(result, 0)
        end
    end

    if (version == nil) then
        error("version not found for provided version " .. version)
    end

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
        sha256 = checksum,
    }
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

function get_checksum(file_content, file_name)
    for line in string.gmatch(file_content, '([^\n]*)\n?') do
        local checksum, name = string.match(line, '(%w+)%s+(%S+)')
        if name == file_name then
            return checksum
        end
    end
    return nil
end

available_result = nil

function PLUGIN:Available(ctx)
    if available_result then
        return available_result
    end

    local resp, err = http.get({
        url = VersionSourceUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local list = {}
    local versions_shorthand = {}

    for _, v in ipairs(body) do
        local version = string.gsub(v.version, "^v", "")
        local major, minor = extract_semver(version)
        table.insert(list, {
            version = version,
            note = v.lts and "LTS" or "",
            addition = {
                {
                    name = "npm",
                    version = v.npm,
                }
            }
        })
        if major then
            if not versions_shorthand[major] then
                versions_shorthand[major] = version
            else
                if compare_versions({version = version}, {version = versions_shorthand[major]}) then
                    versions_shorthand[major] = version
                end
            end

            if minor then
                local major_minor = major .. "." .. minor
                if not versions_shorthand[major_minor] then
                    versions_shorthand[major_minor] = version
                else
                    if compare_versions({version = version}, {version = versions_shorthand[major_minor]}) then
                        versions_shorthand[major_minor] = version
                    end
                end
            end
        end
    end

    table.sort(list, compare_versions)

    local result = {}
    result['list'] = list
    result['versions_shorthand'] = versions_shorthand
    available_result = result
    return result
end

--- Expansion point
function PLUGIN:PostInstall(ctx)
    local rootPath = ctx.rootPath
    local sdkInfo = ctx.sdkInfo['nodejs']
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

function is_semver_simple(str)
    -- match pattern: three digits, separated by dot
    local pattern = "^%d+%.%d+%.%d+$"
    return str:match(pattern) ~= nil
end

function extract_semver(semver)
    local pattern = "^(%d+)%.(%d+)%.[%d.]+$"
    local major, minor = semver:match(pattern)
    return major, minor
end

function print_table(t, indent)
    indent = indent or 0
    local strIndent = string.rep("  ", indent)
    for key, value in pairs(t) do
        local keyStr = tostring(key)
        local valueStr = tostring(value)
        if type(value) == "table" then
            print(strIndent .. "[" .. keyStr .. "] =>")
            print_table(value, indent + 1)
        else
            print(strIndent .. "[" .. keyStr .. "] => " .. valueStr)
        end
    end
end
