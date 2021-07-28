local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local DocumentTree = require("tbd.data.document_tree")

local M = {}

function M.model()
	return mountable.model({
		buf = util.nvim.create_buf(true, false),
		tree = DocumentTree:new(),
		lines = nil,
		line = nil,
		cursor = nil,
	})
end

function M.event(evt, data)
	if evt == "document/buffer_unloaded" then
		return { "document/teardown", "quit" }
	end

	if evt == "document/cursor_moved" then
		return { "document/reposition_cursor", { cursor = util.nvim.win_get_cursor(0) } }
	end

	if evt == "document/key_pressed" then
		data = util.table.extend(data, { key = util.nvim.decode_keycodes(data.key) })

		if data.key == "H" then
			return "document/step_up_cursor"
		end

		if data.key == "J" then
			return "document/over_next_cursor"
		end

		if data.key == "K" then
			return "document/over_prev_cursor"
		end

		if data.key == "L" then
			return "document/step_down_cursor"
		end

		if data.key == "<Enter>" then
			return "document/begin_edit_line"
		end

		if data.key == "i" then
			return { "document/begin_edit_line", { start_insert = true } }
		end

		if data.key == "a" then
			return { "document/begin_edit_line", { start_append = true } }
		end

		if data.key == "O" then
			return "document/insert_before_line"
		end

		if data.key == "o" then
			return "document/insert_after_line"
		end

		if data.key == "<Tab>O" then
			return "document/prepend_under_line"
		end

		if data.key == "<Tab>o" then
			return "document/append_under_line"
		end
	end
end

function M.update(mdl, message)
	local action = message[1]
	local data = message[2]

	if action == "document/setup" then
		if not mountable.should_mount(mdl) then
			return mdl
		end

		mdl.cursor = util.nvim.win_get_cursor(0)

		mdl.tree:set(1, "foo")
		mdl.tree:insert_after(1, "foo")
		mdl.tree:insert_after(1, "foo")

		mdl.tree:append_to(1, "bar")
		mdl.tree:insert_after(2, "bar")

		mdl.tree:append_to(3, "baz")
		mdl.tree:insert_after(4, "baz")

		mdl.tree:append_to(4, "qux")
		mdl.tree:append_to(4, "qux")
		mdl.tree:append_to(7, "qux")

		mdl.lines = mdl.tree:render()

		return mdl
	end

	if action == "document/teardown" then
		if not mountable.should_unmount(mdl) then
			return mdl
		end

		return mdl
	end

	if action == "document/reposition_cursor" then
		local line = mdl.tree:get(data.cursor[1])

		if line and (mdl.cursor[1] ~= data.cursor[1] or data.cursor[2] < line.col - 1) then
			mdl.cursor = { data.cursor[1], line.col - 1 }
		else
			mdl.cursor = data.cursor
		end

		return mdl
	end

	if action == "document/step_up_cursor" then
		local line = mdl.tree:get_parent(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col - 1 }
		end

		return mdl
	end

	if action == "document/step_down_cursor" then
		local line = mdl.tree:get_first_child(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col - 1 }
		end

		return mdl
	end

	if action == "document/over_next_cursor" then
		local line = mdl.tree:get_next_sibling(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col - 1 }
		end

		return mdl
	end

	if action == "document/over_prev_cursor" then
		local line = mdl.tree:get_prev_sibling(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col - 1 }
		end

		return mdl
	end

	if action == "document/begin_edit_line" then
		mdl.line = mdl.line or mdl.tree:get(mdl.cursor[1])

		if not mdl.line then
			mdl.line = mdl.tree:set(mdl.cursor[1], "__")
			data.start_blank = true
		end

		return mdl,
			{
				"editor/setup",
				util.table.extend(data, {
					cursor = mdl.cursor,
					line = mdl.line,
				}),
			}
	end

	if action == "document/finish_edit_line" then
		if mdl.line.parsed ~= data.line then
			mdl.line = mdl.tree:set(mdl.line.row, data.line)
			mdl.lines = mdl.tree:render()
		end

		mdl.cursor = { mdl.line.row, (mdl.line.col - 1) + data.cursor[2] }
		mdl.line = nil

		return mdl
	end

	if action == "document/abort_edit_line" then
		mdl.line = mdl.tree:remove(mdl.line.row)
		mdl.lines = mdl.tree:render()

		mdl.line = nil

		return mdl
	end

	if action == "document/insert_before_line" then
		mdl.line = mdl.tree:insert_before(mdl.cursor[1], "__")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/insert_after_line" then
		mdl.line = mdl.tree:insert_after(mdl.cursor[1], "__")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/prepend_under_line" then
		mdl.line = mdl.tree:prepend_to(mdl.cursor[1], "__")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/append_under_line" then
		mdl.line = mdl.tree:append_to(mdl.cursor[1], "__")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	return mdl
end

function M.view(mdl, prev, props)
	mountable.view(mdl, {
		mount = function()
			util.nvim.buf_set_option(mdl.buf, "buftype", "nowrite")
			util.nvim.buf_set_option(mdl.buf, "filetype", "tbd")
			util.nvim.buf_set_option(mdl.buf, "modifiable", true)

			util.nvim.define_augroup("TbdDocument", function()
				util.nvim.define_autocmd(
					"BufUnload",
					util.string.template([[lua require("tbd").event(${app}, "document/buffer_unloaded")]], props),
					{ buffer = mdl.buf }
				)

				util.nvim.define_autocmd(
					"CursorMoved",
					util.string.template([[lua require("tbd").event(${app}, "document/cursor_moved")]], props),
					{ buffer = mdl.buf }
				)
			end)

			local key_pressed_event = function(key)
				return util.string.template(
					[[<Cmd>lua require("tbd").event(${app}, "document/key_pressed", { key = "${key}" })<CR>]],
					{
						app = props.app,
						key = util.nvim.encode_keycodes(key),
					}
				)
			end

			util.nvim.buf_set_keymap(mdl.buf, "n", "H", key_pressed_event("H"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "J", key_pressed_event("J"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "K", key_pressed_event("K"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "L", key_pressed_event("L"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Enter>", key_pressed_event("<Enter>"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "i", key_pressed_event("i"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "a", key_pressed_event("a"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "o", key_pressed_event("o"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "O", key_pressed_event("O"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Tab>o", key_pressed_event("<Tab>o"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "<Tab>O", key_pressed_event("<Tab>O"))

			util.nvim.win_set_buf(0, mdl.buf)
		end,

		view = function()
			if mdl.lines and prev.lines ~= mdl.lines then
				util.nvim.buf_set_option(mdl.buf, "modifiable", true)
				util.nvim.buf_set_lines(mdl.buf, 0, -1, false, mdl.lines)
				util.nvim.buf_set_option(mdl.buf, "modifiable", false)
			end

			if mdl.cursor and prev.cursor ~= mdl.cursor then
				util.nvim.win_set_cursor(0, mdl.cursor)
			end
		end,

		unmount = function()
			vim.schedule(function()
				util.nvim.buf_delete(mdl.buf, {})
			end)
		end,
	})
end

return M
