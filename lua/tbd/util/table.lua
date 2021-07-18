local copy, dig, extend

copy = function(tbl)
	local cpy = {}

	for k, v in pairs(tbl) do
		cpy[k] = v
	end

	return cpy
end

dig = function(tbl, path)
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

extend = function(tbl, ...)
	return vim.tbl_extend("force", tbl, ...)
end

return {
	copy = copy,
	dig = dig,
	extend = extend,
}
