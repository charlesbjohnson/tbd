local app = require("tbd.ui.app")
local main = require("tbd.ui.section.main")

local M = {}

function M.start()
	app.start(main)
end

function M.event(id, evt, data)
	app.event(id, evt, data)
end

return M
