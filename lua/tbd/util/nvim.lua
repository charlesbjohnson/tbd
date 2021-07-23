local string_util = require("tbd.util.string")
local table_util = require("tbd.util.table")

local buf_set_keymap, define_augroup, define_autocmd, win_get_net_width

buf_set_keymap = function(buf, mode, key, map, opts)
	vim.api.nvim_buf_set_keymap(buf, mode, key, map, table_util.extend(opts or {}, { noremap = true, silent = true }))
end

define_augroup = function(name, fn)
	vim.api.nvim_exec("augroup " .. name, false)
	vim.api.nvim_exec("autocmd!", false)
	fn()
	vim.api.nvim_exec("augroup END", false)
end

define_autocmd = function(event, handler, options)
	options = options or {}

	local opt_buf = ""
	if options.buffer then
		opt_buf = "<buffer"

		if type(options.buffer) == "number" or type(options.buffer) == "string" then
			opt_buf = opt_buf .. "=" .. options.buffer
		end

		opt_buf = opt_buf .. ">"
	end

	vim.api.nvim_exec(
		string_util.template("autocmd ${event} ${opt_buf} ${handler}", {
			event = event,
			opt_buf = opt_buf,
			handler = handler,
		}),
		false
	)
end

win_get_net_width = function(win)
	local win_width = vim.api.nvim_win_get_width(win)
	local sign_width = 1
	local fold_width = vim.api.nvim_win_get_option(win, "foldcolumn")
	local num_width = (vim.api.nvim_win_get_option(win, "number") or vim.api.nvim_win_get_option(win, "relativenumber"))
			and math.max(
				vim.api.nvim_win_get_option(win, "numberwidth"),
				#tostring(vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)))
			)
		or 0

	return win_width - sign_width - fold_width - num_width
end

return setmetatable({
	buf_set_keymap = buf_set_keymap,
	define_augroup = define_augroup,
	define_autocmd = define_autocmd,
	win_get_net_width = win_get_net_width,
}, {
	__index = function(self, k)
		if rawget(self, k) == nil then
			return vim.api["nvim_" .. k]
		end

		return rawget(self, k)
	end,
})
