-- Copyright 2011-2012 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local map, section, net = ...
local ifc = net:get_interface()

local hostname, accept_ra, send_rs
local bcast, defaultroute, peerdns, dns, metric, clientid, vendorclass


hostname = section:option(Value, "hostname",
	translate("Hostname to send when requesting DHCP"))

hostname.placeholder = luci.sys.hostname()
hostname.datatype    = "hostname"
