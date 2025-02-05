---@type Portal.QueryGenerator
local function generate(opts, settings)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local jumplist, start = unpack(vim.fn.getjumplist())

    if start == #jumplist then
        table.insert(jumplist, {})
    end

    opts = vim.tbl_extend("force", {
        start = start + 1,
        direction = "backward",
        max_results = #settings.labels,
    }, opts or {})

    if settings.max_results then
        opts.max_results = math.min(opts.max_results, settings.max_results)
    end

    -- stylua: ignore
    local iter = Iterator:new(jumplist)
        :start_at(opts.start)
        :skip(1)
        :take(settings.lookback)

    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, i)
        return {
            type = "jumplist",
            buffer = v.bufnr,
            cursor = { row = v.lnum, col = v.col },
            select = function(content)
                local keycode = vim.api.nvim_replace_termcodes("<c-o>", true, false, true)
                if content.direction == "forward" then
                    keycode = vim.api.nvim_replace_termcodes("<c-i>", true, false, true)
                end
                vim.api.nvim_feedkeys(content.distance .. keycode, "n", false)
            end,
            direction = opts.direction,
            distance = math.abs(opts.start - i),
        }
    end)

    iter = iter:filter(function(v)
        return vim.api.nvim_buf_is_valid(v.buffer)
    end)
    if settings.filter then
        iter = iter:filter(settings.filter)
    end
    if opts.filter then
        iter = iter:filter(opts.filter)
    end
    if not opts.slots then
        iter = iter:take(opts.max_results)
    end

    return {
        source = iter,
        slots = opts.slots,
    }
end

return generate
