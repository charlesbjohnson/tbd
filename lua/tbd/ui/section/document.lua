local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local DocumentTree = require("tbd.data.document_tree")

local model, event, update, view

model = function()
	return mountable.model({
		buf = util.nvim.create_buf(true, false),
		tree = DocumentTree:new(),
		lines = nil,
		line = nil,
		cursor = nil,
	})
end

event = function(evt, data)
	if evt == "document/cursor_moved" then
		return { "document/reposition_cursor", { cursor = util.nvim.win_get_cursor(0) } }
	end

	if evt == "document/key_pressed" then
		data = util.table.extend(data, { key = util.nvim.decode_keycodes(data.key) })

		if data.key == "<Enter>" then
			return "document/begin_edit_line"
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

update = function(mdl, message)
	local action = message[1]
	local data = message[2]

	if action == "document/setup" then
		if not mountable.should_mount(mdl) then
			return mdl
		end

		mdl.cursor = util.nvim.win_get_cursor(0)

		mdl.tree:append_to(nil, "foo")
		mdl.tree:append_to(1, "bar")
		mdl.tree:append_to(2, "baz")
		mdl.tree:append_to(3, "qux")

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

		if mdl.cursor[1] ~= data.cursor[1] or data.cursor[2] < line.col - 1 then
			mdl.cursor = { data.cursor[1], line.col - 1 }
		else
			mdl.cursor = data.cursor
		end

		return mdl
	end

	if action == "document/begin_edit_line" then
		mdl.line = mdl.line or mdl.tree:get(mdl.cursor[1])

		return mdl, {
			"editor/setup",
			{
				cursor = mdl.cursor,
				line = mdl.line,
			},
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

	if action == "document/insert_before_line" then
		mdl.line = mdl.tree:insert_before(mdl.cursor[1], "FOO")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, "document/begin_edit_line"
	end

	if action == "document/insert_after_line" then
		mdl.line = mdl.tree:insert_after(mdl.cursor[1], "FOO")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, "document/begin_edit_line"
	end

	if action == "document/prepend_under_line" then
		mdl.line = mdl.tree:prepend_to(mdl.cursor[1], "FOO")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, "document/begin_edit_line"
	end

	if action == "document/append_under_line" then
		mdl.line = mdl.tree:append_to(mdl.cursor[1], "FOO")
		mdl.lines = mdl.tree:render()

		mdl.cursor = { mdl.line.row, mdl.line.col - 1 }

		return mdl, "document/begin_edit_line"
	end

	return mdl
end

view = function(mdl, prev, props)
	mountable.view(mdl, {
		mount = function()
			util.nvim.buf_set_option(mdl.buf, "buftype", "nowrite")
			util.nvim.buf_set_option(mdl.buf, "filetype", "tbd")
			util.nvim.buf_set_option(mdl.buf, "modifiable", true)

			util.nvim.define_augroup("TbdDocument", function()
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

			util.nvim.buf_set_keymap(mdl.buf, "n", "<Enter>", key_pressed_event("<Enter>"))

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
			util.nvim.buf_delete(mdl.buf, {})
		end,
	})
end

return {
	model = model,
	event = event,
	update = update,
	view = view,
}
