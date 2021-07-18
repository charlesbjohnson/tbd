local util = require("tbd.util")

local start, event, stop
local dispatch, to_messages, to_message, is_message

local apps = {}

start = function(program)
	local app = {
		program = program,
		model = program.model(),
		stopping = false,
	}

	app.id = app.program.id(app.model)
	apps[app.id] = app

	dispatch(app, app.program.start(app.model))
end

event = function(id, evt, data)
	local app = apps[id]
	if app and not app.stopping then
		dispatch(app, app.program.event(evt, data or {}))
	end
end

stop = function(app)
	if not app.stopping then
		app.stopping = true
		dispatch(app, app.program.stop(app.model))
		apps[app.id] = nil
	end
end

dispatch = function(app, messages)
	messages = to_messages(messages)
	if #messages == 0 then
		return
	end

	-- TODO: synchronization bug?
	local next_model = util.table.copy(app.model)
	local next_messages = {}

	for _, message in ipairs(messages) do
		if message[1] == "quit" then
			stop(app)
			return
		end

		local next_message
		next_model, next_message = app.program.update(next_model, message)
		util.list.concat(next_messages, to_messages(next_message))
	end

	local prev_model = app.model
	app.model = next_model

	app.program.view(app.model, prev_model, { app = app.id })

	if not app.stopping then
		dispatch(app, next_messages)
	end
end

to_messages = function(messages)
	if type(messages) == "string" then
		return { to_message(messages) }
	end

	if type(messages) == "table" then
		local result = {}

		local i = 1
		while i <= #messages do
			local v = messages[i]

			if is_message(v) then
				table.insert(result, v)
				i = i + 1
			elseif is_message({ v, messages[i + 1] }) then
				table.insert(result, to_message({ v, messages[i + 1] }))
				i = i + 2
			else
				table.insert(result, to_message(v))
				i = i + 1
			end
		end

		return result
	end

	return {}
end

to_message = function(message)
	if type(message) == "string" then
		return { message, {} }
	end

	if type(message) == "table" then
		return { message[1], message[2] or {} }
	end

	return {}
end

is_message = function(message)
	return type(message) == "table"
		and type(message[1]) == "string"
		and type(message[2]) == "table"
		and not is_message(message[2])
end

return {
	start = start,
	event = event,
}
