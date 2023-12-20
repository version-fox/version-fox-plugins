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
local html = require("html")

OS_TYPE = ""
ARCH_TYPE = ""

PYTHON_URL =  "https://www.python.org/downloads/"

PLUGIN = {
    --- Plugin name
    name = "python",
    --- Plugin author
    author = "Han Li",
    --- Plugin version
    version = "0.0.1",
    -- Update URL
    updateUrl = "https://github.com/aooohan/version-fox-plugins/blob/main/python/python.lua",
}

function PLUGIN:PreInstall(ctx)
    return {
        version = "3.9.8",
        url = "https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz",
        md5= "51c5c22dcbc698483734dff5c8028606",
    }
end

function PLUGIN:PostInstall(ctx)
    --- TODO
end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = PYTHON_URL
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local doc = html.parse(resp.body)
    local listDoc = doc:find("div.download-list-widget ol.list-row-container")
    local result = {}
    listDoc:find("li"):each(function(i, selection)
        local versionStr = selection:find("span.release-number"):first():text()
        local v = string.match(versionStr, "Python%s(%d+%.%d+%.%d+)")
        result[i] = {
            version = v,
            note = "",
        }
    end)
    return result
end

function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.version_path
    return {
        {
            key = "JAVA_HOME",
            value = mainPath
        },
        {
            key = "PATH",
            value = mainPath .. "/bin"
        }
    }
end