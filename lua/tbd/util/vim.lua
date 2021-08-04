local M = setmetatable({}, {
	__index = function(_, k)
		return vim.fn[k]
	end,
})
function M.get_current_register()
	return vim.fn.getreg(vim.api.nvim_get_vvar("register"))
end

function M.set_current_register(str)
	vim.fn.setreg(vim.api.nvim_get_vvar("register"), str)
end

return M
