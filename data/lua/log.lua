--==============================================================================
-- SPanel Log Phase
-- Ghi log request
--==============================================================================

local ngx = ngx
local var = ngx.var
local log = ngx.log
local INFO = ngx.INFO

-- Format log entry
local function format_log_entry()
    return string.format(
        '[SPanel] %s - %s [%s] "%s %s%s %s" %d %d "%s" "%s"',
        var.remote_addr,
        var.remote_user or "-",
        ngx.localtime(),
        var.request_method,
        var.request_uri,
        var.args and var.args ~= "" and "?" .. var.args or "",
        var.server_protocol,
        tonumber(var.status) or 0,
        tonumber(var.body_bytes_sent) or 0,
        var.http_referer or "-",
        var.http_user_agent or "-"
    )
end

-- Ghi log WAF nếu có
local function log_waf_event()
    if var.waf_check_result ~= "pass" then
        local log_file = assert(io.open("/var/server/logs/waf/blocked.log", "a"))
        if log_file then
            local entry = string.format(
                "[%s] %s - Rule: %s | Var: %s | URI: %s\n",
                ngx.localtime(),
                var.remote_addr,
                var.waf_matched_rule or "unknown",
                var.waf_matched_var or "unknown",
                var.request_uri
            )
            log_file:write(entry)
            log_file:close()
        end
    end
end

-- MAIN log logic
log(INFO, format_log_entry())
log_waf_event()