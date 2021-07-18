local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local model, event, update, view
local parse_line

model = function()
	return mountable.model({
		buf = util.nvim.create_buf(true, false),
		cursor = nil,
		lines = nil,
	})
end

event = function(evt, data)
	if evt == "document/cursor_moved" then
		return { "document/reposition_cursor", { cursor = util.nvim.win_get_cursor(0) } }
	end

	if evt == "document/key_pressed" then
		if data.key == "Enter" then
			return "document/begin_edit_line"
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
		mdl.lines = { "foo", "  bar", "    baz", "      qux" }

		return mdl
	end

	if action == "document/teardown" then
		if not mountable.should_unmount(mdl) then
			return mdl
		end

		return mdl
	end

	if action == "document/reposition_cursor" then
		local line = parse_line(util.nvim.get_current_line())

		if mdl.cursor[1] ~= data.cursor[1] or data.cursor[2] < line.start - 1 then
			mdl.cursor = { data.cursor[1], line.start - 1 }
		else
			mdl.cursor = data.cursor
		end

		return mdl
	end

	if action == "document/begin_edit_line" then
		return mdl,
			{
				"editor/setup",
				{
					cursor = mdl.cursor,
					line = parse_line(util.nvim.get_current_line()),
				},
			}
	end

	if action == "document/finish_edit_line" then
		if data.line.source ~= mdl.lines[mdl.cursor[1]] then
			mdl.lines = util.table.copy(mdl.lines)
			mdl.lines[mdl.cursor[1]] = data.line.source
		end

		mdl.cursor = { mdl.cursor[1], (data.line.start - 1) + data.cursor[2] }

		return mdl
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

			util.nvim.buf_set_keymap(
				mdl.buf,
				"n",
				"<CR>",
				util.string.template(
					[[<Cmd>lua require("tbd").event(${app}, "document/key_pressed", { key = "Enter" })<CR>]],
					props
				),
				{ noremap = true, silent = true }
			)

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

parse_line = function(line)
	local start = (line:find("%S"))
	local parsed = line:sub(start)

	return {
		source = line,
		parsed = parsed,
		start = start,
	}
end

return {
	model = model,
	event = event,
	update = update,
	view = view,
}
