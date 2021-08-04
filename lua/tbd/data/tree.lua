local util = require("tbd.util")

local Tree = {}
Tree.__index = Tree

function Tree:new()
	local obj = setmetatable({}, self)

	obj._root = self:_to_node()

	return obj
end

function Tree:from_iter(iter)
	local obj = self:new()

	for node in iter do
		if not obj:_insert_at(node.path, node.data) then
			return
		end
	end

	return obj
end

function Tree:into_iter()
	local traversal = self:_traverse()
	local i = 0

	return function()
		i = i + 1

		if i <= #traversal then
			return traversal[i]
		end
	end
end

function Tree:get(path)
	local node = self:_get(path)
	if not node then
		return
	end

	return { data = node.data, path = util.table.copy(path) }
end

function Tree:get_parent(path)
	local child_node = self:_get(path)
	if not child_node or child_node.parent == self._root then
		return
	end

	local parent_node = child_node.parent
	local parent_path = util.list.slice(path, 1, -2)

	return { data = parent_node.data, path = parent_path }
end

function Tree:get_first_child(path)
	local parent_node = self:_get(path)
	if not parent_node or #parent_node.children == 0 then
		return
	end

	local child_node = parent_node.children[1]
	local child_path = util.list.concat({}, path, 1)

	return { data = child_node.data, path = child_path }
end

function Tree:get_last_child(path)
	local parent_node = self:_get(path)
	if not parent_node or #parent_node.children == 0 then
		return
	end

	local child_node = parent_node.children[#parent_node.children]
	local child_path = util.list.concat({}, path, #parent_node.children)

	return { data = child_node.data, path = child_path }
end

function Tree:get_next_sibling(path)
	local sibling_or_root_node = self:_get(path, true)
	if not sibling_or_root_node then
		return
	end

	local parent_node = sibling_or_root_node.parent or self._root
	if path[#path] >= #parent_node.children then
		return
	end

	local sibling_path = util.table.copy(path)
	sibling_path[#sibling_path] = sibling_path[#sibling_path] + 1

	local sibling_node = parent_node.children[sibling_path[#sibling_path]]

	return { data = sibling_node.data, path = sibling_path }
end

function Tree:get_prev_sibling(path)
	local sibling_or_root_node = self:_get(path, true)
	if not sibling_or_root_node then
		return
	end

	local parent_node = sibling_or_root_node.parent or self._root
	if path[#path] <= 1 then
		return
	end

	local sibling_path = util.table.copy(path)
	sibling_path[#sibling_path] = sibling_path[#sibling_path] - 1

	local sibling_node = parent_node.children[sibling_path[#sibling_path]]

	return { data = sibling_node.data, path = sibling_path }
end

function Tree:set(path, data)
	local node = self:_get(path, self:is_empty())
	if not node then
		return
	end

	if node == self._root then
		node = self:_to_node(data, self._root)
		table.insert(self._root.children, node)
	else
		node.data = data
	end

	return self:get(path)
end

function Tree:prepend_to(path, data)
	if self:is_empty() then
		return self:set(path, data)
	end

	local parent_node = self:_get(path)
	if not parent_node then
		return
	end

	local child_node = self:_to_node(data, parent_node)
	table.insert(parent_node.children, 1, child_node)

	if parent_node == self._root then
		return self:get(path)
	end

	return self:get_first_child(path)
end

function Tree:append_to(path, data)
	if self:is_empty() then
		return self:set(path, data)
	end

	local parent_node = self:_get(path)
	if not parent_node then
		return
	end

	local child_node = self:_to_node(data, parent_node)
	table.insert(parent_node.children, child_node)

	if parent_node == self._root then
		return self:get(path)
	end

	return self:get_last_child(path)
end

function Tree:insert_before(path, data)
	if self:is_empty() then
		return self:set(path, data)
	end

	local sibling_node = self:_get(path)
	if not sibling_node then
		return
	end

	local parent_node = sibling_node.parent
	local child_node = self:_to_node(data, parent_node)

	table.insert(parent_node.children, path[#path], child_node)

	return self:get(path)
end

function Tree:insert_after(path, data)
	if self:is_empty() then
		return self:set(path, data)
	end

	local sibling_node = self:_get(path)
	if not sibling_node then
		return
	end

	local parent_node = sibling_node.parent
	local child_node = self:_to_node(data, parent_node)

	local child_path = util.table.copy(path)
	child_path[#child_path] = child_path[#child_path] + 1

	table.insert(parent_node.children, child_path[#child_path], child_node)

	return self:get(child_path)
end

function Tree:remove(path)
	local node = self:_get(path)
	if not node then
		return
	end

	table.remove(node.parent.children, path[#path])

	return { data = node.data, path = util.table.copy(path) }
end

function Tree:is_empty()
	return #self._root.children == 0
end

function Tree:_get(path, include_root)
	if type(path) ~= "table" or #path == 0 then
		return
	end

	if self:is_empty() and include_root and #path == 1 and path[#path] == 1 then
		return self._root
	end

	local node = self._root

	for _, v in ipairs(path) do
		node = node.children[v]
		if not node then
			return
		end
	end

	if node == self._root then
		return
	end

	return node
end

function Tree:_insert_at(path, data)
	if self:is_empty() then
		return self:set(path, data)
	end

	if self:_get(path) then
		return self:insert_before(path, data)
	end

	local parent_node = #path == 1 and self._root or self:_get(util.list.slice(path, 1, -2), true)
	if not parent_node then
		return
	end

	if path[#path] < 1 or math.abs(path[#path] - #parent_node.children) > 1 then
		return
	end

	local child_node = self:_to_node(data, parent_node)
	table.insert(parent_node.children, path[#path], child_node)

	return child_node
end

function Tree:_traverse(node)
	local root = node or self._root
	local path = root == self._root and {} or { 1 }
	return self:_traverse_rec(root, path, {})
end

function Tree:_traverse_rec(node, path, result)
	if node ~= self._root then
		table.insert(result, { data = node.data, path = path })
	end

	for i, child in ipairs(node.children) do
		self:_traverse_rec(child, util.list.concat({}, path, i), result)
	end

	return result
end

function Tree:_to_node(data, parent)
	return {
		data = data,
		parent = parent,
		children = {},
	}
end

return Tree
