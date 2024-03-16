--- Common libraries provided by VersionFox (optional)
local http = require("http")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

PLUGIN = {
    --- Plugin name
    name = "erlang",
    --- Plugin author
    author = "yeshan333",
    --- Plugin version
    version = "0.0.1",
    --- Plugin description
    description = "install Erlang/OTP from source by vfox",
    -- Update URL
    updateUrl = "https://github.com/version-fox/version-fox-plugins/erlang/otp.lua",
    -- minimum compatible vfox version
    minRuntimeVersion = "0.2.2",
}

local function check_version_existence(url)
    local resp, err = http.get({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Please confirm whether the corresponding Erlang/OTP release version exists! visit: https://github.com/erlang/otp/releases")
    end
end

local function check_platform()
    if OS_TYPE == "windows" then
        error("Windows is not supported. Please direct use the offcial installer to setup Erlang/OTP. visit: https://www.erlang.org/downloads")
    end
end

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    check_platform()

    local erlang_version = ctx.version
    if erlang_version == nil then
        error("You must provide a version number for Erlang/OTP, eg: vfox install erlang@24.1")
    end
    check_version_existence("https://github.com/erlang/otp/releases/tag/OTP-" .. erlang_version)

    local download_url = "https://github.com/erlang/otp/archive/refs/tags/OTP-" .. erlang_version .. ".tar.gz"
    return {
        version = erlang_version,
        url = download_url
    }
end

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local compile_args = os.getenv("OTP_COMPILE_ARGS") or ""
    print("Erlang/OTP compile with: %s", compile_args)
    print("If you enable some Erlang/OTP features, maybe you can reference this guide: https://github.com/asdf-vm/asdf-erlang?tab=readme-ov-file#before-asdf-install")
    os.execute("sleep " .. tonumber(3))

    local sdkInfo = ctx.sdkInfo['erlang']
    local path = sdkInfo.path
    local status, _exitType, _code = os.execute("cd " .. path .. " && ./configure --prefix=" .. path .. "/release " .. compile_args .. "&& make && make install")
    if status == false then
        error("Erlang/OTP install failed, please check the stdout for details. Make sure you have the required utilties: https://www.erlang.org/doc/installation_guide/install#required-utilitiesvc")
    end
    -- correspond: ./configure --prefix=/home/username/.version-fox/cache/erlang/v-25.3.2.10/erlang-25.3.2.10/release ${compile_args}
end

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    -- local runtimeVersion = ctx.runtimeVersion
    return {
        PLUGIN,
    }
end

--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- @param ctx table Context information
--- @field ctx.path string SDK installation directory
function PLUGIN:EnvKeys(ctx)
    --- this variable is same as ctx.sdkInfo['plugin-name'].path
    -- local mainPath = ctx.path
    local mainPath = ctx.path .. "/release/bin"
    return {
        {
            key = "PATH",
            value = mainPath
        },
    }
end

--- When user invoke `use` command, this function will be called to get the
--- valid version information.
--- @param ctx table Context information
function PLUGIN:PreUse(ctx)
    -- local runtimeVersion = ctx.runtimeVersion
    -- --- user input version
    local input_version = ctx.version
    -- --- installed sdks
    local sdkInfo = ctx.installedSdks[input_version]
    local use_version = sdkInfo.version

    --- return the version information
    return {
        version = use_version
    }
end