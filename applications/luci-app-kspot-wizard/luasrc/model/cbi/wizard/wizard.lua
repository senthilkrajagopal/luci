--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local nw = require "luci.model.network"
local ut = require "luci.util"

m = Map("network", translate("Configuration Wizard"),
	translate("Configuration Wizard : to simplify initial setup of the your wireless router"))

s = m:section(NamedSection, "wan",  "interface", translate("WAN"))
s.addremove = false
s.anonymous = false
s.optional = false

nw.init(m.uci)
local net = nw:get_network("wan")

local function backup_ifnames(is_bridge)
	if not net:is_floating() and not m:get(net:name(), "_orig_ifname") then
		local ifcs = net:get_interfaces() or { net:get_interface() }
		if ifcs then
			local _, ifn
			local ifns = { }
			for _, ifn in ipairs(ifcs) do
				ifns[#ifns+1] = ifn:name()
			end
			if #ifns > 0 then
				m:set(net:name(), "_orig_ifname", table.concat(ifns, " "))
				m:set(net:name(), "_orig_bridge", tostring(net:is_bridge()))
			end
		end
	end
end


-- redirect to overview page if network does not exist anymore (e.g. after a revert)
if not net then
	luci.http.redirect(luci.dispatcher.build_url("admin/network/network"))
	return
end

-- protocol switch was requested, rebuild interface config and reload page
if m:formvalue("cbid.network.%s._switch" % net:name()) then
	-- get new protocol
	local ptype = m:formvalue("cbid.network.%s.proto" % net:name()) or "-"
	local proto = nw:get_protocol(ptype, net:name())
	if proto then
		-- backup default
		backup_ifnames()

		-- if current proto is not floating and target proto is not floating,
		-- then attempt to retain the ifnames
		--error(net:proto() .. " > " .. proto:proto())
		if not net:is_floating() and not proto:is_floating() then
			-- if old proto is a bridge and new proto not, then clip the
			-- interface list to the first ifname only
			if net:is_bridge() and proto:is_virtual() then
				local _, ifn
				local first = true
				for _, ifn in ipairs(net:get_interfaces() or { net:get_interface() }) do
					if first then
						first = false
					else
						net:del_interface(ifn)
					end
				end
				m:del(net:name(), "type")
			end

		-- if the current proto is floating, the target proto not floating,
		-- then attempt to restore ifnames from backup
		elseif net:is_floating() and not proto:is_floating() then
			-- if we have backup data, then re-add all orphaned interfaces
			-- from it and restore the bridge choice
			local br = (m:get(net:name(), "_orig_bridge") == "true")
			local ifn
			local ifns = { }
			for ifn in ut.imatch(m:get(net:name(), "_orig_ifname")) do
				ifn = nw:get_interface(ifn)
				if ifn and not ifn:get_network() then
					proto:add_interface(ifn)
					if not br then
						break
					end
				end
			end
			if br then
				m:set(net:name(), "type", "bridge")
			end

		-- in all other cases clear the ifnames
		else
			local _, ifc
			for _, ifc in ipairs(net:get_interfaces() or { net:get_interface() }) do
				net:del_interface(ifc)
			end
			m:del(net:name(), "type")
		end

		-- clear options
		local k, v
		for k, v in pairs(m:get(net:name())) do
			if k:sub(1,1) ~= "." and
			   k ~= "type" and
			   k ~= "ifname" and
			   k ~= "_orig_ifname" and
			   k ~= "_orig_bridge"
			then
				m:del(net:name(), k)
			end
		end

		-- set proto
		m:set(net:name(), "proto", proto:proto())
		m.uci:save("network")
		m.uci:save("wireless")

		-- reload page
		luci.http.redirect(luci.dispatcher.build_url("admin/wizard/wizard"))
		return
	end
end

-- dhcp setup was requested, create section and reload page
if m:formvalue("cbid.dhcp._enable._enable") then
	m.uci:section("dhcp", "dhcp", nil, {
		interface = "wan",
		start     = "100",
		limit     = "150",
		leasetime = "12h"
	})

	m.uci:save("dhcp")
	luci.http.redirect(luci.dispatcher.build_url("admin/wizard/wizard"))
	return
end

local ifc = net:get_interface()

st = s:option(DummyValue, "__status", translate("Status"))

local function set_status()
	-- if current network is empty, print a warning
	if not net:is_floating() and net:is_empty() then
		st.template = "cbi/dvalue"
		st.network  = nil
		st.value    = translate("There is no device assigned yet, please attach a network device in the \"Physical Settings\" tab")
	else
		st.template = "admin_network/iface_status"
		st.network  = "wan" 
		st.value    = nil
	end
end

m.on_init = set_status
m.on_after_save = set_status

p = s:option(ListValue, "proto", translate("Protocol"))
p.default = net:proto()

if not net:is_installed() then
	p_install = s:option(Button, "_install")
	p_install.title      = translate("Protocol support is not installed")
	p_install.inputtitle = translate("Install package %q" % net:opkg_package())
	p_install.inputstyle = "apply"
	p_install:depends("proto", net:proto())

	function p_install.write()
		return luci.http.redirect(
			luci.dispatcher.build_url("admin/system/packages") ..
			"?submit=1&install=%s" % net:opkg_package()
		)
	end
end

p_switch = s:option(Button, "_switch")
p_switch.title      = translate("Really switch protocol?")
p_switch.inputtitle = translate("Switch protocol")
p_switch.inputstyle = "apply"

local _, pr
for _, pr in ipairs(nw:get_protocols()) do
	p:value(pr:proto(), pr:get_i18n())
	if pr:proto() ~= net:proto() then
		p_switch:depends("proto", pr:proto())
	end
end

function p.write() end
function p.remove() end
function p.validate(self, value, section)
	if value == net:proto() then
		if not net:is_floating() and net:is_empty() then
			local ifn = ((br and (br:formvalue(section) == "bridge"))
				and ifname_multi:formvalue(section)
			     or ifname_single:formvalue(section))

			for ifn in ut.imatch(ifn) do
				return value
			end
			return nil, translate("The selected protocol needs a device assigned")
		end
	end
	return value
end

local form, ferr = loadfile(
	ut.libpath() .. "/model/cbi/wizard/proto_%s.lua" % net:proto()
)

if not form then
	s:option(DummyValue, "_error",
		translate("Missing protocol extension for proto %q" % net:proto())
	).value = ferr
else
	setfenv(form, getfenv(1))(m, s, net)
end


local _, field
for _, field in ipairs(s.children) do
	if field ~= st and field ~= p and field ~= p_install and field ~= p_switch then
		if next(field.deps) then
			local _, dep
			for _, dep in ipairs(field.deps) do
				dep.deps.proto = net:proto()
			end
		else
			field:depends("proto", net:proto())
		end
	end
end

l = Map("network") 

s = l:section(NamedSection, "lan",  "interface", translate("LAN"))                   
s.addremove = false
s.anonymous = false
s.optional = false

e = s:option(Value, "ipaddr", translate("<abbr title=\"Internet Protocol Version 4\">IPv4</abbr>-Address"))
e.default = "192.168.0.1"
e.rmempty = false
e.optional = true
e.datatype = "ip4addr"

e = s:option(Value, "netmask", translate("<abbr title=\"Internet Protocol Version 4\">IPv4</abbr>-Address")) 
e.default = "255.255.255.0"
e.rmempty = false
e.optional = true
e.datatype = "ip4addr"
e:value("255.255.255.0")
e:value("255.255.0.0")
e:value("255.0.0.0")

d = Map("dhcp")

s = d:section(NamedSection, "lan",  "dhcp", translate("DHCP"))
s.addremove = false
s.anonymous = false
s.optional = false

e = s:option(Value, "start", translate("Start"),translate("Lowest leased address as offset from the network address."))
e.default = "100"
e.rmempty = false
e.optional = true
e.datatype = "uinteger"

e = s:option(Value, "limit", translate("Limit"),translate("Maximum number of leased addresses."))
e.default = "100"
e.rmempty = false
e.optional = true
e.datatype = "uinteger"

w = Map("wireless")

local wnet = nw:get_wifinet("ra0.network1")
local wdev = wnet and wnet:get_device()

s = w:section(NamedSection, wnet.sid, "wifi-iface", translate("Wireless Settings"))
s.addremove = false
s.anonymous = false
s.optional = false

e = s:option(Value, "ssid", translate("SSID"))
e.default = "Kloudspot"
e.rmempty = false
e.optional = true

e = s:option(ListValue, "encryption", translate("Encryption"))
e.override_values = true
e.override_depends = true
e.default = "none"
e.rmempty = false
e.optional = true
e:value("none", "No Encryption")
e:value("psk", "WPA-PSK")
e:value("psk2", "WPA2-PSK")
e:value("psk-mixed", "WPA-PSK/WPA2-PSK Mixed Mode")

e = s:option(Value, "key", translate("Key"))
e:depends("encryption", "psk")
e:depends("encryption", "psk2")
e:depends("encryption", "psk+psk2")
e:depends("encryption", "psk-mixed")
e.datatype = "wpakey"
e.rmempty = true
e.password = true

return m, l, d, w

