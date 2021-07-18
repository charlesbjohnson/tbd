local concat, flatten

concat = function(lst, other)
	if type(other) == "table" then
		vim.list_extend(lst, other)
	else
		table.insert(lst, other)
	end

	return lst
end

flatten = function(lst, depth)
	if not depth then
		return vim.tbl_flatten(lst)
	end

	local flattened = {}

	local i = 1
	while i <= #lst do
		local v = lst[i]

		if type(v) == "table" and depth > 0 then
			concat(flattened, flatten(v, depth - 1))
		else
			table.insert(flattened, v)
		end

		i = i + 1
	end

	return flattened
end

return {
	concat = concat,
	flatten = flatten,
}
