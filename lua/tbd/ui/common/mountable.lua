local util = require("tbd.util")

local function model(decorated)
	return util.table.extend(decorated, {
		mountable = {
			mounted = false,
			should_mount = false,
			should_unmount = false,
		},
	})
end

local function view(mdl, options)
	options = options or {}

	if not mdl.mountable.mounted and mdl.mountable.should_mount then
		mdl.mountable.mounted = true
		mdl.mountable.should_mount = false
		mdl.mountable.should_unmount = false;

		(options.mount or function() end)()
	end

	if mdl.mountable.mounted then
		(options.view or function() end)()
	end

	if mdl.mountable.mounted and mdl.mountable.should_unmount then
		mdl.mountable.mounted = false
		mdl.mountable.should_mount = false
		mdl.mountable.should_unmount = false;

		(options.unmount or function() end)()
	end
end

local function should_mount(mdl)
	if mdl.mountable.mounted then
		return false
	end

	mdl.mountable.should_mount = true
	mdl.mountable.should_unmount = false

	return true
end

local function should_unmount(mdl)
	if not mdl.mountable.mounted then
		return false
	end

	mdl.mountable.should_mount = false
	mdl.mountable.should_unmount = true

	return true
end

return {
	model = model,
	view = view,
	should_mount = should_mount,
	should_unmount = should_unmount,
}
