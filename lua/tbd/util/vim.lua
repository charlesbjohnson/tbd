local M = setmetatable({}, {
	__index = function(_, k)
		return vim.fn[k]
	end,
})

return M
