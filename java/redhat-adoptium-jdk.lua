---    Copyright 2024 [axdank axdank@proton.me]
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

AvailableVersionsUrl = "https://marketplace-api.adoptium.net/v1/info/available_releases/redhat"
DownloadLatestUrl = "https://marketplace-api.adoptium.net/v1/assets/latest/redhat/%s/hotspot"

PLUGIN = {
    name = "java",
    author = "axdank",
    version = "0.0.4",
    description = "RedHat JDK - Adoptium",
    --updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/java/redhat-adoptium-jdk.lua",
    minRuntimeVersion = "0.3.0",
    manifestUrl = "https://github.com/version-fox/vfox-java/releases/download/manifest/manifest.json"
}

function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    if version == nil or version == "" then
      return nil
    end

    if tonumber(version) == nil then
        error("invalid version: " .. ctx.version)
    end

    local type = getOsTypeAndArch()

    local resp, err = http.get({
        url = DownloadLatestUrl:format(version)
    })

    if err ~= nil then
        error(err)
    end

    if resp.status_code ~= 200 then
        return nil
    end

    local body = json.decode(resp.body)
    local binaryInfo = nil

    for _, bin in pairs(body) do
      local bin_os = bin.binary.os
      local bin_arch = bin.binary.architecture
      local bin_type = bin.binary.image_type
      if bin_os == type.osType and bin_arch == type.archType and bin_type == "jdk" then
        binaryInfo = bin
        break
      end
    end

    if binaryInfo == nil then
      return nil
    else
      return {
          version = version,
          url = binaryInfo.binary.package.link,
          sha256 = (binaryInfo.binary.package.sha265sum or nil),
      }
    end

end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "mac"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    elseif ARCH_TYPE == "386" then
        archType = "x32"
    end
    return {
        osType = osType, archType = archType
    }
end

function PLUGIN:Available(ctx)
    local resp, err = http.get({
        url = AvailableVersionsUrl
    })
    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end
    local body = json.decode(resp.body)
    local ltsMap = {}
    for _, v in ipairs(body.available_lts_releases) do
        ltsMap[v] = v
    end
    local result = {}
    for _, v in ipairs(body.available_releases) do
        local note = ""
        if ltsMap[v] ~= nil then
            note = "LTS"
        end
        table.insert(result, {
            version = v .. '',
            note = note,
        })
    end
    return result
end

function PLUGIN:EnvKeys(ctx)
    local path = ctx.path
    if OS_TYPE == "darwin" then
        path = path .. "/Contents/Home"
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
