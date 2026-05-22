--==============================================================================
-- SPanel Body Filter
-- Xử lý response body
--==============================================================================

local ngx = ngx
local ngx_phase = ngx.get_phase

-- Chunk buffer để xử lý body theo chunk
local body_chunk = ""

local function filter_body(chunk)
    if not chunk or chunk == "" then
        return chunk
    end

    -- Lưu chunk vào buffer
    body_chunk = body_chunk .. chunk

    -- TODO: Các xử lý body nếu cần
    -- Ví dụ: inline CSS, minify HTML, thay đổi content

    return chunk
end

-- Nếu là last chunk, xử lý toàn bộ body
local function finalize_body()
    if body_chunk == "" then
        return
    end

    -- Reset buffer
    body_chunk = ""
end

return filter_body, finalize_body