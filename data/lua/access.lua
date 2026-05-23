--==============================================================================
-- SPanel Access Phase - Proxy Logic
-- Luồng xử lý:
-- 1. Có querystring HOẶC WordPress cookies → bypass cache → next phase
-- 2. Không có querystring VÀ không có WP cookies → check cache
--    - Cache hit → serve cached response
--    - Cache miss → next phase
-- 3. WAF check
-- 4. WAF pass → vào backend (proxy_pass)
--==============================================================================

local ngx = ngx
local var = ngx.var
local log = ngx.log
local ERR = ngx.ERR
local WARN = ngx.WARN
local HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local HTTP_TOO_MANY_REQUESTS = ngx.HTTP_TOO_MANY_REQUESTS
local HTTP_OK = ngx.HTTP_OK

local ngx_shared = ngx.shared
local spanel_shm = ngx_shared and ngx_shared.spanel_shm
local waf_shm = ngx_shared and ngx_shared.waf_shm

-- Cookie names that indicate dynamic content (bypass cache)
local WP_COOKIES = {
    "wordpress_test_cookie",
    "wordpress_logged_in_",
    "wp-settings-",
    "wp-settings-time-",
    "wordpress_",
    "comment_author_",
    "woocommerce_",
    "edd_wp_session",
    "tk_ai"
}

--==============================================================================
-- CONFIG
--==============================================================================

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

--==============================================================================
-- CACHE CHECK
--==============================================================================

-- Check if request should bypass cache
local function should_bypass_cache()
    local args = var.args or ""
    local uri = var.request_uri or ""

    -- Bypass if has querystring
    if args and args ~= "" then
        var.bypass_cache = "1"
        var.cache_action = "bypass_querystring"
        return true
    end

    -- Bypass if has WordPress cookies
    local headers = ngx.req.get_headers()
    local cookie_header = headers["cookie"] or ""

    if cookie_header and cookie_header ~= "" then
        for _, pattern in ipairs(WP_COOKIES) do
            if string.find(cookie_header, pattern, 1, true) then
                var.bypass_cache = "1"
                var.cache_action = "bypass_wp_cookie"
                return true
            end
        end
    end

    -- No bypass needed
    var.bypass_cache = "0"
    var.cache_action = "cache_ok"
    return false
end

-- Serve from cache if available
local function serve_from_cache()
    -- OpenResty proxy_cache provides X-Cache-Status header
    -- If it's HIT/MISS/Stale, we can short-circuit here if needed
    local cache_status = var.upstream_cache_status or ""

    if cache_status == "HIT" then
        log(WARN, "[Cache] HIT: ", var.request_uri)
        var.cache_action = "hit"
        return true
    end

    -- Set bypass_cache to 0 for cached requests
    var.bypass_cache = "0"
    return false
end

--==============================================================================
-- WAF CHECK
--==============================================================================

local function waf_check()
    local config = get_config()
    if config.waf_enabled ~= "true" then
        return true, nil
    end

    -- Load WAF module
    local waf_ok, waf = pcall(require, "waf")
    if not waf_ok then
        log(WARN, "[WAF] Module not found, skipping")
        return true, nil
    end

    local result = waf.check()

    if not result.pass then
        var.waf_check_result = "block"
        var.waf_matched_rule = result.rule or ""
        var.waf_matched_var = result.var or ""
        var.waf_reason = result.reason or ""

        -- Log to WAF log file
        local log_msg = string.format(
            "[%s] %s | %s | %s | %s\n",
            ngx.localtime(),
            var.remote_addr,
            result.rule or "unknown",
            result.reason or "unknown",
            var.request_uri or ""
        )

        local log_file = io.open("/var/server/logs/waf/blocked.log", "a")
        if log_file then
            log_file:write(log_msg)
            log_file:close()
        end

        log(ERR, "[WAF] Blocked: ", var.remote_addr, " - ", result.reason)

        if config.waf_mode == "active" then
            return false, result.reason
        end
    end

    return true, nil
end

--==============================================================================
-- RATE LIMIT
--==============================================================================

local function rate_limit_check()
    local config = get_config()
    if config.rate_limit ~= "true" then
        return true, nil
    end

    local key = "rate_limit:" .. var.remote_addr
    local limit = config.rate_limit_req
    local window = config.rate_limit_window

    if not spanel_shm then
        return true, nil
    end

    local current = spanel_shm:get(key)
    if current and current >= limit then
        log(WARN, "[RateLimit] Limited: ", var.remote_addr)
        return false, "Rate limit exceeded"
    end

    local ok, err = spanel_shm:incr(key, 1)
    if not ok then
        spanel_shm:set(key, 1, window)
    end

    return true, nil
end

--==============================================================================
-- MAIN LOGIC
--==============================================================================

local function main()
    local config = get_config()

    -- Initialize variables
    var.cache_action = "check"
    var.waf_check_result = "pass"
    var.waf_matched_rule = ""
    var.waf_matched_var = ""
    var.waf_reason = ""

    -- Skip for internal requests
    if var.server_addr == var.remote_addr then
        return
    end

    -- STEP 1: Check if should bypass cache
    -- If has querystring OR WP cookies → go directly to WAF (no cache)
    -- If no querystring AND no WP cookies → cache will be checked by nginx
    local bypass_cache = should_bypass_cache()
    if bypass_cache then
        log(WARN, "[Cache] Bypass - ", var.cache_action, ": ", var.request_uri)
        -- Continue to WAF check
    end

    -- STEP 2: WAF Check
    local waf_ok, waf_reason = waf_check()
    if not waf_ok then
        if config.waf_mode == "active" then
            ngx.status = HTTP_FORBIDDEN
            ngx.say("403 Forbidden - Security Policy Violation")
            ngx.exit(HTTP_FORBIDDEN)
            return
        end
    end

    -- STEP 3: Rate Limit Check
    local rl_ok, rl_reason = rate_limit_check()
    if not rl_ok then
        ngx.status = HTTP_TOO_MANY_REQUESTS
        ngx.say("429 Too Many Requests - Rate Limit Exceeded")
        ngx.exit(HTTP_TOO_MANY_REQUESTS)
        return
    end

    -- STEP 4: Continue to backend (proxy_pass)
    log(WARN, "[SPanel] Pass: ", var.remote_addr, " ", var.request_uri, " (cache:", var.cache_action or "default", ")")
end

-- Run
main()