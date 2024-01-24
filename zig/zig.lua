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

PLUGIN = {
    name = "zig",
    author = "aooohan",
    version = "0.0.2",
    description = "Zig",
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/zig/zig.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local releases = self:Available({})
    if version == "latest" then
        return releases[2]
    end
    for _, release in ipairs(releases) do
        if release.version == version then
            return release
        elseif release.note == version then
            return release
        end
    end
    return {}
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
        url = BaseUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local archs = getArchArr()
    local os = getOsType()
    local body = json.decode(resp.body)
    local result = {}
    for k, v in pairs(body) do
        local version = k
        local note = ""
        if k == "master" then
            version = v.version
            note = "nightly"
        end
        for _, arch in ipairs(archs) do
            local key = arch .. "-" .. os
            if v[key] ~= nil then
                if k == "master" then
                    table.insert(result, 1, {
                        version = version,
                        url = v[key].tarball,
                        sha256 = v[key].shasum,
                        note = note,
                    })
                else
                    table.insert(result, {
                        version = version,
                        url = v[key].tarball,
                        sha256 = v[key].shasum,
                        note = note,
                    })
                end
            end
        end
    end
    table.sort(result, compare_versions)
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
        archType = {
            "aarch64",
        }
    elseif ARCH_TYPE == "386" then
        archType = {
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
function PLUGIN:PostInstall(ctx)
end

function PLUGIN:EnvKeys(ctx)
    local version_path = ctx.path
    return {
        {
            key = "PATH",
            value = version_path
        },
    }
end
