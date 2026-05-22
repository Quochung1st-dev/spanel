--==============================================================================
-- SPanel Init Worker
-- Khởi tạo khi worker process bắt đầu
--==============================================================================

local ngx = ngx
local ngx_log = ngx.log
local ngx_shared = ngx.shared
local floor = math.floor

-- Shared dicts
local spanel_shm = ngx_shared.spanel_shm
local waf_shm = ngx_shared.waf_shm
local cache_shm = ngx_shared.cache_shm

-- Cấu hình từ env
local env = os.getenv

-- Timer cho các tác vụ background
local function start_timer(premature)
    if premature then
        return
    end

    -- Timer dọn dẹp cache expired
    local cache_cleanup = ngx.timer.every
    local ok, err = cache_cleanup(300, function()
        local keys = cache_shm:get_keys(1000)
        local now = ngx.now()
        for _, key in ipairs(keys) do
            local val = cache_shm:get(key)
            if val then
                local data = cjson.decode(val)
                if data.expire and data.expire < now then
                    cache_shm:delete(key)
                end
            end
        end
    end)

    if not ok then
        ngx_log(ngx.ERR, "[SPanel] Failed to start cache cleanup timer: ", err)
    end

    -- Timer cleanup WAF blocked IPs
    local ok2, err2 = ngx.timer.every(60, function()
        local keys = waf_shm:get_keys(1000)
        local now = ngx.now()
        for _, key in ipairs(keys) do
            local expire = waf_shm:get(key)
            if expire and expire < now then
                waf_shm:delete(key)
            end
        end
    end)

    if not ok2 then
        ngx_log(ngx.ERR, "[SPanel] Failed to start WAF cleanup timer: ", err2)
    end
end

-- Đăng ký init handler
local ok, err = ngx.timer.at(0, start_timer)
if not ok then
    ngx_log(ngx.ERR, "[SPanel] Failed to create init timer: ", err)
end

ngx_log(ngx.INFO, "[SPanel] Init worker started")