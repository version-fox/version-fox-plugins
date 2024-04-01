---    Copyright 2024 [lihan aooohan@gmail.com]
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.

local http = require("http")
local json = require("json")

OS_TYPE = ""
ARCH_TYPE = ""

BaseUrl = "https://ziglang.org/download/index.json"
MachUrl = "https://machengine.org/zig/index.json"

PLUGIN = {
    name = "zig",
    author = "aooohan",
    version = "0.0.5",
    description = "Zig",
    --updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/zig/zig.lua",
    minRuntimeVersion = "0.3.0",
    manifestUrl = "https://github.com/version-fox/vfox-zig/releases/download/manifest/manifest.json"
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local releases = self:Available({})
    for _, release in ipairs(releases) do
        if release.version == version then
            return release
        else
            for note in string.gmatch(release.note, "[^|]+") do
                if note == version then
                    return release
                end
            end
        end
    end
    return {}
end

function compare_versions(v1o, v2o)
    local v1 = v1o.version
    local v2 = v2o.version
    local v1_parts = {}
    for part in string.gmatch(v1, "[^.+-]+") do
        table.insert(v1_parts, tonumber(part))
    end

    local v2_parts = {}
    for part in string.gmatch(v2, "[^.+-]+") do
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
    local archs = getArchArr()
    local os = getOsType()
    local base = getResults(BaseUrl, archs, os, "tarball")
    local mach = getResults(MachUrl, archs, os, "zigTarball")

    --merge the two together
    for k, v in pairs(mach) do
        if v.note == "nightly" then
            goto continue
        end
        if base[k] == nil then
            base[k] = v
        elseif base[k].note ~= "" then
            base[k].note = base[k].note .. "|" .. v.note
        end
        ::continue::
    end

    -- Need an list to sort it
    local result = {}
    for _, v in pairs(base) do
        table.insert(result, v)
    end
    table.sort(result, compare_versions)

    -- Get the first non-noted version to dictate latest
    for _, v in ipairs(result) do
        if v.note == "" then
            v.note = "latest"
            break
        end
    end
    return result
end

function getResults(url, archs, os, tar)
    local resp, err = http.get({
        url = url,
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local body = json.decode(resp.body)
    local result = {}
    for k, v in pairs(body) do
        local version = k
        local note = ""
        if v.version ~= nil then
            version = v.version
            if k == "master" then
                note = "nightly"
            else
                note = k
            end
        end
        for _, arch in ipairs(archs) do
            local key = arch .. "-" .. os
            if v[key] ~= nil then
                if result[version] ~= nil then
                    result[version].note = result[version].note .. "|" .. note
                else
                    result[version] = {
                        version = version,
                        url = v[key][tar],
                        sha256 = v[key].shasum,
                        note = note,
                    }
                end
            end
        end
    end
    return result
end

function getOsType()
    if OS_TYPE == "darwin" then
        return "macos"
    end
    return OS_TYPE
end

function getArchArr()
    if ARCH_TYPE == "amd64" then
        return {
            "x86_64",
        }
    elseif ARCH_TYPE == "arm64" then
        return {
            "aarch64",
        }
    elseif ARCH_TYPE == "386" then
        return {
            "x86",
            "i386",
        }
    else
        return {
            ARCH_TYPE,
        }
    end
end

--- Expansion point
function PLUGIN:PostInstall(ctx) end

function PLUGIN:EnvKeys(ctx)
    local version_path = ctx.path
    return {
        {
            key = "PATH",
            value = version_path,
        },
    }
end
