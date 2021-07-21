local table_util = require("tbd.util.table")

local template

template = function(str, context)
	return (
			str:gsub("%${([^}]+)}", function(accessor)
				return table_util.dig(context, vim.split(accessor, "%.")) or ""
			end)
		)
end

return {
	split = vim.split,
	template = template,
	trim = vim.trim,
}
