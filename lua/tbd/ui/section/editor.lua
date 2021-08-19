local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local M = {}

function M.model(_)
	return mountable.model({
		buf = nil,
		win = nil,

		start_blank = nil,
		start_insert = nil,
		start_append = nil,

		cursor = nil,
		line = nil,
	})
end

function M.event(evt, data)
	if evt == "editor/buffer_left" then
		return "editor/teardown"
	end

	if evt == "editor/cursor_moved" then
		return { "editor/reposition_cursor", { cursor = util.nvim.win_get_cursor(0) } }
	end

	if evt == "editor/key_pressed" then
		data = util.table.extend(data, { key = util.nvim.decode_keycodes(data.key) })

		if data.key == "<Esc>" then
			return "editor/teardown"
		end
	end
end

function M.update(mdl, message)
	local action = message[1]
	local data = message[2]

	mdl.start_blank = nil
	mdl.start_insert = nil
	mdl.start_append = nil

	if action == "editor/setup" then
		if not mountable.should_mount(mdl) then
			return mdl
		end

		mdl.buf = util.nvim.create_buf(false, true)
		mdl.win = util.nvim.open_win(mdl.buf, false, {
			style = "minimal",
			relative = "win",

			bufpos = { 0, 0 },
			row = data.line.row - 1,
			col = data.line.col_start - 1,

			height = 1,
			width = util.nvim.win_get_net_width(0) - data.line.col_start,
		})

		mdl.start_blank = data.start_blank and true or false
		mdl.start_insert = data.start_insert and true or false
		mdl.start_append = data.start_append and true or false

		mdl.cursor = { 1, data.cursor[2] - (data.line.col_start - 1) }
		if mdl.start_append then
			mdl.cursor[2] = mdl.cursor[2] + 1

			if mdl.cursor[2] < #data.line.parsed then
				mdl.start_append = false
				mdl.start_insert = true
			end
		end

		mdl.line = data.line.parsed
		if mdl.start_blank then
			mdl.line = ""
		end

		return mdl
	end

	if action == "editor/teardown" then
		if not mountable.should_unmount(mdl) then
			return mdl
		end

		local cursor = util.table.copy(mdl.cursor)
		mdl.cursor = nil

		local line = util.string.trim(util.nvim.get_current_line())
		local orig = mdl.line

		mdl.line = nil

		if line == orig then
			return mdl, { "document/abort_edit_line", { line = line } }
		end

		return mdl, {
			"document/finish_edit_line",
			{
				cursor = cursor,
				line = line,
			},
		}
	end

	if action == "editor/reposition_cursor" then
		if data.cursor[1] ~= 1 then
			mdl.cursor = { 1, data.cursor[2] }
		else
			mdl.cursor = data.cursor
		end

		return mdl
	end

	return mdl
end

function M.view(mdl, prev, props)
	mountable.view(mdl, {
		mount = function()
			util.nvim.buf_set_option(mdl.buf, "bufhidden", "wipe")

			util.nvim.define_augroup("TbdEditor" .. mdl.buf, function()
				util.nvim.define_autocmd(
					"BufLeave",
					util.string.template([[lua require("tbd").event(${app}, "editor/buffer_left")]], props),
					{ buffer = mdl.buf }
				)

				util.nvim.define_autocmd(
					"CursorMoved",
					util.string.template([[lua require("tbd").event(${app}, "editor/cursor_moved")]], props),
					{ buffer = mdl.buf }
				)
			end)

			local key_pressed_event = function(key)
				return util.string.template(
					[[<Cmd>lua require("tbd").event(${app}, "editor/key_pressed", { key = "${key}" })<CR>]],
					{
						app = props.app,
						key = util.nvim.encode_keycodes(key),
					}
				)
			end

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Esc>", key_pressed_event("<Esc>"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Enter>", "<NOP>")
			util.nvim.buf_set_keymap(mdl.buf, "i", "<Enter>", "<NOP>")

			util.nvim.buf_set_keymap(mdl.buf, "n", "o", "<NOP>")
			util.nvim.buf_set_keymap(mdl.buf, "n", "O", "<NOP>")

			util.nvim.buf_set_keymap(mdl.buf, "n", "j", "<NOP>")
			util.nvim.buf_set_keymap(mdl.buf, "n", "k", "<NOP>")

			util.nvim.set_current_win(mdl.win)
		end,

		view = function()
			if mdl.line and prev.line ~= mdl.line then
				util.nvim.buf_set_option(mdl.buf, "undolevels", -1)
				util.nvim.buf_set_lines(mdl.buf, 0, 1, true, { mdl.line })
				util.nvim.buf_set_option(mdl.buf, "undolevels", 1000)
			end

			if mdl.cursor and prev.cursor ~= mdl.cursor then
				util.nvim.win_set_cursor(mdl.win, mdl.cursor)
			end

			if mdl.start_insert then
				util.nvim.command("startinsert")
			elseif mdl.start_append then
				util.nvim.command("startinsert!")
			end
		end,

		unmount = function()
			util.nvim.win_hide(mdl.win)
		end,
	})
end

return M
