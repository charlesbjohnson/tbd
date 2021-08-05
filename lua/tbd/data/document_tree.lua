local util = require("tbd.util")
local Tree = require("tbd.data.tree")

local DocumentTree = {}
DocumentTree.__index = DocumentTree

function DocumentTree:new(tree)
	local obj = setmetatable({}, self)

	obj._tree = tree or Tree:new()
	obj._lines = self._render(obj)

	return obj
end

function DocumentTree:from_lines(lines)
	lines = util.string.strip_blanks(lines)
	lines = util.string.dedent(lines)

	local paths = {}
	local data = {}

	local prev_path = {}

	for _, line in ipairs(lines) do
		local depth = math.ceil((line:find("%S")) / 2)
		local path = util.table.copy(prev_path)

		if depth - #path > 1 then
			return
		end

		if depth > #path then
			table.insert(path, 0)
		else
			while depth < #path do
				table.remove(path)
			end
		end

		path[#path] = path[#path] + 1

		table.insert(paths, path)
		table.insert(data, (line:sub(depth * 2 - 1)))

		prev_path = path
	end

	local iter = function()
		local i = 0

		return function()
			i = i + 1

			if i <= #paths then
				return { data = data[i], path = paths[i] }
			end
		end
	end

	return self:new(Tree:from_iter(iter()))
end

function DocumentTree:get(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return
	end

	return self:_to_line(node)
end

function DocumentTree:get_tree(row)
	local path = self:_get_path_at(row)
	local tree = self._tree:get_tree(path)
	if not tree then
		return
	end

	return DocumentTree:new(tree)
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

function DocumentTree:prepend_tree_to(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:prepend_tree_to(path, tree._tree)
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

function DocumentTree:append_tree_to(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:append_tree_to(path, tree._tree)
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

function DocumentTree:insert_tree_before(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_tree_before(path, tree._tree)
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

function DocumentTree:insert_tree_after(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_tree_after(path, tree._tree)
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

function DocumentTree:remove_tree(row)
	local path = self:_get_path_at(row)
	local tree = self._tree:remove_tree(path)
	if not tree then
		return
	end

	self:_render()

	return DocumentTree:new(tree)
end

function DocumentTree:to_lines()
	return self._lines
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
