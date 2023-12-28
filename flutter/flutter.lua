---    Copyright 2023 [lihan aooohan@gmail.com]
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

BASE_URL = "https://storage.googleapis.com/flutter_infra_release/releases/releases_%s.json"

--- https://go.dev/dl/go1.21.5.darwin-arm64.tar.gz
PLUGIN = {
    --- Plugin name
    name = "flutter",
    --- Plugin author
    author = "Han Li",
    --- Plugin version
    version = "0.0.2",
    description = "flutter plugin, support for getting stable, dev, beta version",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/flutter/flutter.lua",
}

function PLUGIN:PreInstall(ctx)
    local arg = ctx.version
    if arg == "beta" or arg == "dev" or arg == "stable" then
        local type = getOsTypeAndArch()
        local resp, err = http.get({
            url = BASE_URL:format(type.osType)
        })
        if err ~= nil or resp.status_code ~= 200 then
            error("get version failed" .. err)
        end
        local body = json.decode(resp.body)
        local cr = body.current_release
        local key = cr[arg]
        local releases = self:Available({})
        for _, info in ipairs(releases) do
            if info.key == key then
                return {
                    version = info.version,
                    url = info.url,
                    sha256 = info.sha256
                }
            end
        end
    end
    local releases = self:Available({})
    for _, info in ipairs(releases) do
        if info.version == arg then
            return {
                version = info.version,
                url = info.url,
                sha256 = info.sha256
            }
        end
    end
    return nil
end

function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    local type = getOsTypeAndArch()
    local resp, err = http.get({
        url = BASE_URL:format(type.osType)
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local body = json.decode(resp.body)
    local result = {}
    for _, info in ipairs(body.releases) do
        local version = info.version
        local oldVersion = string.sub(version, 1, 1) == "v"
        if oldVersion then
            break
        end
        table.insert(result, {
            version = info.version,
            url = body.base_url .. "/" .. info.archive,
            sha256 = info.sha256,
            key = info.hash,
            note = info.channel,
            addition = {
                {
                    name = "dart",
                    version = info.dart_sdk_version
                }
            }
        })
    end
    return result
end


function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "macos"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "arm64"
    else
        error("flutter does not support" .. ARCH_TYPE .. "architecture")
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin"
        }
    }
end