local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local model, event, update, view

model = function()
	return mountable.model({
		buf = nil,
		win = nil,
		cursor = nil,
		line = nil,
	})
end

event = function(evt, data)
	if evt == "editor/buffer_left" then
		return "editor/teardown"
	end

	if evt == "editor/cursor_moved" then
		return { "editor/reposition_cursor", { cursor = util.nvim.win_get_cursor(0) } }
	end

	if evt == "editor/key_pressed" then
		data = util.table.extend(data or {}, { mode = util.vim.mode() })

		if data.mode == "n" and data.key == "Esc" then
			return "editor/teardown"
		end
	end
end

update = function(mdl, message)
	local action = message[1]
	local data = message[2]

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
			col = data.line.col - 1,

			height = 1,
			width = util.nvim.win_get_net_width(0) - data.line.col,
		})

		mdl.cursor = { 1, data.cursor[2] - (data.line.col - 1) }
		mdl.line = data.line

		return mdl
	end

	if action == "editor/teardown" then
		if not mountable.should_unmount(mdl) then
			return mdl
		end

		local cursor = util.table.copy(mdl.cursor)
		mdl.cursor = nil

		local line = util.nvim.get_current_line()
		mdl.line = nil

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

view = function(mdl, prev, props)
	mountable.view(mdl, {
		mount = function()
			util.nvim.buf_set_option(mdl.buf, "bufhidden", "wipe")

			util.nvim.define_augroup("TbdEditor", function()
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
						key = key,
					}
				)
			end

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Esc>", key_pressed_event("Esc"))

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
				util.nvim.buf_set_lines(mdl.buf, 0, 1, true, { mdl.line.parsed })
				util.nvim.buf_set_option(mdl.buf, "undolevels", 1000)
			end

			if mdl.cursor and prev.cursor ~= mdl.cursor then
				util.nvim.win_set_cursor(mdl.win, mdl.cursor)
			end
		end,

		unmount = function()
			util.nvim.win_hide(mdl.win)
		end,
	})
end

return {
	model = model,
	event = event,
	update = update,
	view = view,
}