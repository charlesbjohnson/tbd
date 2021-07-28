local table_util = require("tbd.util.table")

local M = {
	split = vim.split,
	trim = vim.trim,
}

function M.template(str, context)
	return (
			str:gsub("%${([^}]+)}", function(accessor)
				return table_util.dig(context, vim.split(accessor, "%.")) or ""
			end)
		)
end

return M
