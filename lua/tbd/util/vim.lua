local M = setmetatable({}, {
	__index = function(_, k)
		if vim[k] == nil then
			return vim.fn[k]
		end

		return vim[k]
	end,
})

return M
