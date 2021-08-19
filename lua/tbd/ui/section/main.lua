local util = require("tbd.util")

local document = require("tbd.ui.section.document")
local editor = require("tbd.ui.section.editor")

local M = {}

function M.model()
	local buf = util.nvim.get_current_buf()

	local initial = {
		buf = buf,
		ns = util.nvim.create_namespace("Tbd" .. buf),
	}

	return {
		document = document.model(initial),
		editor = editor.model(initial),
	}
end

function M.id(mdl)
	return mdl.document.buf
end

function M.start()
	return "document/setup"
end

function M.event(evt, data)
	local messages = {}

	util.list.concat(messages, document.event(evt, data))
	util.list.concat(messages, editor.event(evt, data))

	return messages
end

function M.update(mdl, message)
	local dcmt, dcmt_msg = document.update(util.table.copy(mdl.document), message)
	local edtr, edtr_msg = editor.update(util.table.copy(mdl.editor), message)

	local next_model = { document = dcmt, editor = edtr }
	local next_messages = util.list.flatten({ dcmt_msg, edtr_msg }, 1)

	return next_model, next_messages
end

function M.view(mdl, prev, props)
	document.view(mdl.document, prev.document, props)
	editor.view(mdl.editor, prev.editor, props)
end

return M
