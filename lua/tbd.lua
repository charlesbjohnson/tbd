local app = require("tbd.ui.app")
local main = require("tbd.ui.section.main")

local start, event

start = function()
	app.start(main)
end

event = function(id, evt, data)
	app.event(id, evt, data)
end

return {
	start = start,
	event = event,
}
