local string_util = require("tbd.util.string")
local table_util = require("tbd.util.table")
local vim_util = require("tbd.util.vim")

local M = setmetatable({}, {
	__index = function(self, k)
		if rawget(self, k) == nil then
			return vim.api["nvim_" .. k]
		end

		return rawget(self, k)
	end,
})

function M.get_current_register()
	return vim_util.getreg(vim.api.nvim_get_vvar("register"))
end

function M.set_current_register(str)
	vim_util.setreg(vim.api.nvim_get_vvar("register"), str)
end

function M.define_augroup(name, fn)
	vim.api.nvim_exec("augroup " .. name, false)
	vim.api.nvim_exec("autocmd!", false)
	fn()
	vim.api.nvim_exec("augroup END", false)
end

function M.define_autocmd(event, handler, options)
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

function M.decode_keycodes(str)
	return ((str:gsub("&lt;", "<")):gsub("&gt;", ">"))
end

function M.encode_keycodes(str)
	return ((str:gsub("<", "&lt;")):gsub(">", "&gt;"))
end

function M.buf_set_keymap(buf, mode, key, map, opts)
	vim.api.nvim_buf_set_keymap(buf, mode, key, map, table_util.extend(opts or {}, { noremap = true, silent = true }))
end

function M.win_get_net_width(win)
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

return M
