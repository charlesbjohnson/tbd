local table_util = require("tbd.util.table")

local M = {
	join = vim.fn.join,
	split = vim.split,
	trim = vim.trim,
}

function M.dedent(lines)
	local result = {}
	local min_indent

	for _, line in ipairs(lines) do
		local indent = (line:find("%S"))
		if indent then
			min_indent = min_indent and math.min(indent, min_indent) or indent
		end
	end

	if min_indent then
		for _, line in ipairs(lines) do
			table.insert(result, line:sub(min_indent))
		end
	end

	return result
end

function M.strip_blanks(lines)
	local result = {}

	for _, line in ipairs(lines) do
		if line:match("%S") then
			table.insert(result, line)
		end
	end

	return result
end

function M.template(str, context)
	return (
			str:gsub("%${([^}]+)}", function(accessor)
				return table_util.dig(context, vim.split(accessor, "%.")) or ""
			end)
		)
end

return M
