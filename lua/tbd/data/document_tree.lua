local util = require("tbd.util")
local Tree = require("tbd.data.tree")

local DocumentTree = {}
DocumentTree.__index = DocumentTree

function DocumentTree:new()
	local obj = setmetatable({}, self)

	obj._tree = Tree:new()
	obj._lines = {}

	return obj
end

function DocumentTree:get(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:get_parent(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_parent(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:get_first_child(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_first_child(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:get_next_sibling(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_next_sibling(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:get_prev_sibling(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_prev_sibling(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:set(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:set(path, util.string.trim(data))
	if not node then
		return
	end

	self:_render()

	return self:_to_line(node)
end

function DocumentTree:prepend_to(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:prepend_to(path, util.string.trim(data))
	if not node then
		return
	end

	self:_render()

	return self:_to_line(node)
end

function DocumentTree:append_to(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:append_to(path, util.string.trim(data))
	if not node then
		return
	end

	self:_render()

	return self:_to_line(node)
end

function DocumentTree:insert_before(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_before(path, util.string.trim(data))
	if not node then
		return
	end

	self:_render()

	return self:_to_line(node)
end

function DocumentTree:insert_after(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_after(path, util.string.trim(data))
	if not node then
		return
	end

	self:_render()

	return self:_to_line(node)
end

function DocumentTree:remove(row)
	local path = self:_get_path_at(row)
	local node = self._tree:remove(path)
	if not node then
		return
	end

	local result = self:_to_line(node)
	self:_render()

	return result
end

function DocumentTree:render()
	return util.table.copy(self._lines)
end

function DocumentTree:_get_path_at(row)
	row = row or 1

	if row == 1 then
		return { 1 }
	end

	if row < 1 or row > #self._lines then
		return
	end

	local path = {}

	local cursor = { row, (self._lines[row]:find("%S")) }
	local distance = 0

	while true do
		if cursor[1] == 0 then
			table.insert(path, 1, distance)
			break
		end

		local line = self._lines[cursor[1]]

		if cursor[2] > #line or (cursor[2] > 2 and line:sub(cursor[2] - 2, cursor[2] - 1) ~= "  ") then
			table.insert(path, 1, distance)
			distance = 1
			cursor[2] = cursor[2] - 2
		elseif line:sub(cursor[2], cursor[2]) ~= " " then
			distance = distance + 1
		end

		cursor[1] = cursor[1] - 1
	end

	return path
end

function DocumentTree:_get_row_at(path)
	path = path or {}

	if #path == 0 then
		return
	end

	local cursor = { 1, 1 }

	for depth, distance in ipairs(path) do
		while distance > 0 do
			local line = self._lines[cursor[1]]

			if line:sub(cursor[2], cursor[2] + 1) ~= "  " then
				distance = distance - 1
			end

			if distance > 0 then
				cursor[1] = cursor[1] + 1
			end
		end

		if depth < #path then
			cursor[1] = cursor[1] + 1
			cursor[2] = cursor[2] + 2
		end
	end

	return cursor[1]
end

function DocumentTree:_render()
	self._lines = {}

	for node in self._tree:into_iter() do
		table.insert(self._lines, string.rep("  ", #node.path - 1) .. node.data)
	end

	return self._lines
end

function DocumentTree:_to_line(node)
	local row = self:_get_row_at(node.path)

	local line = self._lines[row]
	local col = (line:find(node.data))

	return {
		source = line,
		parsed = node.data,
		row = row,
		col = col,
	}
end

return DocumentTree
