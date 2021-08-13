local M = {}

function M.any(lst, fn)
	for i, v in ipairs(lst) do
		if fn(i, v) then
			return true
		end
	end

	return false
end

function M.concat(lst, ...)
	for _, other in ipairs({ ... }) do
		if type(other) == "table" then
			vim.list_extend(lst, other)
		else
			table.insert(lst, other)
		end
	end

	return lst
end

function M.flatten(lst, depth)
	if not depth then
		return vim.tbl_flatten(lst)
	end

	local flattened = {}

	for i = 0, #lst do
		local v = lst[i]

		if type(v) == "table" and depth > 0 then
			M.concat(flattened, M.flatten(v, depth - 1))
		else
			table.insert(flattened, v)
		end
	end

	return flattened
end

function M.slice(lst, start, finish)
	local sliced = {}

	if not start or start < 1 or start > #lst then
		start = 1
	end

	if not finish or finish > #lst then
		finish = #lst
	elseif finish < 0 then
		finish = #lst + (finish + 1)
	end

	for i = start, finish do
		table.insert(sliced, lst[i])
	end

	return sliced
end

return M
