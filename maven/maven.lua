local http = require("http")
local html = require("html")

OS_TYPE = ""
ARCH_TYPE = ""

MAVEN_URL = "https://archive.apache.org/dist/maven/"
FILE_URL = "https://archive.apache.org/dist/maven/maven-%s/%s/binaries/apache-maven-%s-bin.tar.gz"
CHECKSUM_URL = "https://archive.apache.org/dist/maven/maven-%s/%s/binaries/apache-maven-%s-bin.tar.gz.%s"

PLUGIN = {
    --- Plugin name
    name = "maven",
    --- Plugin author
    author = "Han Li",
    --- Plugin version
    version = "0.0.1",
    -- Update URL
    updateUrl = "https://github.com/version-fox/version-fox-plugins/blob/main/maven/maven.lua",
}

function PLUGIN:PreInstall(ctx)
    local v = ctx.version
    local major = string.sub(v, 1, 1)
    if tonumber(major) ~= nil then
        if major == "3" or major == "4" then
            local checksums = {
                sha512 = CHECKSUM_URL:format(major, v, v, "sha512"),
                md5 = CHECKSUM_URL:format(major, v, v, "md5"),
                sha1 = CHECKSUM_URL:format(major, v, v, "sha1"),
            }
            for k, url in pairs(checksums) do
                local resp, err = http.get({
                    url = url
                })
                if err == nil and resp.status_code == 200 then
                    local result = {
                        version = v,
                        url = FILE_URL:format(major, v, v),
                    }
                    result[k] = resp.body
                    return result
                end
            end
        else
            error("invalid version: " .. v)
        end
    else
        error("invalid version: " .. v)
    end
    return {}
end


function PLUGIN:PostInstall(ctx)
end

function PLUGIN:Available(ctx)
    local m4 = parseVersion("maven-4/")
    local m3 = parseVersion("maven-3/")
    for _, v in ipairs(m3) do
        table.insert(m4, v)
    end
    table.sort(m4, function(a, b)
        return a.version > b.version
    end)
    return m4
end

function parseVersion(path)
    local resp, err = http.get({
        url = MAVEN_URL .. path
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("paring release info failed." .. err)
    end
    local result = {}
    html.parse(resp.body):find("a"):each(function(i, selection)
        local href = selection:attr("href")
        local sn = string.match(href, "^%d")
        local es = string.match(href, "/$")
        if sn and es then
            table.insert(result, {
                version = string.sub(href, 1, -2),
                note = "",
            })
        end
    end)
    return result
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