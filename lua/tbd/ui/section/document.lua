local util = require("tbd.util")
local mountable = require("tbd.ui.common.mountable")

local DocumentTree = require("tbd.data.document_tree")

local M = {}

function M.model()
	return mountable.model({
		buf = util.nvim.create_buf(true, false),
		ns = util.nvim.create_namespace("Tbd"),

		tree = nil,
		cursor = nil,
		line = nil,

		history = {
			past = {},
			future = {},
		},

		lines = nil,
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

		if data.key == "yy" then
			return "document/yank_line"
		end

		if data.key == "yt" then
			return "document/yank_tree"
		end

		if data.key == "p" then
			return "document/paste_after_line"
		end

		if data.key == "P" then
			return "document/paste_before_line"
		end

		if data.key == "<Tab>P" then
			return "document/paste_prepend_under_line"
		end

		if data.key == "<Tab>p" then
			return "document/paste_append_under_line"
		end

		if data.key == "dd" then
			return "document/delete_line"
		end

		if data.key == "dt" then
			return "document/delete_tree"
		end

		if data.key == "zc" then
			return "document/fold_tree"
		end

		if data.key == "zC" then
			return "document/fold_tree_downward"
		end

		if data.key == "zM" then
			return "document/fold_all"
		end

		if data.key == "zo" then
			return "document/unfold_tree"
		end

		if data.key == "zO" then
			return "document/unfold_tree_downward"
		end

		if data.key == "zR" then
			return "document/unfold_all"
		end

		if data.key == "u" then
			return "document/undo"
		end

		if data.key == "<C-r>" then
			return "document/redo"
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

		mdl.tree = DocumentTree:new()
		mdl.cursor = { 1, 0 }

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

		mdl.lines = mdl.tree:to_lines()

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

		if line and (mdl.cursor[1] ~= data.cursor[1] or data.cursor[2] < line.col_start - 1) then
			mdl.cursor = { data.cursor[1], line.col_start - 1 }
		else
			mdl.cursor = data.cursor
		end

		return mdl
	end

	if action == "document/step_up_cursor" then
		local line = mdl.tree:get_parent(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col_start - 1 }
		end

		return mdl
	end

	if action == "document/step_down_cursor" then
		local line = mdl.tree:get_first_child(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col_start - 1 }
		end

		return mdl
	end

	if action == "document/over_next_cursor" then
		local line = mdl.tree:get_next_sibling(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col_start - 1 }
		end

		return mdl
	end

	if action == "document/over_prev_cursor" then
		local line = mdl.tree:get_prev_sibling(mdl.cursor[1])

		if line then
			mdl.cursor = { line.row, line.col_start - 1 }
		end

		return mdl
	end

	if action == "document/begin_edit_line" then
		if not mdl.line then
			table.insert(mdl.history.past, {
				tree = mdl.tree,
				cursor = mdl.cursor,
				line = nil,
			})

			mdl.tree = mdl.tree:copy()
			mdl.cursor = util.table.copy(mdl.cursor)

			mdl.line = mdl.tree:get(mdl.cursor[1])
			if not mdl.line then
				mdl.line = mdl.tree:set(mdl.cursor[1], "__")
				data.start_blank = true
			end
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
		mdl.history.future = {}

		if data.line == "" then
			mdl.line = mdl.tree:remove(mdl.line.row)
		else
			mdl.line = mdl.tree:set(mdl.line.row, data.line)
			mdl.cursor = { mdl.line.row, (mdl.line.col_start - 1) + data.cursor[2] }
		end

		mdl.history.past[#mdl.history.past].line = mdl.line
		mdl.line = nil

		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/abort_edit_line" then
		table.remove(mdl.history.past)

		if data.line == "" then
			mdl.line = mdl.tree:remove(mdl.line.row)
			mdl.lines = mdl.tree:to_lines()
		end

		mdl.line = nil

		return mdl
	end

	if action == "document/insert_before_line" then
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		mdl.line = mdl.tree:insert_before(mdl.cursor[1], "__")
		mdl.cursor = { mdl.line.row, mdl.line.col_start - 1 }

		mdl.lines = mdl.tree:to_lines()

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/insert_after_line" then
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		mdl.line = mdl.tree:insert_after(mdl.cursor[1], "__")
		mdl.cursor = { mdl.line.row, mdl.line.col_start - 1 }

		mdl.lines = mdl.tree:to_lines()

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/prepend_under_line" then
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		mdl.line = mdl.tree:prepend_to(mdl.cursor[1], "__")
		mdl.cursor = { mdl.line.row, mdl.line.col_start - 1 }

		mdl.lines = mdl.tree:to_lines()

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/append_under_line" then
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		mdl.line = mdl.tree:append_to(mdl.cursor[1], "__")
		mdl.cursor = { mdl.line.row, mdl.line.col_start - 1 }

		mdl.lines = mdl.tree:to_lines()

		return mdl, { "document/begin_edit_line", { start_blank = true, start_insert = true } }
	end

	if action == "document/yank_line" then
		local line = mdl.tree:get(mdl.cursor[1])

		if line then
			util.vim.set_current_register(line.parsed)
		end

		return mdl
	end

	if action == "document/yank_tree" then
		local tree = mdl.tree:get_tree(mdl.cursor[1])

		if tree then
			util.vim.set_current_register(util.string.join(tree:to_source_lines(), "\n"))
		end

		return mdl
	end

	if action == "document/paste_before_line" then
		local lines = util.string.split(util.vim.get_current_register(), "\n")
		local tree = DocumentTree:from_lines(lines)

		if tree then
			mdl.history.future = {}
			table.insert(mdl.history.past, {
				tree = mdl.tree,
				cursor = mdl.cursor,
				line = nil,
			})

			mdl.tree = mdl.tree:copy()
			mdl.line = mdl.tree:insert_tree_before(mdl.cursor[1], tree)
			mdl.cursor = { mdl.line.row, mdl.line.col_start - 1 }

			mdl.history.past[#mdl.history.past].line = mdl.line
			mdl.line = nil

			mdl.lines = mdl.tree:to_lines()
		end

		return mdl
	end

	if action == "document/paste_after_line" then
		local lines = util.string.split(util.vim.get_current_register(), "\n")
		local tree = DocumentTree:from_lines(lines)

		if tree then
			mdl.history.future = {}
			table.insert(mdl.history.past, {
				tree = mdl.tree,
				cursor = mdl.cursor,
				line = nil,
			})

			mdl.tree = mdl.tree:copy()
			mdl.line = mdl.tree:insert_tree_after(mdl.cursor[1], tree)
			mdl.cursor = { mdl.line.row, mdl.line.col_end - 1 }

			mdl.history.past[#mdl.history.past].line = mdl.line
			mdl.line = nil

			mdl.lines = mdl.tree:to_lines()
		end

		return mdl
	end

	if action == "document/paste_prepend_under_line" then
		local lines = util.string.split(util.vim.get_current_register(), "\n")
		local tree = DocumentTree:from_lines(lines)

		if tree then
			mdl.history.future = {}
			table.insert(mdl.history.past, {
				tree = mdl.tree,
				cursor = mdl.cursor,
				line = nil,
			})

			mdl.tree = mdl.tree:copy()
			mdl.line = mdl.tree:prepend_tree_to(mdl.cursor[1], tree)
			mdl.cursor = { mdl.line.row, mdl.line.col_end - 1 }

			mdl.history.past[#mdl.history.past].line = mdl.line
			mdl.line = nil

			mdl.lines = mdl.tree:to_lines()
		end

		return mdl
	end

	if action == "document/paste_append_under_line" then
		local lines = util.string.split(util.vim.get_current_register(), "\n")
		local tree = DocumentTree:from_lines(lines)

		if tree then
			mdl.history.future = {}
			table.insert(mdl.history.past, {
				tree = mdl.tree,
				cursor = mdl.cursor,
				line = nil,
			})

			mdl.tree = mdl.tree:copy()
			mdl.line = mdl.tree:append_tree_to(mdl.cursor[1], tree)
			mdl.cursor = { mdl.line.row, mdl.line.col_end - 1 }

			mdl.history.past[#mdl.history.past].line = mdl.line
			mdl.line = nil

			mdl.lines = mdl.tree:to_lines()
		end

		return mdl
	end

	if action == "document/delete_line" then
		if not mdl.tree:get(mdl.cursor[1]) then
			return mdl
		end

		mdl.history.future = {}
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		mdl.line = mdl.tree:remove(mdl.cursor[1])

		util.vim.set_current_register(mdl.line.parsed)

		mdl.history.past[#mdl.history.past].line = mdl.line
		mdl.line = nil

		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/delete_tree" then
		if not mdl.tree:get(mdl.cursor[1]) then
			return mdl
		end

		mdl.history.future = {}
		table.insert(mdl.history.past, {
			tree = mdl.tree,
			cursor = mdl.cursor,
			line = nil,
		})

		mdl.tree = mdl.tree:copy()
		local tree = mdl.tree:remove_tree(mdl.cursor[1])
		mdl.line = tree:get(1)

		util.vim.set_current_register(util.string.join(tree:to_source_lines(), "\n"))

		mdl.history.past[#mdl.history.past].line = mdl.line
		mdl.line = nil

		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/fold_tree" then
		mdl.tree:fold(mdl.cursor[1])
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/fold_tree_downward" then
		mdl.tree:fold_downward(mdl.cursor[1])
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/fold_all" then
		mdl.tree:fold_all()
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/unfold_tree" then
		mdl.tree:unfold(mdl.cursor[1])
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/unfold_tree_downward" then
		mdl.tree:unfold_downward(mdl.cursor[1])
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/unfold_all" then
		mdl.tree:unfold_all()
		mdl.lines = mdl.tree:to_lines()

		return mdl
	end

	if action == "document/undo" then
		if #mdl.history.past > 0 then
			local past = mdl.history.past[#mdl.history.past]
			local future = {
				tree = mdl.tree,
				cursor = past.cursor,
				line = past.line,
			}

			table.remove(mdl.history.past)
			table.insert(mdl.history.future, future)

			mdl.tree = past.tree
			mdl.cursor = past.cursor

			mdl.tree:unfold_downward(mdl.cursor[1])
			mdl.tree:unfold_upward(past.line.path)

			mdl.lines = mdl.tree:to_lines(true)
		end

		return mdl
	end

	if action == "document/redo" then
		if #mdl.history.future > 0 then
			local future = mdl.history.future[#mdl.history.future]
			local past = {
				tree = mdl.tree,
				cursor = future.cursor,
				line = future.line,
			}

			table.remove(mdl.history.future)
			table.insert(mdl.history.past, past)

			mdl.tree = future.tree
			mdl.cursor = future.cursor

			mdl.tree:unfold_downward(mdl.cursor[1])
			mdl.tree:unfold_upward(future.line.path)

			mdl.lines = mdl.tree:to_lines(true)
		end

		return mdl
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

			util.nvim.buf_set_keymap(mdl.buf, "n", "yy", key_pressed_event("yy"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "yt", key_pressed_event("yt"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "p", key_pressed_event("p"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "P", key_pressed_event("P"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "<Tab>p", key_pressed_event("<Tab>p"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "<Tab>P", key_pressed_event("<Tab>P"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "dd", key_pressed_event("dd"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "dt", key_pressed_event("dt"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "zc", key_pressed_event("zc"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "zC", key_pressed_event("zC"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "zM", key_pressed_event("zM"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "zo", key_pressed_event("zo"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "zO", key_pressed_event("zO"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "zR", key_pressed_event("zR"))

			util.nvim.buf_set_keymap(mdl.buf, "n", "u", key_pressed_event("u"))
			util.nvim.buf_set_keymap(mdl.buf, "n", "<C-r>", key_pressed_event("<C-r>"))

			util.nvim.win_set_buf(0, mdl.buf)
		end,

		view = function()
			if mdl.lines and prev.lines ~= mdl.lines then
				util.nvim.buf_set_option(mdl.buf, "modifiable", true)

				util.nvim.buf_set_lines(mdl.buf, #mdl.lines, -1, false, {})

				for row, line in ipairs(mdl.lines) do
					util.nvim.buf_set_lines(mdl.buf, row - 1, row, false, { line.source })

					if line.meta then
						util.nvim.buf_set_extmark(mdl.buf, mdl.ns, row - 1, -1, {
							id = row,
							virt_text = { { line.meta, "Normal" } },
						})
					end
				end

				util.nvim.buf_set_option(mdl.buf, "modifiable", false)
			end

			if mdl.cursor and prev.cursor ~= mdl.cursor then
				util.nvim.win_set_cursor(0, { math.min(mdl.cursor[1], #mdl.lines + 1), mdl.cursor[2] })
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
