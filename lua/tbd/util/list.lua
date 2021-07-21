local concat, flatten, slice

concat = function(lst, ...)
	for _, other in ipairs({ ... }) do
		if type(other) == "table" then
			vim.list_extend(lst, other)
		else
			table.insert(lst, other)
		end
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

slice = function(lst, start, finish)
	local sliced = {}

	if not start or start < 1 or start > #lst then
		start = 1
	end

	if not finish or finish > #lst then
		finish = #lst
	elseif finish < 0 then
		finish = #lst + (finish + 1)
	end

	local i = start
	while i <= finish do
		table.insert(sliced, lst[i])
		i = i + 1
	end

	return sliced
end

return {
	concat = concat,
	flatten = flatten,
	slice = slice,
}
