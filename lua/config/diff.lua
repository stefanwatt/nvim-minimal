local M = {
  diff_items = {}
}

---@param row number
---@param col number
---@return number
---@return number
function M.get_diff_status(row, col)
  local total_diffs = #M.diff_items
  local diff_index = 0
  for index, diff_item in ipairs(M.diff_items) do
    if diff_item.row > row then break end
    if row > diff_item.row then
      diff_index = index
    end
    if row == diff_item.row then
      local foundRanges = vim.tbl_filter(function(range)
        return (col + 1) >= range.start
      end, diff_item.ranges)
      if #foundRanges > 0 then
        diff_index = index
        break
      end
    end
    if index == total_diffs then return total_diffs, total_diffs end
  end
  return diff_index, total_diffs
end

function M.get_diff_items()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local diff_positions = {}

  for row, line in ipairs(lines) do
    local hl_id = vim.fn.diff_hlID(row, 0)
    local hl_group = vim.fn.synIDattr(hl_id, "name")

    if hl_group == "DiffChange" or hl_group == "DiffAdd" or hl_group == "DiffDelete" then
      local text_ranges = {}
      local in_diff_text = false
      local start_col = nil

      local last_col_hl_id = vim.fn.diff_hlID(row, #line)
      local last_col_hl_group = vim.fn.synIDattr(last_col_hl_id, "name")
      if last_col_hl_group ~= "DiffChange" and last_col_hl_group == hl_group then
        table.insert(text_ranges, { start = 0, finish = #line })
      else
        local last_hl_group = "foo"
        for col = 0, #line do
          local col_hl_id = vim.fn.diff_hlID(row, col)
          local col_hl_group = vim.fn.synIDattr(col_hl_id, "name")
          if (col_hl_group == "DiffText" or col_hl_group == "DiffAdd") and not in_diff_text then
            last_hl_group = col_hl_group
            in_diff_text = true
            start_col = col
          elseif (col_hl_group ~= last_hl_group) and in_diff_text then
            in_diff_text = false
            table.insert(text_ranges, { start = start_col, finish = col - 1 })
            last_hl_group = col_hl_group
          end
        end
        if in_diff_text then
          table.insert(text_ranges, { start = start_col, finish = #line })
        end
      end
      if #text_ranges > 0 then
        table.insert(diff_positions, {
          row = row,
          ranges = text_ranges
        })
      end
    end
  end

  return diff_positions
end

vim.api.nvim_create_autocmd({ "VimEnter", "DiffUpdated" }, {
  callback = function()
    M.diff_items = M.get_diff_items()
  end,
  group = vim.api.nvim_create_augroup("DiffTextStore", { clear = true }),
  desc = "Store all lines"
})

return M
