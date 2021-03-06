--[[  
LuCI - Lua Configuration Interface    
    
Copyright 2008 Steven Barth <steven@midlink.org>      
      
Licensed under the Apache License, Version 2.0 (the "License");     
you may not use this file except in compliance with the License.      
You may obtain a copy of the License at 
    
http://www.apache.org/licenses/LICENSE-2.0    
      
$Id$
]]--  
      
local uci = require "uci"     
local nw = require "luci.model.network"       
local ut = require "luci.util"
local x = uci.cursor()
      
nw.init()     
local net = nw:get_network("wan")     
       
function getMode()    
        local ntm = require "luci.model.network".init()
        local value = x:get("network", "mode")
        if value == "bridge" then
                return "bridge"
        elseif value == "cbridge" then
                return "cbridge"
        elseif value == "wrouter" then
                return "wrouter"
        else
                return "router"
        end
end   
    
function getWifiMode()  
	local ntm = require "luci.model.network".init() 
	local wifinet = ntm:get_wifinet("radio0.network1")  
	local value = x:get("wireless", wifinet:name(), "mode")       
	if value == "ap" then 
		return "Access Point" 
	elseif value == "sta" then     
		return "Client"     
	else  
		return "Other"
	end   
end   
      
local valmode = getMode()     
local valwifimode = getWifiMode()      
      
f = SimpleForm("wizard", translate("Wizard"),       
translate("Wizard for configuring the device."))    
    
s = f:section(SimpleSection)  
    
mode = s:option(ListValue, "mode", translate("Device Mode"))  
mode.datatype = "string"      
mode:value("router", "Router")      
mode:value("wrouter", "W-Router")     
mode:value("bridge", "AP Bridge")   
mode:value("cbridge", "Client Bridge")
      
function mode.cfgvalue()      
	return getMode()
end

function mode.write(self, section, data)    
    local ntm = require "luci.model.network".init()       
    local wifinet = ntm:get_wifinet("radio0.network1")    
    if data == "bridge" then
        local net = ntm:del_network("wan")
        local net = ntm:del_network("wan6")
        local net = ntm:del_network("lan")
	local net = ntm:del_network("wwan")
        x:set("network", "bridge", "interface")
        x:set("network", "bridge", "proto", "static")
        x:set("network", "bridge", "type", "bridge")
        x:set("network", "bridge", "ifname", "eth0.1 eth0.2")
        x:set("dhcp", "bridge", "ignore", "1")
        x:set("wireless", wifinet:name(), "network", "bridge")
        x:set("wireless", wifinet:name(), "ifname", "wlan0")
        x:set("wireless", wifinet:name(), "mode", "ap")
        x:set("wireless", wifinet:name(), "wmm", "1")
        x:set("wireless", wifinet:name(), "rekeyinteval", "0")
        x:set("wireless", wifinet:name(), "ssid", "kloudspot")
        x:set("wireless", wifinet:name(), "key", "kloudspot")
        x:set("wireless", wifinet:name(), "encryption", "psk2")
	x:set("network", "mode","bridge")
        luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
        ntm:commit("network")
        ntm:commit("wireless")
        x:save("dhcp")
        x:save("network")
        x:save("wireless")
        return
    elseif data == "cbridge" then
        local net = ntm:del_network("bridge")
        local net = ntm:del_network("wwan")
        luci.sys.call("env -i /etc/init.d/relayd enable >/dev/null 2>/dev/null")
        luci.sys.call("env -i /etc/init.d/relayd start >/dev/null 2>/dev/null")
        x:set("network", "lan", "interface")
        x:set("network", "lan", "proto", "static")
        x:set("network", "lan", "type", "bridge")
        x:set("network", "lan", "ifname", "eth0.1 eth0.2")
        x:set("network", "wwan", "interface")
        x:set("network", "wwan", "proto", "dhcp")
        x:set("network", "bridge", "interface")
        x:set("network", "bridge", "proto", "relay")
        x:set("network", "bridge", "network", "lan wwan")
        x:set("wireless", wifinet:name(), "network", "wwan")
        x:set("dhcp", "lan", "ignore", "1")
        x:set("dhcp", "wan", "ignore", "1")
        x:set("network", "mode","cbridge")
        luci.sys.call("env -i /etc/init.d/network restart >/dev/null 2>/dev/null")
        ntm:commit("network")
        ntm:commit("wireless")
        x:save("dhcp")
        x:save("network")
        x:save("wireless")
        return
    elseif data == "router" then
        local net = ntm:del_network("bridge")
	local net = ntm:del_network("wwan")
        x:set("network", "lan", "interface")
        x:set("network", "lan", "proto", "static")
        x:set("network", "lan", "type", "bridge")
        x:set("network", "lan", "ifname", "eth0.1")
        x:set("network", "wan", "interface")
        x:set("network", "wan", "proto", "dhcp")
        x:set("network", "wan", "ifname", "eth0.2")
        x:set("wireless", wifinet:name(), "network", "lan")
        x:set("wireless", wifinet:name(), "ifname", "wlan0")
        x:set("wireless", wifinet:name(), "mode", "ap")
        x:set("wireless", wifinet:name(), "wmm", "1")
        x:set("wireless", wifinet:name(), "rekeyinteval", "0")
        x:set("wireless", wifinet:name(), "ssid", "kloudspot")
        x:set("wireless", wifinet:name(), "key", "kloudspot")
        x:set("wireless", wifinet:name(), "encryption", "psk2")
        x:set("dhcp", "bridge", "ignore", "0")
	x:set("network", "mode","router")
        luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
        ntm:commit("network")
        ntm:commit("wireless")
        x:save("dhcp")
        x:save("network")
        x:save("wireless")
        return
    elseif data == "wrouter" then
        local net = ntm:del_network("bridge")
        x:set("network", "lan", "interface")
        x:set("network", "lan", "proto", "static")
        x:set("network", "lan", "type", "bridge")
        x:set("network", "lan", "ifname", "eth0.1 eth0.2")
        x:set("wireless", wifinet:name(), "network", "wan")
	x:set("network", "mode","wrouter")
        luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
        ntm:commit("network")
        ntm:commit("wireless")
        x:save("dhcp")
        x:save("network")
        x:save("wireless")
        return
    end   
end 
    
wifimode = s:option(DummyValue, "wifimode", translate("Wifi Mode"))   
--wifimode.class = "hidden"     
    
function wifimode.cfgvalue()  
    return getWifiMode()  
end

local bridge = "bridge"
local router = "router"
local cbridge = ""
local wrouter = ""
if valwifimode == "Client" then
	cbridge = "cbridge"
	wrouter = "wrouter"
end 

if valwifimode == "Access Point" then      
    join = s:option(Button, "join", translate("Scan & Add Wireless Network"))     
    join.template = "cbi/wireless_join"   
    join:depends("mode", "wrouter")     
    join:depends("mode", "cbridge")    
end
      
bridge_ipaddr = s:option(Value, "bridge_ipaddr", translate("Bridge IPv4 address"))      
bridge_ipaddr:depends("mode", bridge) 
bridge_ipaddr:depends("mode", cbridge) 
bridge_ipaddr.rmempty = true  
bridge_ipaddr.datatype = "ip4addr"    

function bridge_ipaddr.cfgvalue()   
    return x:get("network", "bridge", "ipaddr")   
end   

function bridge_ipaddr.write(self, section, data)     
    x:set("network", "bridge", "ipaddr", data)    
    return x:save("network")      
end    

function bridge_ipaddr.remove(self, section)
    x:delete("network", "bridge", "ipaddr")     
    return x:save("network")    
end   

bridge_netmask = s:option(Value, "bridge_netmask", translate("Bridge IPv4 netmask"))  
bridge_netmask:depends("mode", bridge) 
bridge_netmask:depends("mode", cbridge)
bridge_netmask.rmempty = true 
bridge_netmask.datatype = "ip4addr" 
bridge_netmask:value("255.255.255.0") 
bridge_netmask:value("255.255.0.0")   
bridge_netmask:value("255.0.0.0")     

function bridge_netmask.cfgvalue()    
    return x:get("network", "bridge", "netmask")  
end 

function bridge_netmask.write(self, section, data)    
    x:set("network", "bridge", "netmask", data)   
    return x:save("network")      
end

function bridge_netmask.remove(self, section) 
    x:delete("network", "bridge", "netmask")    
    return x:save("network")      
end   

bridge_gateway = s:option(Value, "bridge_gateway", translate("Bridge IPv4 gateway"))  
bridge_gateway.datatype = "ip4addr"     
bridge_gateway:depends("mode", bridge) 
bridge_gateway:depends("mode", cbridge) 
bridge_gateway.rmempty = true 

function bridge_gateway.cfgvalue()    
    return x:get("network", "bridge", "gateway")  
end   

function bridge_gateway.write(self, section, data)    
    x:set("network", "bridge", "gateway", data)   
    return x:save("network")      
end   

function bridge_gateway.remove(self, section)  
    x:delete("network", "bridge", "gateway")      
    return x:save("network")    
end 

proto = s:option(ListValue, "proto", translate("WAN Protocol")) 
proto.datatype = "string"   
proto:depends("mode", router) 
proto:depends("mode", wrouter)     
proto:value("dhcp", "DHCP Client")    
proto:value("static", "Static Address")       
proto:value("pppoe", "PPPoE")   

function proto.cfgvalue()     
    return x:get("network", "wan", "proto")       
end 

function proto.write(self, section, data)     
    x:set("network", "wan", "proto", data)
    return x:save("network")    
end     

hostname = s:option(Value, "hostname", translate("Hostname"))       
hostname:depends("proto", "dhcp")     
hostname.rmempty = true       
hostname.placeholder = luci.sys.hostname()    
hostname.datatype    = "hostname"     
--hostname.optional = true  

function hostname.cfgvalue()  
    return x:get("network", "wan", "hostname")    
end   

function hostname.write(self, section, data)  
    x:set("network", "wan", "hostname", data)      
    return x:save("network")      
end 

function hostname.remove(self, section)     
    x:delete("network", "wan", "hostname")
    return x:save("network")    
end   

wan_ipaddr = s:option(Value, "wan_ipaddr", translate("WAN IPv4 address"))   
wan_ipaddr:depends("proto", "static") 
wan_ipaddr.rmempty = true   
wan_ipaddr.datatype = "ip4addr"       
--wan_ipaddr.optional = true  

function wan_ipaddr.cfgvalue()  
    return x:get("network", "wan", "ipaddr")      
end   

function wan_ipaddr.write(self, section, data)      
    x:set("network", "wan", "ipaddr", data)       
    return x:save("network")      
end

function wan_ipaddr.remove(self, section)     
    x:delete("network", "wan", "ipaddr")
    return x:save("network")      
end   

wan_netmask = s:option(Value, "wan_netmask", translate("WAN IPv4 netmask"))   
wan_netmask:depends("proto", "static")  
wan_netmask.rmempty = true  
wan_netmask.datatype = "ip4addr"      
wan_netmask:value("255.255.255.0")    
wan_netmask:value("255.255.0.0")    
wan_netmask:value("255.0.0.0")
--wan_netmask.optional = true 

function wan_netmask.cfgvalue()       
    return x:get("network", "wan", "netmask")     
end   

function wan_netmask.write(self, section, data)       
    x:set("network", "wan", "netmask", data)      
    return x:save("network")       
end   

function wan_netmask.remove(self, section)  
    x:delete("network", "wan", "netmask") 
    return x:save("network")
end 

gateway = s:option(Value, "gateway", translate("WAN IPv4 gateway"))   
gateway.datatype = "ip4addr"  
gateway:depends("proto", "static")      
gateway.rmempty = true
--gateway.optional = true     

function gateway.cfgvalue() 
    return x:get("network", "wan", "gateway")     
end   

function gateway.write(self, section, data) 
    x:set("network", "wan", "gateway", data)
    return x:save("network")
end 

function gateway.remove(self, section)
    x:delete("network", "wan", "gateway") 
    return x:save("network")      
end 

broadcast = s:option(Value, "broadcast", translate("WAN IPv4 broadcast"))     
broadcast.datatype = "ip4addr"
broadcast:depends("proto", "static")  
broadcast.rmempty = true      
--broadcast.optional = true   

function broadcast.cfgvalue() 
    return x:get("network", "wan", "broadcast") 
end 

function broadcast.write(self, section, data) 
    x:set("network", "wan", "broadcast", data)  
    return x:save("network")      
end   

function broadcast.remove(self, section)      
    x:delete("network", "wan", "broadcast")     
    return x:save("network")      
end   

dns = s:option(DynamicList, "dns", translate("Use custom DNS servers")) 
dns.datatype = "ipaddr"       
dns.cast     = "string"       
dns:depends("proto", "static")      
dns.rmempty = true  
--dns.optional = true 

function dns.cfgvalue()       
    return x:get("network", "wan", "dns")       
end

function dns.write(self, section, data)       
    x:set("network", "wan", "dns", data)  
    return x:save("network")    
end   

function dns.remove(self, section)  
    x:delete("network", "wan", "dns")     
    return x:save("network")
end 


username = s:option(Value, "username", translate("PAP/CHAP username"))      
username:depends("proto", "pppoe")    
username.rmempty = true       

function username.cfgvalue()  
    return x:get("network", "username", "dns")    
end   

function username.write(self, section, data)  
    x:set("network", "wan", "username", data)     
    return x:save("network")       
end   

function username.remove(self, section)     
    x:delete("network", "wan", "username")
    return x:save("network")
end 

password = s:option(Value, "password", translate("PAP/CHAP password"))
password.password = true      
password:depends("proto", "pppoe")      
password.rmempty = true       

function password.cfgvalue()  
    return x:get("network", "wan", "password")  
end   

function password.write(self, section, data)  
    x:set("network", "wan", "password", data)   
    return x:save("network")
end     

function password.remove(self, section)       
    x:delete("network", "wan", "password")
    return x:save("network")      
end   

ac = s:option(Value, "ac", translate("Access Concentrator"), translate("Leave empty to autodetect"))
ac.placeholder = translate("auto")    
ac:depends("proto", "pppoe")
ac.rmempty = true     

function ac.cfgvalue()
    return x:get("network", "wan", "ac")   
end   

function ac.write(self, section, data)      
    x:set("network", "wan", "ac", data) 
    return x:save("network")    
end 

function ac.remove(self, section)     
    x:delete("network", "wan", "ac")    
    return x:save("network")      
end 

service = s:option(Value, "service", translate("Service Name"), translate("Leave empty to autodetect"))
service.placeholder = translate("auto")       
service:depends("proto", "pppoe")       
service.rmempty = true      

function service.cfgvalue() 
    return x:get("network", "wan", "service")   
end   

function service.write(self, section, data)    
    x:set("network", "wan", "service", data)       
    return x:save("network")
end

function service.remove(self, section)      
    x:delete("network", "wan", "service") 
    return x:save("network")      
end    
-------------       

nat = s:option(ListValue, "nat", translate("NAT"), translate("Enable NAT")) 
nat.default = "1"      
nat.widget = "radio"   
nat.orientation = "horizontal"      
nat:depends("mode", router) 
nat:depends("mode", wrouter)   
nat:value("0", translate("false"))     
nat:value("1", translate("true"))      

function nat.cfgvalue()
    return x:get("network", "nat")
end

function nat.write(self, section, data)
    x:set("network", "nat", data)
    if data == "0" then
                luci.sys.call("env -i /etc/init.d/firewall disable >/dev/null 2>/dev/null")
                luci.sys.call("env -i /etc/init.d/firewall stop >/dev/null 2>/dev/null")
    else
                luci.sys.call("env -i /etc/init.d/firewall enable >/dev/null 2>/dev/null")
                luci.sys.call("env -i /etc/init.d/firewall start >/dev/null 2>/dev/null")
    end
    return x:save("network")
end

------------- 

lan_ipaddr = s:option(Value, "lan_ipaddr", translate("LAN IPv4 address"))   
lan_ipaddr:depends("mode", router) 
lan_ipaddr:depends("mode", wrouter)  
lan_ipaddr.rmempty = true      
lan_ipaddr.datatype = "ip4addr"       

function lan_ipaddr.cfgvalue()      
    return x:get("network", "lan", "ipaddr")       
end     

function lan_ipaddr.write(self, section, data) 
    x:set("network", "lan", "ipaddr", data)     
    return x:save("network")    
end     

function lan_ipaddr.remove(self, section)     
--x:delete("network", "lan", "ipaddr") 
--return x:save("network")  
end   

lan_netmask = s:option(Value, "lan_netmask", translate("LAN IPv4 netmask"))    
lan_netmask:depends("mode", router) 
lan_netmask:depends("mode", wrouter)       
lan_netmask.rmempty = true      
lan_netmask.datatype = "ip4addr"
lan_netmask:value("255.255.255.0")  
lan_netmask:value("255.255.0.0")      
lan_netmask:value("255.0.0.0")      
--wan_netmask.optional = true 

function lan_netmask.cfgvalue()     
    return x:get("network", "lan", "netmask")      
end    

function lan_netmask.write(self, section, data)
    x:set("network", "lan", "netmask", data)    
    return x:save("network")       
end    

function lan_netmask.remove(self, section)  
--x:delete("network", "lan", "netmask")     
--return x:save("network")  
end 

function f.handle(self, state, data)
    return true   
end 

--s = f:section(SimpleSection, translate("DHCP"))      

dhcp_ignore = s:option(ListValue, "dhcp_ignore", translate("DHCP"), translate("Enable DHCP for this interface"))
dhcp_ignore.widget = "radio"  
dhcp_ignore.orientation = "horizontal"  
dhcp_ignore:depends("mode", router) 
dhcp_ignore:depends("mode", wrouter)       
dhcp_ignore:value("0", translate("true"))       
dhcp_ignore:value("1", translate("false"))  

function dhcp_ignore.cfgvalue() 
    return x:get("dhcp", "lan", "ignore") or "0"   
end

function dhcp_ignore.write(self, section, data)     
    x:set("dhcp", "lan", "ignore", data)    
    return x:save("dhcp")       
end   

dhcp_start = s:option(Value, "start", translate("DHCP Start offset"),translate("Lowest leased address as offset from the network address."))
dhcp_start:depends("dhcp_ignore", "0") 
dhcp_start.default = "100"  
dhcp_start.rmempty = false  
dhcp_start.optional = true      
dhcp_start.datatype = "uinteger"    

function dhcp_start.cfgvalue()      
    return x:get("dhcp", "lan", "start")
end 

function dhcp_start.write(self, section, data)      
    x:set("dhcp", "lan", "start", data) 
    return x:save("dhcp")       
end 

dhcp_limit = s:option(Value, "limit", translate("DHCP Max Leases"),translate("Maximum number of leased addresses."))
dhcp_limit:depends("dhcp_ignore", "0")
dhcp_limit.default = "100"  
dhcp_limit.rmempty = false  
dhcp_limit.optional = true  
dhcp_limit.datatype = "uinteger"    

function dhcp_limit.cfgvalue()      
    return x:get("dhcp", "lan", "limit")
end 

function dhcp_limit.write(self, section, data)      
    x:set("dhcp", "lan", "limit", data) 
    return x:save("dhcp")   
end    

return f
