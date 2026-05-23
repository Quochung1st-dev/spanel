--==============================================================================
-- SPanel WAF Module
-- Core WAF checking functions
--==============================================================================

local waf = {}

-- Config
local config = {
    rules_dir = "/var/server/waf/rules",
    whitelist_file = "/var/server/waf/whitelist.ip",
    blocklist_file = "/var/server/waf/blocklist.ip"
}

-- Shared dict
local ngx_shared = ngx.shared
local waf_shm = ngx_shared and ngx_shared.waf_shm

-- Cached lists
local whitelist_ips = {}
local blocklist_ips = {}
local list_loaded = false

-- Request data helpers
local function get_var(name)
    return ngx.var[name] or ""
end

local function get_args()
    return ngx.var.args or ""
end

local function get_post()
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    return data or ""
end

-- Load IPs from file
local function load_ip_list(file)
    local ips = {}
    local f = io.open(file, "r")
    if not f then
        return ips
    end

    for line in f:lines() do
        -- Skip comments and empty lines
        line = line:gsub("%s+#.*", "") -- Remove comments
        line = line:gsub("^%s+", "") -- Trim leading
        line = line:gsub("%s+$", "") -- Trim trailing

        if line ~= "" and line ~= "#" then
            -- Convert CIDR to simple check (simplified)
            local ip = line:gsub("/%d+$", "") -- Remove /24 etc for now
            table.insert(ips, ip)
        end
    end

    f:close()
    return ips
end

-- Reload lists periodically
local function ensure_lists_loaded()
    if not list_loaded then
        whitelist_ips = load_ip_list(config.whitelist_file)
        blocklist_ips = load_ip_list(config.blocklist_file)
        list_loaded = true

        -- Reload every 60 seconds
        local ok, err = ngx.timer.at(60, function()
            list_loaded = false
        end)
    end
end

-- Check if IP is in whitelist
local function is_ip_whitelisted(ip)
    ensure_lists_loaded()

    for _, whitelist_ip in ipairs(whitelist_ips) do
        if ip == whitelist_ip then
            return true
        end
    end

    -- Also check shared dict
    if waf_shm then
        local whitelist = waf_shm:get("whitelist:" .. ip)
        if whitelist == true then
            return true
        end
    end

    return false
end

-- Check if IP is in blocklist
local function is_ip_blocklisted(ip)
    ensure_lists_loaded()

    for _, blocklist_ip in ipairs(blocklist_ips) do
        if ip == blocklist_ip then
            return true
        end
    done

    return false
end

-- Kiểm tra IP có bị block không
local function is_ip_blocked(ip)
    if not waf_shm then
        return false
    end

    local blocked = waf_shm:get("blocked:" .. ip)
    if blocked then
        local now = ngx.now() * 1000
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

    duration = duration or 3600000
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
        if line ~= "" and not line:match("^%s*#") then
            table.insert(rules, line)
        end
    end

    f:close()
    return rules
end

-- Match against pattern
local function pattern_match(str, pattern)
    if not str or not pattern then
        return false
    end

    -- SQL injection patterns
    if pattern:match("^sql:") then
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

    local ip = get_var("remote_addr")

    -- Check whitelist first
    if is_ip_whitelisted(ip) then
        return result -- Allow
    end

    -- Check blocklist
    if is_ip_blocklisted(ip) then
        result.pass = false
        result.reason = "IP is blocklisted"
        result.rule = "ip_blocklist"
        result.var = ip
        return result
    end

    -- Check if IP is blocked (temporary block)
    if is_ip_blocked(ip) then
        result.pass = false
        result.reason = "IP is blocked"
        result.rule = "ip_block"
        result.var = ip
        return result
    end

    -- Check URI, args, body
    local uri = get_var("request_uri")
    local args = get_args()
    local post = get_post()
    local data_to_check = uri .. " " .. args .. " " .. post

    -- Check SQL injection
    local sql_passed, sql_reason = pattern_match(data_to_check, "sql:anything")
    if sql_passed then
        result.pass = false
        result.reason = sql_reason
        result.rule = "sql_injection"
        result.var = "request_uri/args/body"
        block_ip(ip, 3600000)
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

    return result
end

-- Export functions
waf.is_ip_whitelisted = is_ip_whitelisted
waf.is_ip_blocklisted = is_ip_blocklisted
waf.is_ip_blocked = is_ip_blocked
waf.block_ip = block_ip
waf.pattern_match = pattern_match
waf.load_ip_list = load_ip_list
waf.reload_lists = function() list_loaded = false end

return waf