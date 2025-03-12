local visible = true
local function diff_status()
	if not vim.wo.diff then
		return ""
	end

	-- Get current buffer and line
	local buf = vim.api.nvim_get_current_buf()
	local current_line = vim.fn.line(".")

	-- Get all lines in buffer
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local diff_lines = {}

	-- Iterate through lines to find diff changes
	for i, _ in ipairs(lines) do
		-- Check if line is part of a diff chunk
		local line_info = vim.fn.getlinebufinfo(buf, i + 1)[1]
		if line_info and line_info.linehl and line_info.linehl:match("Diff") then
			table.insert(diff_lines, i + 1)
		end
	end

	-- If we found no diff lines, try another approach
	if #diff_lines == 0 then
		for i = 1, #lines do
			local syntax_id = vim.fn.synID(i, 1, true)
			local syntax_name = vim.fn.synIDattr(syntax_id, "name")
			if syntax_name:match("^Diff") then
				table.insert(diff_lines, i)
			end
		end
	end

	-- Group consecutive diff lines into hunks
	local hunks = {}
	local hunk_start = nil

	for i, line_num in ipairs(diff_lines) do
		if not hunk_start or line_num > diff_lines[i - 1] + 1 then
			if hunk_start then
				table.insert(hunks, { start = hunk_start, stop = diff_lines[i - 1] })
			end
			hunk_start = line_num
		end

		-- Handle last hunk
		if i == #diff_lines then
			table.insert(hunks, { start = hunk_start, stop = line_num })
		end
	end

	-- Find which hunk we're in
	local current_hunk = 0
	for i, hunk in ipairs(hunks) do
		if current_line >= hunk.start and current_line <= hunk.stop then
			current_hunk = i
			break
		elseif current_line < hunk.start then
			-- We're before this hunk
			break
		end
	end

	if #hunks > 0 then
		if current_hunk == 0 then
			-- Before first hunk
			return string.format("Diff: <1/%d", #hunks)
		else
			return string.format("Diff: %d/%d", current_hunk, #hunks)
		end
	end

	return ""
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
			require("lualine").setup({
				sections = {
					lualine_c = {
						macro_recording_status,
						diff_status
					},
					lualine_x = { "filetype" },
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
