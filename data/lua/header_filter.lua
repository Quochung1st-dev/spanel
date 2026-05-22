--==============================================================================
-- SPanel Header Filter
-- Xử lý response headers
--==============================================================================

local ngx = ngx
local var = ngx.var
local ngx_header = ngx.header

-- Thêm các security headers
local function add_security_headers()
    -- X-Content-Type-Options
    ngx_header["X-Content-Type-Options"] = "nosniff"
    -- X-Frame-Options
    ngx_header["X-Frame-Options"] = "SAMEORIGIN"
    -- X-XSS-Protection
    ngx_header["X-XSS-Protection"] = "1; mode=block"
    -- Referrer Policy
    ngx_header["Referrer-Policy"] = "strict-origin-when-cross-origin"
    -- Permissions Policy
    ngx_header["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
end

-- Thêm cache headers cho static content
local function add_cache_headers()
    if var.is_static == "1" then
        ngx_header["Cache-Control"] = "public, max-age=31536000"
        ngx_header["Expires"] = ngx.cookie_time(ngx.time() + 31536000)
    else
        ngx_header["Cache-Control"] = "no-cache, no-store, must-revalidate"
        ngx_header["Pragma"] = "no-cache"
        ngx_header["Expires"] = "0"
    end
end

-- Xóa các header không cần thiết
local function remove_sensitive_headers()
    ngx_header["Server"] = nil
    ngx_header["X-Powered-By"] = nil
end

-- MAIN header filter
add_security_headers()
add_cache_headers()
remove_sensitive_headers()