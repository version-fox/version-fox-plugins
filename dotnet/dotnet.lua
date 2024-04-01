---    Copyright 2024 [liquidiert haberederkorbinian@googlemail.com]
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
local html = require("html")

OS_TYPE = ""
ARCH_TYPE = ""

BARE_URL = "https://dotnet.microsoft.com"
VERSIONS_URL = "https://dotnet.microsoft.com/en-us/download/dotnet"

PLUGIN = {
    --- Plugin name
    name = "dotnet",
    --- Plugin author
    author = "Korbinian Habereder",
    --- Plugin version
    version = "0.0.2",
    description = "dotnet plugin, support for dotnet sdks 6.0, 7.0, 8.0",
    -- Update URL
    --updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/dotnet/dotnet.lua",
    manifestUrl = "https://github.com/version-fox/vfox-dotnet/releases/download/manifest/manifest.json",
    minRuntimeVersion = "0.3.0",
}

function PLUGIN:PreInstall(ctx)
    local releases = self:Available(ctx)
    for _, release in ipairs(releases) do
        if release.version == ctx.version then
            return release
        end
    end
    return {}
end

function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    local result = {}
    local versions = {}
    local resp, err = http.get({
        url = VERSIONS_URL
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Getting releases failed: " .. err)
    end
    local type = getOsTypeAndArch()
    local doc = html.parse(resp.body)
    local tableDoc = doc:find("table")
    -- first find available sdk versions
    tableDoc:find("tbody"):first():find("tr"):each(function(ti, ts)
        local td = ts:find("td")
        local downloadLink = td:eq(0):find("a"):attr("href")
        local support = td:eq(1):text()
        local installableVersion = td:eq(3):text()
        local endOfLife = td:eq(5):text():gsub("\n", ""):gsub("%s+$", "")
        table.insert(versions, {
            version = installableVersion,
            url = BARE_URL .. downloadLink,
            note = "End of Support: " .. endOfLife,
            -- sha256 = nil,
        })
    end)
    -- then find os and arch specific version
    for _, version in ipairs(versions) do
        local resp, err = http.get({
            url = version.url
        })
        if err ~= nil or resp.status_code ~= 200 then
            error("Getting specific versions failed: " .. err)
        end
        local downloadDoc = html.parse(resp.body)
        local tableDoc = downloadDoc:find("table"):first():find("tbody"):first()
        local osSpecifics = tableDoc:find("tr")

        local downloadUrl = ""
        
        if type.osType == "Linux" then
            local archVersions = osSpecifics:eq(0):find("td"):eq(1):find("a")
            if type.archType == "x64" then
                downloadUrl = archVersions:eq(4):attr("href")
            elseif type.archType == "Arm64" then
                downloadUrl = archVersions:eq(2):attr("href")
            elseif type.archType == "x86" then
                error("Can't provide dotnet for x86 architecture linux")
            end
        elseif type.osType == "macOS" then
            local archVersions = osSpecifics:eq(1):find("td"):eq(1):find("a")
            if type.archType == "x64" then
                downloadUrl = archVersions:eq(1):attr("href")
            elseif type.archType == "Arm64" then
                downloadUrl = archVersions:eq(0):attr("href")
            end
        elseif type.osType == "Windows" then
            local archVersions = osSpecifics:eq(2):find("td"):eq(1):find("a")
            if type.archType == "x64" then
                downloadUrl = archVersions:eq(1):attr("href")
            elseif type.archType == "Arm64" then
                downloadUrl = archVersions:eq(0):attr("href")
            elseif type.archType == "x86" then
                downloadUrl = archVersions:eq(2):attr("href")
            end
        end

        -- after getting download url parse direct download link and checksum
        local resp, err = http.get({
            url = BARE_URL .. downloadUrl
        })
        if err ~= nil or resp.status_code ~= 200 then
            error("Getting specific versions failed: " .. err)
        end

        local directLinkDoc = html.parse(resp.body)
        local directLink = directLinkDoc:find("a#directLink"):attr("href")
        local checksum = directLinkDoc:find("input#checksum"):attr("value")

        table.insert(result, {
            version = version.version,
            url = directLink,
            note = version.note,
            sha512 = checksum
        })
    end
    return result
end


function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "macOS"
    elseif OS_TYPE == "linux" then
        osType = "Linux"
    elseif OS_TYPE == "windows" then
        osType = "Windows"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "Arm64"
    elseif ARCH_TYPE == "386" then
        archType = "x86"
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    return {
        {
            key = "DOTNET_ROOT",
            value = mainPath
        },
        {
            key = "PATH",
            value = mainPath
        }
    }
end