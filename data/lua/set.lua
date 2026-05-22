--==============================================================================
-- SPanel Set Phase
-- Xử lý các biến set_by_lua
--==============================================================================

local ngx = ngx
local var = ngx.var

-- Kiểm tra SSL
local function is_ssl()
    local scheme = var.scheme
    if scheme == "https" then
        return "1"
    end
    -- Check port
    local port = var-server_port
    if port == "443" then
        return "1"
    end
    return "0"
end

-- Lấy domain từ host header
local function get_domain()
    local host = var.host
    -- Loại bỏ port nếu có
    return host:gsub(":%d+$", "")
end

-- Kiểm tra request có phải static không
local function is_static()
    local uri = var.request_uri
    local ext = uri:match("%.(%w+)$")
    if ext then
        local static_exts = {
            html = true, htm = true, css = true, js = true,
            jpg = true, jpeg = true, png = true, gif = true,
            webp = true, svg = true, ico = true,woff = true,
            woff2 = true, ttf = true, eot = true
        }
        if static_exts[ext:lower()] then
            return "1"
        end
    end
    return "0"
end

-- Trả về các biến
ngx.var.ssl_enabled = is_ssl()
ngx.var.domain_name = get_domain()
ngx.var.is_static = is_static()