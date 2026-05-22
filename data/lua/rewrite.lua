--==============================================================================
-- SPanel Rewrite Phase
-- Xử lý URL rewrite và redirect
--==============================================================================

local ngx = ngx
local var = ngx.var
local log = ngx.log
local WARN = ngx.WARN

-- Lấy domain config
local function get_domain_config(domain)
    -- TODO: Load domain config từ database hoặc file
    return {
        force_https = false,
        www_redirect = nil,  -- "to_www" hoặc "from_www"
        custom_rewrites = {}
    }
end

-- Xử lý www redirect
local function handle_www_redirect(domain)
    local config = get_domain_config(domain)
    local host = var.host
    local request_uri = var.request_uri

    if config.www_redirect == "to_www" then
        if not host:match("^www%.") then
            return ngx.redirect("https://www." .. host .. request_uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
    elseif config.www_redirect == "from_www" then
        if host:match("^www%.") then
            local non_www = host:gsub("^www%.", "")
            return ngx.redirect("https://" .. non_www .. request_uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
    end
end

-- Xử lý HTTPS redirect
local function handle_https_redirect(domain)
    local config = get_domain_config(domain)

    if config.force_https and var.ssl_enabled == "0" then
        local scheme = var.scheme
        if scheme == "http" then
            return ngx.redirect("https://" .. var.host .. var.request_uri, ngx.HTTP_MOVED_TEMPORARILY)
        end
    end
end

-- MAIN rewrite logic
local domain = var.domain_name

-- Skip cho các static file
if var.is_static == "1" then
    return
end

-- Xử lý redirects
handle_https_redirect(domain)
handle_www_redirect(domain)

log(WARN, "[SPanel] Rewrite completed for: ", domain)