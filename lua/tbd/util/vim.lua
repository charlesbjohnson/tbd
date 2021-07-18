return setmetatable({}, {
	__index = function(_, k)
		return vim.fn[k]
	end,
})
