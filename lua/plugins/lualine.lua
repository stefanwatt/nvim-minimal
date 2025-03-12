local visible = true

local function diff_status()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  local diff_index, total_diffs = require("config.diff").get_diff_status(row, col)
  return "Diff (" .. tostring(diff_index) .. "/" .. total_diffs .. ")"
end

local function macro_recording_status()
  local recording_register = vim.fn.reg_recording()
  if recording_register ~= "" then
    return "Recording @" .. recording_register
  end
  return ""
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader><leader>s",
        mode = { "n" },
        function()
          if not visible then
            vim.o.laststatus = 3
            visible = true
          else
            vim.o.laststatus = 0
            visible = false
          end
        end,
        desc = "Toggle Lualine",
      },
    },
    config = function()
      local custom_fname = require('lualine.components.filename'):extend()
      function custom_fname:init(options)
        custom_fname.super.init(self, options)
      end

      function custom_fname:update_status()
        local data = vim.fn.expand('%:t')
        if data == "" then
          data = "[No Name]"
        end

        if not vim.bo.modified then return data end
        return "%#DiagnosticSignWarn#" .. data .. ' ●'
      end

      require("lualine").setup({
        sections = {
          lualine_c = {
            { custom_fname },
            { macro_recording_status },
            { diff_status },
          },
          lualine_x = {
            "filetype",
          },
          lualine_y = {
            {
              "fileformat",
              icons_enabled = true,
              symbols = {
                unix = "LF",
                dos = "CRLF",
                mac = "CR",
              },
            },
          },
        },
      })
      vim.o.cmdheight = 0
      vim.o.laststatus = 3
    end,
  },
}
