local util = require("tbd.util")

local Tree = {}
Tree.__index = Tree

function Tree:new()
	local obj = setmetatable({}, self)

	obj._root = self:_to_node()

	return obj
end

function Tree:get(path)
	path = path or {}

	local node = self:_get_node_at(path)
	if not node or node == self._root then
		return
	end

	return { data = node.data, path = path }
end

function Tree:get_parent(path)
	path = util.list.slice(path or {}, 1, -2)

	if #path == 0 then
		return
	end

	local node = self:_get_node_at(path)
	if not node then
		return
	end

	return { data = node.data, path = path }
end

function Tree:get_first_child(path)
	path = path or {}

	local parent_node = self:_get_node_at(path)
	if not parent_node or #parent_node.children == 0 then
		return
	end

	local child_node = parent_node.children[1]
	local child_path = util.list.concat({}, path, 1)

	return { data = child_node.data, path = child_path }
end

function Tree:get_next_sibling(path)
	path = path or {}

	local parent_node = self:_get_node_at(util.list.slice(path, 1, -2))
	if not parent_node then
		return
	end

	if path[#path] >= #parent_node.children then
		return
	end

	local sibling_path = util.table.copy(path)
	sibling_path[#sibling_path] = sibling_path[#sibling_path] + 1

	local sibling_node = parent_node.children[sibling_path[#sibling_path]]

	return { data = sibling_node.data, path = sibling_path }
end

function Tree:get_prev_sibling(path)
	path = path or {}

	local parent_node = self:_get_node_at(util.list.slice(path, 1, -2))
	if not parent_node then
		return
	end

	if path[#path] <= 1 then
		return
	end

	local sibling_path = util.table.copy(path)
	sibling_path[#sibling_path] = sibling_path[#sibling_path] - 1

	local sibling_node = parent_node.children[sibling_path[#sibling_path]]

	return { data = sibling_node.data, path = sibling_path }
end

function Tree:set(path, data)
	path = path or {}

	local node = self:_get_node_at(path)
	if not node or node == self._root then
		return
	end

	node.data = data

	return { data = node.data, path = path }
end

function Tree:iter()
	local traversal = self:_traverse()
	local i = 0

	return function()
		i = i + 1

		if i <= #traversal then
			return traversal[i]
		end
	end
end

function Tree:prepend_to(path, data)
	path = path or {}

	local node = self:_get_node_at(path)
	if not node then
		return
	end

	local child_node = self:_to_node(data)
	local child_path = util.list.concat({}, path, 1)

	table.insert(node.children, child_path[#child_path], child_node)

	return { data = child_node.data, path = child_path }
end

function Tree:append_to(path, data)
	path = path or {}

	local node = self:_get_node_at(path)
	if not node then
		return
	end

	local child_node = self:_to_node(data)
	local child_path = util.list.concat({}, path, #node.children + 1)

	table.insert(node.children, child_path[#child_path], child_node)

	return { data = child_node.data, path = child_path }
end

function Tree:insert_before(path, data)
	path = path or {}

	local parent_node = self:_get_node_at(util.list.slice(path, 1, -2))
	if not parent_node then
		return
	end

	local child_node = self:_to_node(data)
	local child_path = util.table.copy(path)
	child_path[#child_path] = child_path[#child_path] or 1

	table.insert(parent_node.children, child_path[#child_path], child_node)

	return { data = child_node.data, path = child_path }
end

function Tree:insert_after(path, data)
	path = path or {}

	local parent_node = self:_get_node_at(util.list.slice(path, 1, -2))
	if not parent_node then
		return
	end

	local child_node = self:_to_node(data)
	local child_path = util.table.copy(path)
	child_path[#child_path] = (child_path[#child_path] or 0) + 1

	table.insert(parent_node.children, child_path[#child_path], child_node)

	return { data = child_node.data, path = child_path }
end

function Tree:remove(path)
	path = path or {}

	local parent_node = self:_get_node_at(util.list.slice(path, 1, -2))
	if not parent_node then
		return
	end

	local child_node = parent_node.children[path[#path]]
	local child_path = util.table.copy(path)

	table.remove(parent_node.children, path[#path])

	return { data = child_node.data, path = child_path }
end

function Tree:_get_node_at(path)
	if type(path) ~= "table" then
		return
	end

	local node = self._root

	for _, v in ipairs(path) do
		node = node.children[tonumber(v)]
		if not node then
			return
		end
	end

	return node
end

function Tree:_to_node(data)
	return {
		data = data,
		children = {},
	}
end

function Tree:_traverse()
	return self:_traverse_rec(self._root, {}, {})
end

function Tree:_traverse_rec(node, result, path)
	if node ~= self._root then
		table.insert(result, { data = node.data, path = path })
	end

	for i, child in ipairs(node.children) do
		self:_traverse_rec(child, result, util.list.concat({}, path, i))
	end

	return result
end

return Tree
