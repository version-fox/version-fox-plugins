--- Common libraries provided by VersionFox (optional)
local http = require("http")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

PLUGIN = {
    --- Plugin name
    name = "elixir",
    --- Plugin author
    author = "yeshan333",
    --- Plugin version
    version = "0.0.1",
    --- Plugin description
    description = "Elixir vfox plugin, support for managing multiple OTP versions.",
    -- Update URL
    updateUrl = "https://github.com/version-fox/version-fox-plugins/elixir/elixir.lua",
    -- minimum compatible vfox version
    minRuntimeVersion = "0.2.2",
}

local function check_version_existence(url)
    local resp, err = http.get({
        url = url
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("Please confirm whether the corresponding Elixir release version exists! visit: https://github.com/elixir-lang/elixir/releases")
    end
end

local function check_platform()
    if OS_TYPE == "windows" then
        error("Windows is not supported. Please direct use the offcial installer to setup Elixir. visit: https://elixir-lang.org/install.html#windows")
    end
end

local function check_erlang_existence()
    print("Check Erlang/OTP existence...")
    local status = os.execute("which erlc")
    if status ~= 0 then
        error("Please install Erlang/OTP before you install Elixir.")
    end
end

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    check_platform()
    check_erlang_existence()

    local elixir_version = ctx.version
    if elixir_version == nil then
        error("You must provide a version number for Elixir, eg: vfox install elixir@1.16.2")
    end
    check_version_existence("https://github.com/elixir-lang/elixir/releases/tag/v" .. elixir_version)

    local download_url = "https://github.com/elixir-lang/elixir/archive/refs/tags/v" .. elixir_version .. ".tar.gz"
    return {
        version = elixir_version,
        url = download_url
    }
end

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    local sdkInfo = ctx.sdkInfo['elixir']
    local path = sdkInfo.path
    local status = os.execute("cd " .. path .. " && make")
    if status ~= 0 then
        error("Elixir install failed, please check the stdout for details.")
    end
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
    local mainPath = ctx.path .. "/bin"
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