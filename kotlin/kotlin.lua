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
local html = require("html")

OS_TYPE = ""
ARCH_TYPE = ""

DownloadURL = "https://github.com/JetBrains/kotlin/releases/download/v%s/kotlin-compiler-%s.zip"


PLUGIN = {
    name = "kotlin",
    author = "Aooohan",
    version = "0.0.1",
    description = "Kotlin plugin",
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/kotlin/kotlin.lua",
    minRuntimeVersion = "0.2.3",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if version == "latest" then
        local lists = self:Available({})
        version = lists[1].version
    end
    local url = DownloadURL:format(version, version)
    local resp, err = http.head({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Current version information not detected.")
    end
    resp, err = http.get({
        url = url .. ".sha256"
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Current version checksum not detected.")
    end

    return {
        version = version,
        url = url,
        sha256 = resp.body
    }

end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = "https://kotlinlang.org/docs/releases.html#release-details"
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local result = {}
    html.parse(resp.body):find("tbody tr"):each(function(i, sel)
        local version = sel:find("td b"):first():text()
        table.insert(result, {
            version = version,
            note = "",
        })
    end)
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
            value = version_path .. "/bin"
        },
    }
end
