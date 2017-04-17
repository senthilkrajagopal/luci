-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local map, section, net = ...

local ipaddr, netmask, gateway, broadcast, dns

ipaddr = section:option(Value, "ipaddr", translate("IPv4 address"))
ipaddr.datatype = "ip4addr"


netmask = section:option(Value, "netmask",
	translate("IPv4 netmask"))

netmask.datatype = "ip4addr"
netmask:value("255.255.255.0")
netmask:value("255.255.0.0")
netmask:value("255.0.0.0")


gateway = section:option(Value, "gateway", translate("IPv4 gateway"))
gateway.datatype = "ip4addr"


broadcast = section:option(Value, "broadcast", translate("IPv4 broadcast"))
broadcast.datatype = "ip4addr"


dns = section:option(DynamicList, "dns",
	translate("Use custom DNS servers"))

dns.datatype = "ipaddr"
dns.cast     = "string"


