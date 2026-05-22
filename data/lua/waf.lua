--==============================================================================
-- SPanel WAF Module
-- Core WAF checking functions
--==============================================================================

local waf = {}

-- Cấu hình
local config = {
    rules_dir = "/opt/spanel/var/server/waf/rules"
}

-- Shared dict
local ngx_shared = ngx.shared
local waf_shm = ngx_shared and ngx_shared.waf_shm

-- Request data helpers
local function get_var(name)
    return ngx.var[name] or ""
end

local function get_args()
    return ngx.var.args or ""
end

local function get_post()
    -- Đọc body để kiểm tra POST data
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    return data or ""
end

local function get_headers()
    local headers = {}
    local keys = ngx.req.get_headers()
    for k, v in pairs(keys) do
        headers[k] = v
    end
    return headers
end

-- Kiểm tra IP có bị block không
local function is_ip_blocked(ip)
    if not waf_shm then
        return false
    end

    local blocked = waf_shm:get("blocked:" .. ip)
    if blocked then
        local now = ngx.now() * 1000  -- Convert to milliseconds
        if blocked > now then
            return true
        else
            waf_shm:delete("blocked:" .. ip)
        end
    end

    return false
end

-- Block một IP
local function block_ip(ip, duration)
    if not waf_shm then
        return
    end

    duration = duration or 3600000  -- Default 1 hour in ms
    local expire = ngx.now() * 1000 + duration
    waf_shm:set("blocked:" .. ip, expire)
end

-- Load rules từ file
local function load_rules(file)
    local rules = {}
    local f = io.open(file, "r")
    if not f then
        return rules
    end

    for line in f:lines() do
        -- Skip comments and empty lines
        if line ~= "" and not line:match("^%s*#") then
            table.insert(rules, line)
        end
    end

    f:close()
    return rules
end

-- Match against pattern (simple patterns)
local function pattern_match(str, pattern)
    if not str or not pattern then
        return false
    end

    -- SQL injection patterns
    if pattern:match("^sql:") then
        local pat = pattern:sub(5)
        -- Various SQL injection patterns
        local sql_patterns = {
            "union%s+select",
            "union%s+all%s+select",
            "select%s+from",
            "insert%s+into",
            "delete%s+from",
            "drop%s+table",
            "update%s+.*%s+set",
            "exec%s*%(",
            "execute%s*%(",
            "benchmark%s*%(",
            "sleep%s*%(",
            "'%s*or%s*'1'%s*=%s*'1",
            "'%s*or%s*1%s*=%s*1",
            "'%s*or%s*1%s*=%s*1",
            "or%s+1%s*=%s*1",
            "'%s*--",
            ";%s*drop%s+",
            ";%s*delete%s+",
            "'%s*;%s*"
        }

        for _, p in ipairs(sql_patterns) do
            if str:lower():match(p) then
                return true, "SQL Injection Pattern"
            end
        end
    end

    -- XSS patterns
    if pattern:match("^xss:") then
        local xss_patterns = {
            "<script",
            "</script",
            "javascript:",
            "onerror%s*=",
            "onload%s*=",
            "onclick%s*=",
            "onmouseover%s*=",
            "eval%s*%(",
            "document%.cookie",
            "alert%s*%(",
            "String%.fromCharCode"
        }

        for _, p in ipairs(xss_patterns) do
            if str:lower():match(p) then
                return true, "XSS Pattern"
            end
        end
    end

    -- LFI patterns
    if pattern:match("^lfi:") then
        local lfi_patterns = {
            "../",
            "/etc/passwd",
            "/etc/shadow",
            "/proc/self",
            "/proc/environ",
            "..%2f",
            "%252e%252e"
        }

        for _, p in ipairs(lfi_patterns) do
            if str:lower():find(p, 1, true) then
                return true, "LFI Pattern"
            end
        end
    end

    return false
end

-- MAIN WAF check function
function waf.check()
    local result = {
        pass = true,
        reason = nil,
        rule = nil,
        var = nil
    }

    -- Check nếu IP đã bị block
    local ip = get_var("remote_addr")
    if is_ip_blocked(ip) then
        result.pass = false
        result.reason = "IP is blocked"
        result.rule = "ip_block"
        result.var = ip
        return result
    end

    -- Check URI
    local uri = get_var("request_uri")
    local args = get_args()
    local post = get_post()
    local headers = get_headers()

    -- Combine all data to check
    local data_to_check = uri .. " " .. args .. " " .. post

    -- Check SQL injection
    local sql_passed, sql_reason = pattern_match(data_to_check, "sql:anything")
    if sql_passed then
        result.pass = false
        result.reason = sql_reason
        result.rule = "sql_injection"
        result.var = "request_uri/args/body"
        block_ip(ip, 3600000)  -- Block 1 hour
        return result
    end

    -- Check XSS
    local xss_passed, xss_reason = pattern_match(data_to_check, "xss:anything")
    if xss_passed then
        result.pass = false
        result.reason = xss_reason
        result.rule = "xss"
        result.var = "request_uri/args/body"
        block_ip(ip, 3600000)
        return result
    end

    -- Check LFI
    local lfi_passed, lfi_reason = pattern_match(data_to_check, "lfi:anything")
    if lfi_passed then
        result.pass = false
        result.reason = lfi_reason
        result.rule = "lfi"
        result.var = "request_uri/args"
        block_ip(ip, 3600000)
        return result
    end

    -- Check User-Agent
    local ua = get_var("http_user_agent") or ""
    if ua:match("curl") and uri:match("^/nginx_status") then
        -- Allow nginx_status for monitoring
    end

    return result
end

-- Export functions
waf.is_ip_blocked = is_ip_blocked
waf.block_ip = block_ip
waf.pattern_match = pattern_match

return waf