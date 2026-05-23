#==============================================================================
# VHost Templates Index
# SPanel - Nginx Configuration Templates
#
# Usage: Copy templates to /var/server/nginx/conf/sites-available/{domain}.conf
#        then symlink to sites-enabled/
#
# Variable placeholders:
#   {{DOMAIN}}        - Domain name
#   {{UPSTREAM}}      - Upstream URL (for proxy)
#   {{UPSTREAM_HOST}} - Host header for upstream
#   {{NODE_PORT}}     - Node.js application port
#==============================================================================

# Available Templates
#==============================================================================

# 1. static.conf
#    - Static HTML/CSS/JS websites
#    - No backend processing
#    - Aggressive caching for static assets
#    Usage: v-add-domain example.com --template static

# 2. php.conf
#    - PHP websites with FastCGI
#    - WordPress, Laravel, CodeIgniter, etc.
#    Usage: v-add-domain example.com --template php

# 3. ssl.conf
#    - HTTPS with SSL certificate
#    - PHP support included
#    - Security headers
#    Usage: v-add-domain example.com --template ssl

# 4. proxy.conf
#    - Reverse proxy with caching
#    - For mirroring/caching external websites
#    - Variables: UPSTREAM_URL, UPSTREAM_HOST
#    Usage: v-add-domain example.com --template proxy --upstream https://example.com

# 5. node.conf
#    - Node.js/React/Vue applications
#    - WebSocket support
#    - API proxy to backend
#    Usage: v-add-domain example.com --template node --node-port 3000

# 6. wordpress.conf
#    - WordPress optimized configuration
#    - Permalinks support
#    - Login protection
#    Usage: v-add-domain example.com --template wordpress

# 7. lua.conf (include snippet)
#    - Lua access phase processing
#    - WAF integration
#    - Rate limiting
#    - Custom headers
#    Usage: Include in other templates or use standalone


# Template Selection Logic
#==============================================================================

# In v-add-domain script:
#
# --template static     -> static.conf
# --template php        -> php.conf
# --template ssl        -> ssl.conf
# --template proxy      -> proxy.conf
# --template node       -> node.conf
# --template wordpress  -> wordpress.conf
#
# Without --template flag:
# Default is "php" for backwards compatibility


# SSL Templates
#==============================================================================

# SSL templates require SSL certificate:
# - Let's Encrypt: /var/server/ssl/{domain}/fullchain.pem
# - Custom: Place certificates in /var/server/ssl/{domain}/


# Lua Integration
#==============================================================================

# All templates inherit global Lua configuration from:
# /var/server/nginx/conf/conf.d/lua.conf

# The lua.conf template provides:
# - access_by_lua_file for WAF and rate limiting
# - header_filter_by_lua_file for response headers
# - body_filter_by_lua_file for response body
# - log_by_lua_file for custom logging


# Cache Zones (defined in conf.d/cache.conf)
#==============================================================================

# spanel_cache   - Main proxy cache (10MB)
# static_cache   - Static file cache (50MB)
# cache_shm      - General purpose cache (10MB)


# Security Features (Global)
#==============================================================================

# WAF checks are applied globally via conf.d/lua.conf
# - SQL injection detection
# - XSS detection
# - LFI detection
# - IP whitelist/blocklist

# Rate limiting via lua_shared_dict (conf.d/lua.conf):
# - Per-IP request limiting
# - Configurable via .env


# Example Usage
#==============================================================================

# 1. Create static website:
#    v-add-domain static-site.com --template static

# 2. Create PHP website with SSL:
#    v-add-domain mysite.com --template ssl --ssl letsencrypt

# 3. Create proxy domain:
#    v-add-domain cached-site.com --template proxy --upstream https://original-site.com

# 4. Create WordPress site:
#    v-add-domain myblog.com --template wordpress --ssl selfsigned

# 5. Create Node.js app:
#    v-add-domain myapp.com --template node --node-port 8080 --ssl letsencrypt