--- Common libraries provided by VersionFox (optional)
local http = require("http")
local json = require("json")
local html = require("html")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

URL = "https://www.php.net"

PLUGIN = {
    --- Plugin name
    name = "php",
    --- Plugin author
    author = "Chance",
    --- Plugin version
    version = "0.0.1",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/php/php.lua",
    -- minimum compatible vfox version
    minRuntimeVersion = "0.2.2",
}

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    if OS_TYPE == "windows" then
        return getReleaseForWindows(version)
    else
        return getReleaseForLinux(version)
    end
end

function getReleaseForWindows(version)
    local baseUrl = "https://windows.php.net/downloads/releases/archives/"
    local resp, err = http.get({
        url = baseUrl
    })
    local doc = html.parse(resp.body)
    local prefix = "php-" .. version .. "-nts"
    local x86, x64 = "", ""
    doc:find("a"):each(function(i, selection)
        local filename = selection:text()
        if string.sub(filename, 1, #prefix) == prefix then
            if string.find(filename, "x86") then
                x86 = filename
            end
            if string.find(filename, "x64") then
                x64 = filename
            end
        end
    end)

    local url = ""

    if (ARCH_TYPE == "amd64" or ARCH_TYPE == "arm64") and x64 ~= "" then
        url = baseUrl .. x64
    end
    if ARCH_TYPE == "386" and x86 ~= "" then
        url = baseUrl .. x86
    end

    if url ~= "" then
        return {
            version = version,
            url = url
        }
    end
end

function getReleaseForLinux(version)
    local resp, err = http.get({
        url = URL .. "/releases/index.php?json&version=" .. version
    })
    local data = json.decode(resp.body)

    local filename, md5, sha256 = "", "", ""
    for _, s in ipairs(data["source"]) do
        if string.match(s.filename, "%.tar%.gz$") then
            filename = s.filename
            md5 = s.md5
            sha256 = s.sha256
            break
        end
    end
    return {
        version = version,
        url = URL .. "/distributions/" .. filename,
        sha256 = sha256,
        md5 = md5
    }
end

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    local rootPath = ctx.rootPath
    local sdkInfo = ctx.sdkInfo["php"]
    local path = sdkInfo.path
    local version = sdkInfo.version
    local name = sdkInfo.name
    if OS_TYPE == "windows" then
        return
    end

    local install_path = rootPath .. "/tmp-" .. version
    os.execute("mv " .. path .. " " .. install_path)
    os.execute("cd " .. install_path .. " && ./configure --prefix=" .. path .." --enable-bcmath --enable-calendar --enable-dba --enable-exif --enable-fpm --enable-ftp --enable-gd --enable-gd-native-ttf --enable-intl --enable-mbregex --enable-mbstring --enable-mysqlnd --enable-pcntl --enable-shmop --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-wddx --enable-zip --sysconfdir=" .. path .." --with-config-file-path=" .. path .." --with-config-file-scan-dir=" .. path .."/conf.d --with-curl --with-external-gd --with-fpm-group=www-data --with-fpm-user=www-data --with-gd --with-mhash --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-xmlrpc --with-zip --with-zlib --without-snmp --with-openssl")
    os.execute("cd " .. install_path .. " && make")
    os.execute("cd " .. install_path .. " && make install")
    os.execute("rm -rf " .. install_path)
    os.execute("cd " .. path .. "/bin && curl -sS https://getcomposer.org/installer | ./php -- --install-dir=./")
    os.execute("cd " .. path .. "/bin && mv composer.phar composer")
end

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local result = {}
    local resp, err = http.get({
        url = URL .. "/releases"
    })
    local doc = html.parse(resp.body)

    doc:find("#layout-content h2"):each(function(i, selection)
        local versionStr = selection:text()
        if compareVersions(versionStr, "5.2.10") >= 0 then
            table.insert(result, {
                version = versionStr,
            })
        end
    end)

    table.sort(result, function(a, b)
        return compareVersions(a.version, b.version) > 0
    end)
    return result
end

function compareVersions(v1, v2)
    local v1_parts = {}
    for part in string.gmatch(v1, "[^.]+") do
        table.insert(v1_parts, tonumber(part))
    end

    local v2_parts = {}
    for part in string.gmatch(v2, "[^.]+") do
        table.insert(v2_parts, tonumber(part))
    end

    for i = 1, math.max(#v1_parts, #v2_parts) do
        local v1_part = v1_parts[i] or 0
        local v2_part = v2_parts[i] or 0
        if v1_part > v2_part then
            return 1
        elseif v1_part < v2_part then
            return -1
        end
    end

    return 0
end

--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- @param ctx table Context information
--- @field ctx.path string SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    local bin = ""
    if OS_TYPE ~= "windows" then
        bin = "/bin"
    end

    return {
        {
            key = "PATH",
            value = mainPath .. bin
        }
    }
end
