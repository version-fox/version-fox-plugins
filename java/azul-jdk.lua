---    Copyright 2024 [yimiao yimiaoxiehou@gmail.com]
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

-- api from azul swagger https://api.azul.com/metadata/v1/docs/swagger
AzulMetadataUrl = "https://api.azul.com/metadata/v1/zulu/packages/?release_status=ga&availability_types=CA&certifications=tck&page=1&page_size=1000&java_package_type=jdk&archive_type=zip&latest=true&os=%s&arch=%s"
AzulBinaryInfo = "https://api.azul.com/metadata/v1/zulu/packages/%s"

PLUGIN = {
    name = "java",
    author = "yimiaoxiehou",
    version = "0.0.1",
    description = "Azul JDK, also known as Zulu",
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/java/azul-jdk.lua",
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    if tonumber(version) == nil then
        error("invalid version: " .. ctx.version)
    end

    local type = getOsTypeAndArch()
    local url = AzulMetadataUrl:format(type.osType, type.archType)
    url = url.."&java_version="..version
    local resp, err = http.get({
        url = url
    })
    if err ~= nil then
        error(err)
    end
    if resp.status_code ~= 200 then
        return nil
    end
    local body = json.decode(resp.body)
    local result = {
        version = version,
        url = body[1].download_url,
    }

    resp, err = http.get({
        url = AzulBinaryInfo:format(body[1].package_uuid)
    })
    if err ~= nil then
        error(err)
    end
    if resp.status_code ~= 200 then
        return nil
    end
    local body = json.decode(resp.body)
    result.sha256 = body.sha256_hash
    return result
end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "macosx"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    elseif ARCH_TYPE == "386" then
        archType = "i686"
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:Available(ctx)
    local type = getOsTypeAndArch()
    -- get lts version
    local url = AzulMetadataUrl:format(type.osType, type.archType)
    url = url.."&support_term=lts"
    local resp, err = http.get({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local ltsVersions = {}
    for _, v in ipairs(body) do
        table.insert(ltsVersions, v.java_version[1]) 
    end
    ltsVersions = removeDuplicates(ltsVersions)

    -- all version
    local result = {}
    local versions = {}
    resp, err = http.get({
        url = AzulMetadataUrl:format(type.osType, type.archType)
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    body = json.decode(resp.body)
    for _, v in ipairs(body) do
        table.insert(versions, v.java_version[1]) 
    end
    
    versions = removeDuplicates(versions)
    for _, v in ipairs(versions) do
        if hasElement(ltsVersions, v) then
            table.insert(result, {
                version = v,
                note = "LTS",
            })
        else
            table.insert(result, {
                version = v,
                note = "",
            })
        end
    end
    return result
end

function PLUGIN:EnvKeys(ctx)
    local path = ctx.path
    local version = ctx.version
    if OS_TYPE == "darwin" then
        path = path .. "/zulu-"..version..".jdk/Contents/Home"
    end
    return {
        {
            key = "JAVA_HOME",
            value = path
        },
        {
            key = "PATH",
            value = path .. "/bin"
        }
    }
end

function removeDuplicates(arr)
    local hash = {}
    local result = {}
    for _, value in ipairs(arr) do
        if not hash[value] then
        hash[value] = true
        table.insert(result, value)
        end
    end
return result
end


function hasElement(array, element)
    for _, value in ipairs(array) do
        if value == element then
        return true
        end
    end
    return false
end
