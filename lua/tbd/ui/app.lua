local util = require("tbd.util")

local M = {}
local P = { apps = {} }

function M.start(program)
	local app = {
		program = program,
		model = program.model(),
	}

	app.id = app.program.id(app.model)
	P.apps[app.id] = app

	P.dispatch(app, app.program.start(app.model))
end

function M.event(id, evt, data)
	local app = P.apps[id]
	if app then
		P.dispatch(app, app.program.event(evt, data or {}))
	end
end

function P.dispatch(app, messages)
	messages = P.to_messages(messages)
	if #messages == 0 then
		return
	end

	local next_model = util.table.copy(app.model)
	local next_messages = {}

	for _, message in ipairs(messages) do
		if message[1] == "quit" then
			P.apps[app.id] = nil
			return
		end

		local next_message
		next_model, next_message = app.program.update(next_model, message)
		util.list.concat(next_messages, P.to_messages(next_message))
	end

	local prev_model = app.model
	app.model = next_model

	app.program.view(app.model, prev_model, { app = app.id })

	P.dispatch(app, next_messages)
end

function P.to_messages(messages)
	if type(messages) == "string" then
		return { P.to_message(messages) }
	end

	if type(messages) == "table" then
		local result = {}

		local i = 1
		while i <= #messages do
			local v = messages[i]

			if P.is_message(v) then
				table.insert(result, v)
				i = i + 1
			elseif P.is_message({ v, messages[i + 1] }) then
				table.insert(result, P.to_message({ v, messages[i + 1] }))
				i = i + 2
			else
				table.insert(result, P.to_message(v))
				i = i + 1
			end
		end

		return result
	end

	return {}
end

function P.to_message(message)
	if type(message) == "string" then
		return { message, {} }
	end

	if type(message) == "table" then
		return { message[1], message[2] or {} }
	end

	return {}
end

function P.is_message(message)
	return type(message) == "table"
		and type(message[1]) == "string"
		and type(message[2]) == "table"
		and not P.is_message(message[2])
end

return M
