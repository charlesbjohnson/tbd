local util = require("tbd.util")

local document = require("tbd.ui.section.document")
local editor = require("tbd.ui.section.editor")

local model, id, start, event, update, view

model = function()
	return {
		document = document.model(),
		editor = editor.model(),
	}
end

id = function(mdl)
	return mdl.document.buf
end

start = function()
	return "document/setup"
end

event = function(evt, data)
	local messages = {}

	util.list.concat(messages, document.event(evt, data))
	util.list.concat(messages, editor.event(evt, data))

	return messages
end

update = function(mdl, message)
	local dcmt, dcmt_msg = document.update(util.table.copy(mdl.document), message)
	local edtr, edtr_msg = editor.update(util.table.copy(mdl.editor), message)

	local next_model = { document = dcmt, editor = edtr }
	local next_messages = util.list.flatten({ dcmt_msg, edtr_msg }, 1)

	return next_model, next_messages
end

view = function(mdl, prev, props)
	document.view(mdl.document, prev.document, props)
	editor.view(mdl.editor, prev.editor, props)
end

return {
	model = model,
	id = id,
	start = start,
	event = event,
	update = update,
	view = view,
}
