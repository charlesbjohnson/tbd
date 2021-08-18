local util = require("tbd.util")
local Tree = require("tbd.data.tree")

local Line = {}
Line.__index = Line

function Line:new(row, node, tree)
	local obj = setmetatable({}, self)

	obj.row = row
	obj.path = node.path

	obj.parsed = node.data.content
	obj.col_start = (#obj.path * 2) - 1

	obj.source = string.rep(" ", obj.col_start - 1) .. obj.parsed
	obj.col_end = #obj.source

	if tree:_is_folded(node) and node.children > 0 then
		obj.meta = string.format(" [%i]", node.children)
	end

	return obj
end

local DocumentTree = {}
DocumentTree.__index = DocumentTree

function DocumentTree:new(tree)
	local obj = setmetatable({}, self)

	obj._tree = tree or Tree:new()
	obj._lines = {}

	obj._rows_to_paths = nil
	obj._paths_to_rows = nil

	self._render(obj)

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
		table.insert(data, { content = (line:sub(depth * 2 - 1)), persist = {} })

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

function DocumentTree:copy()
	local inner = self._tree:into_iter()
	local iter = function()
		local node = inner()
		if node then
			return { data = util.table.copy(node.data), path = node.path }
		end
	end

	return DocumentTree:new(Tree:from_iter(iter))
end

function DocumentTree:get(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return
	end

	return self:_get_line_for(node)
end

function DocumentTree:get_tree(row)
	local path = self:_get_path_at(row)
	if not self._tree:get(path) then
		return
	end

	local inner = self._tree:into_iter(path)
	local iter = function()
		local node = inner()
		if node then
			return { data = util.table.extend({}, node.data, { persist = {} }), path = node.path }
		end
	end

	return DocumentTree:new(Tree:from_iter(iter))
end

function DocumentTree:get_parent(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_parent(path)
	if not node then
		return
	end

	return self:_get_line_for(node)
end

function DocumentTree:get_first_child(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_first_child(path)
	if not node then
		return
	end

	return self:_get_line_for(node)
end

function DocumentTree:get_next_sibling(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_next_sibling(path)
	if not node then
		return
	end

	return self:_get_line_for(node)
end

function DocumentTree:get_prev_sibling(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get_prev_sibling(path)
	if not node then
		return
	end

	return self:_get_line_for(node)
end

function DocumentTree:set(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:set(path, { content = util.string.trim(data), persist = {} })
	if not node then
		return
	end

	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:prepend_to(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:prepend_to(path, { content = util.string.trim(data), persist = {} })
	if not node then
		return
	end

	self:_unfold(self._tree:get_parent(node.path))
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:prepend_tree_to(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:prepend_tree_to(path, tree._tree)
	if not node then
		return
	end

	self:_unfold_downward(self._tree:get_parent(node.path))
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:append_to(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:append_to(path, { content = util.string.trim(data), persist = {} })
	if not node then
		return
	end

	self:_unfold(self._tree:get_parent(node.path))
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:append_tree_to(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:append_tree_to(path, tree._tree)
	if not node then
		return
	end

	self:_unfold_downward(self._tree:get_parent(node.path))
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:insert_before(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_before(path, { content = util.string.trim(data), persist = {} })
	if not node then
		return
	end

	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:insert_tree_before(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_tree_before(path, tree._tree)
	if not node then
		return
	end

	self:_unfold_downward(node)
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:insert_after(row, data)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_after(path, { content = util.string.trim(data), persist = {} })
	if not node then
		return
	end

	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:insert_tree_after(row, tree)
	local path = self:_get_path_at(row)
	local node = self._tree:insert_tree_after(path, tree._tree)
	if not node then
		return
	end

	self:_unfold_downward(node)
	self:_render()

	return self:_get_line_for(node)
end

function DocumentTree:remove(row)
	local path = self:_get_path_at(row)
	self:_unfold_downward(self._tree:get(path))

	local node = self._tree:remove(path)
	if not node then
		return
	end

	local result = self:_get_line_for(node)
	self:_render()

	return result
end

function DocumentTree:remove_tree(row)
	local path = self:_get_path_at(row)
	self:_unfold_downward(self._tree:get(path))

	local tree = self._tree:remove_tree(path)
	if not tree then
		return
	end

	self:_render()

	return DocumentTree:new(tree)
end

function DocumentTree:fold(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return false
	end

	if self:_fold(node) then
		self:_render()
		return true
	end

	return false
end

function DocumentTree:fold_downward(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return false
	end

	if self:_fold_downward(node) then
		self:_render()
	end

	return true
end

function DocumentTree:fold_all()
	local path = { 1 }
	local result = false

	while true do
		local node = self._tree:get(path)
		if not node then
			break
		end

		result = self:_fold_downward(node) or result
		path[1] = path[1] + 1
	end

	if result then
		self:_render()
	end

	return result
end

function DocumentTree:unfold(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return false
	end

	if self:_unfold(node) then
		self:_render()
		return true
	end

	return false
end

function DocumentTree:unfold_downward(row)
	local path = self:_get_path_at(row)
	local node = self._tree:get(path)
	if not node then
		return false
	end

	if self:_unfold_downward(node) then
		self:_render()
	end

	return true
end

function DocumentTree:unfold_upward(path)
	path = util.table.copy(path) or {}

	local result = false

	while #path > 0 do
		result = self:_unfold(self._tree:get(path)) or result
		table.remove(path)
	end

	if result then
		self:_render()
	end

	return result
end

function DocumentTree:unfold_all()
	local path = { 1 }
	local result = false

	while true do
		local node = self._tree:get(path)
		if not node then
			break
		end

		result = self:_unfold_downward(node) or result
		path[1] = path[1] + 1
	end

	if result then
		self:_render()
	end

	return result
end

function DocumentTree:to_lines(render)
	if render then
		self:_render()
	end

	return self._lines
end

function DocumentTree:to_source_lines()
	local result = {}

	for node in self._tree:into_iter() do
		table.insert(result, Line:new(#result + 1, node, self).source)
	end

	return result
end

function DocumentTree:_get_path_at(row)
	if row == 1 and #self._lines == 0 then
		return { 1 }
	end

	return self._rows_to_paths[row]
end

function DocumentTree:_get_row_at(path)
	if #path == 1 and path[1] == 1 and #self._lines == 0 then
		return 1
	end

	return self._paths_to_rows[util.string.join(path, ",")]
end

function DocumentTree:_get_line_for(node)
	return self._lines[self:_get_row_at(node.path)]
end

function DocumentTree:_render()
	self._lines = {}

	self._paths_to_rows = {}
	self._rows_to_paths = {}

	local row = 1

	local stack = {}
	local prev

	for node in self._tree:into_iter() do
		if prev and #node.path > #prev.path then
			table.insert(stack, prev)
		else
			while #stack > 0 and #node.path <= #stack[#stack].path do
				table.remove(stack)
			end
		end

		local is_folded = util.list.any(stack, function(_, v)
			return self:_is_folded(v)
		end)

		if not is_folded then
			table.insert(self._lines, row, Line:new(row, node, self))

			self._paths_to_rows[util.string.join(node.path, ",")] = row
			self._rows_to_paths[row] = node.path

			row = row + 1
		end

		prev = node
	end
end

function DocumentTree:_fold(node)
	if node and not self:_is_folded(node) then
		node.data.persist.is_folded = true
		return true
	end

	return false
end

function DocumentTree:_fold_downward(node)
	if not node then
		return false
	end

	local result = false

	for child_node in self._tree:into_iter(node.path) do
		result = self:_fold(child_node) or result
	end

	return result
end

function DocumentTree:_unfold(node)
	if node and self:_is_folded(node) then
		node.data.persist.is_folded = false
		return true
	end

	return false
end

function DocumentTree:_unfold_downward(node)
	if not node then
		return false
	end

	local result = false

	for child_node in self._tree:into_iter(node.path) do
		result = self:_unfold(child_node) or result
	end

	return result
end

function DocumentTree:_is_folded(node)
	return node.data.persist.is_folded
end

return DocumentTree
