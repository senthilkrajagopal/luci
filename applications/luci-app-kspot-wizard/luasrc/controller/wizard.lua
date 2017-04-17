module("luci.controller.wizard", package.seeall)

function index()
	entry({"admin", "wizard"},
		alias("admin", "wizard", "wizard"),
		_("Admin"), 1)

	entry({"admin", "wizard", "wizard"},
		cbi("wizard/wizard"),
		_("Network"), 20).leaf = true

end
