local M = {}

function M.copy(tbl)
	local cpy = {}

	for k, v in pairs(tbl) do
		cpy[k] = v
	end

	return cpy
end

function M.dig(tbl, path)
	if type(tbl) ~= "table" or type(path) ~= "table" then
		return
	end

	for _, segment in ipairs(path) do
		if tbl[segment] == nil then
			return
		end

		tbl = tbl[segment]
	end

	return tbl
end

function M.extend(tbl, ...)
	return vim.tbl_extend("force", tbl, ...)
end

return M
