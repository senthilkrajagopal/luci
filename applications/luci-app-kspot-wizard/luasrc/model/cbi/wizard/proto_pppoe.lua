-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local map, section, net = ...

local username, password, ac, service
local ipv6, defaultroute, metric, peerdns, dns,
      keepalive_failure, keepalive_interval, demand, mtu


username = section:option(Value, "username", translate("PAP/CHAP username"))


password = section:option(Value, "password", translate("PAP/CHAP password"))
password.password = true


ac = section:option(Value, "ac",
	translate("Access Concentrator"),
	translate("Leave empty to autodetect"))

ac.placeholder = translate("auto")


service = section:option(Value, "service",
	translate("Service Name"),
	translate("Leave empty to autodetect"))

service.placeholder = translate("auto")

