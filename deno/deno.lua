---    Copyright 2024 Han Li
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
---  Default global variable
---  OS_TYPE:  windows, linux, darwin
---  ARCH_TYPE: 386, amd64, arm, arm64  ...
local http = require("http")

OS_TYPE = ""
ARCH_TYPE = ""

ReleaseURL = "https://raw.githubusercontent.com/denoland/deno/main/Releases.md"

DownloadURL = "https://github.com/denoland/deno/releases/download/v%s/%s"

PLUGIN = {
    name = "deno",
    author = "aooohan",
    version = "0.0.1",
    description = "Deno plugin, https://deno.com/",
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/deno/deno.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    local type = getOsTypeAndArch()
    if version == "latest" then
        local lists = self:Available({})
        version = lists[1].version
    end
    local filename = "deno-" .. type.archType .. "-" .. type.osType .. ".zip"
    return {
        version = version,
        url = DownloadURL:format(version, filename),
    }

end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "apple-darwin"
    elseif OS_TYPE == "windows" then
        osType = "pc-windows-msvc"
    elseif OS_TYPE == "linux" then
        osType = "unknown-linux-gnu"
    else
        error("dart does not support" .. OS_TYPE .. "os")
    end
    if ARCH_TYPE == "amd64" then
        archType = "x86_64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    else
        error("Deno does not support" .. ARCH_TYPE .. "architecture")
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = ReleaseURL
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local result = {}
    for line in string.gmatch(resp.body, '([^\n]*)\n?') do
        if string.match(line, "^###") then
            local start = string.sub(line, 5)
            local version = string.sub(start, 1, -14)
            if string.sub(version, 1, 1) == "v" then
                version = string.sub(version, 2)
            end
            table.insert(result, {
                version = version,
                note = ""
            })
        end
    end
    return result
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
