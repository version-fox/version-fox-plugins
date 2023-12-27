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

VersionURL = "https://storage.googleapis.com/storage/v1/b/dart-archive/o?delimiter=%2F&prefix=channels%2F%s%2Frelease%2F&alt=json"
DownloadURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip"
SHA256URL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip.sha256sum"
PLUGIN = {
    --- Plugin name
    name = "dart",
    --- Plugin author
    author = "aooohan",
    --- Plugin version
    version = "0.0.1",
    description = "dart plugin, support for getting stable, dev, beta version",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/dart/dart.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local releases = self:Available({})
    for _, info in ipairs(releases) do
        if info.version == version then
            return {
                version = info.version,
                url = info.url,
                sha256 = info.sha256
            }
        end
    end
end

function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    local type = getOsTypeAndArch()
    local resp, err = http.get({
        url = VersionURL:format("stable")
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local body = json.decode(resp.body)
    local result = {}
    for _, info in ipairs(body.prefixes) do
        local version = extractVersions(info)
        table.insert(result, {
            version = info.version,
            url = body.base_url .. "/" .. info.archive,
            sha256 = info.sha256,
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

function extractVersions(str)
    local versions = {}
    for version in string.gmatch(str, "/([^/,]+)/?") do
        table.insert(versions, version)
    end
    return versions
end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "macos"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "386" then
        archType = "ia32"
    else
        error("dart does not support" .. ARCH_TYPE .. "architecture")
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