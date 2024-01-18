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

VersionURL =
"https://storage.googleapis.com/storage/v1/b/dart-archive/o?delimiter=/&prefix=channels/%s/release/&alt=json"
DownloadURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip"
SHA256URL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip.sha256sum"
LatestVersionURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/latest/VERSION"
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
    local arg = ctx.version
    local type = getOsTypeAndArch()
    if arg == "stable" or arg == "dev" or arg == "beta" then
        local resp, err = http.get({
            url = LatestVersionURL:format(arg)
        })
        if err ~= nil or resp.status_code ~= 200 then
            error("get version failed" .. err)
        end
        local latestVersion = json.decode(resp.body)
        local version = latestVersion.version
        local sha256Url = SHA256URL:format(arg, version, type.osType, type.archType)
        local r = {
            version = version,
            url = DownloadURL:format(arg, version, type.osType, type.archType),
            sha256 = extractChecksum(sha256Url)
        }
        return r
    else
        local releases = self:Available({})
        for _, info in ipairs(releases) do
            if info.version == arg then
                return {
                    version = info.version,
                    url = info.url,
                    sha256 = extractChecksum(info.sha256)
                }
            end
        end
    end
end

function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    local result = {}
    parseReleases("stable", result)
    parseReleases("dev", result)
    parseReleases("beta", result)
    table.sort(result, function(a, b)
        return a.version > b.version
    end)
    return result
end

function extractChecksum(url)
    local resp, err = http.get({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get checksum failed" .. err)
    end
    local checksum = resp.body:match("^(%w+)%s")
    return checksum
end

function parseReleases(devType, resultArr)
    local type = getOsTypeAndArch()
    local resp, err = http.get({
        url = VersionURL:format(devType)
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local body = json.decode(resp.body)
    for _, info in ipairs(body.prefixes) do
        local version = extractVersions(info)
        if version ~= nil then
            table.insert(resultArr, {
                version = version,
                url = DownloadURL:format(devType, version, type.osType, type.archType),
                sha256 = SHA256URL:format(devType, version, type.osType, type.archType),
                note = devType,
            })
        end
    end
end

function extractVersions(str)
    local version = str:match(".*/(.-)/$")
    if version and not version:match("^%d+$") and version ~= "latest" then
        return version
    end
    return nil
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
