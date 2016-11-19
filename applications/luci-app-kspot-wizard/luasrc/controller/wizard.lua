module("luci.controller.wizard", package.seeall)

function index()
	entry({"admin", "wizard"},
		alias("admin", "wizard", "wizard"),
		_("Configuration"), 1)

	entry({"admin", "wizard", "wizard"},
		cbi("wizard/wizard"),
		_("Wizard"), 20).leaf = true

end
