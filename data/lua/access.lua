--==============================================================================
-- SPanel Access Phase
-- Xử lý truy cập - Authentication, Rate Limiting, WAF
--==============================================================================

local ngx = ngx
local var = ngx.var
local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local WARN = ngx.WARN

local ngx_shared = ngx.shared
local spanel_shm = ngx_shared.spanel_shm
local waf_shm = ngx_shared.waf_shm

-- Đọc cấu hình
local function get_config()
    local env = os.getenv
    return {
        waf_enabled = env("WAF_ENABLED") or "true",
        waf_mode = env("WAF_MODE") or "active",
        rate_limit = env("RATE_LIMIT_ENABLED") or "true",
        rate_limit_req = tonumber(env("RATE_LIMIT_REQUESTS") or "100"),
        rate_limit_window = tonumber(env("RATE_LIMIT_WINDOW") or "60")
    }
end

-- WAF check
local function waf_check()
    local config = get_config()
    if config.waf_enabled ~= "true" then
        return true
    end

    local waf = require "waf"
    local result = waf.check()

    if not result.pass then
        var.waf_check_result = "block"
        var.waf_matched_rule = result.rule or ""
        var.waf_matched_var = result.var or ""

        log(ERR, "[WAF] Blocked: ", var.remote_addr, " - ", result.reason)

        if config.waf_mode == "active" then
            return false, result.reason
        end
    end

    return true
end

-- Rate limit check
local function rate_limit_check()
    local config = get_config()
    if config.rate_limit ~= "true" then
        return true
    end

    local key = "rate_limit:" .. var.remote_addr
    local limit = config.rate_limit_req
    local window = config.rate_limit_window

    local current = spanel_shm:get(key)
    if current and current >= limit then
        log(WARN, "[RateLimit] Limited: ", var.remote_addr)
        return false, "Rate limit exceeded"
    end

    local ok, err = spanel_shm:incr(key, 1)
    if not ok then
        spanel_shm:set(key, 1, window)
    end

    return true
end

-- IP whitelist check
local function is_ip_whitelisted()
    local ip = var.remote_addr
    local whitelist = spanel_shm:get("whitelist:" .. ip)
    return whitelist == true
end

-- MAIN access logic
local config = get_config()

-- Skip cho internal requests
if var.server_addr == var.remote_addr then
    return
end

-- Check IP whitelist
if is_ip_whitelisted() then
    return
end

-- WAF check
local waf_ok, waf_reason = waf_check()
if not waf_ok then
    if config.waf_mode == "active" then
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end
end

-- Rate limit check
local rl_ok, rl_reason = rate_limit_check()
if not rl_ok then
    ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
    return
end

log(WARN, "[SPanel] Access allowed: ", var.remote_addr, " ", var.request_uri)