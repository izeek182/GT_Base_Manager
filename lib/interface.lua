---@module "components"
local routing = require("routing")
---@class Interface
---@field protected status boolean the status of the interface `true` if up
---@field send fun(if:Interface,mac:string, port:integer, ...:any):boolean Sends 
---@field remoteData fun(if:Interface,localAddress:string, remoteAddress:string, port:number, distance:number, l1Header:string, data):boolean
---@field broadcast fun(if:Interface,port:number, ...):boolean
---@field open fun(if:Interface,port:number):boolean
---@field close fun(if:Interface,port:number):boolean
---@field getPortStatus fun(if:Interface,port:number):boolean
---@field isWireless fun(if:Interface):boolean
local Interface = {status = false}

---@type integer The number of open interfaces
local ifCount = 0

---Applies the Interface metaTable to Object
---@param o any
---@return any
function Interface:extend(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Returns the status of this interface
---@return boolean
function Interface:getStatus()
    return self.status
end

---Brings up this interface wraping the given modem
function Interface:bringUp()
        self.status = true
end

---@class ModemIF:Interface
---@field protected IF Modem the Relevant component interface
local ModemIF = Interface:extend()


function ModemIF:send(mac,port,...)
    return self.IF.send(mac,port,...)
end

function ModemIF:remoteData(localAddress, remoteAddress, port, distance, l1Header, data)
    return false
end

function ModemIF:broadcast(port, ...)
    return self.IF.broadcast(port,...)
end

function ModemIF:open(port)
    return self.IF.open(port)
end

function ModemIF:close(port)
    return self.IF.close(port)
end

function ModemIF:getPortStatus(port)
    return self.IF.isOpen(port)
end

function ModemIF:isWireless()
    return self.IF.isWireless()
end

---@class TunnelIF:Interface
---@field protected IF Tunnel the Relevant component interface
---@field protected ports table<integer,boolean>
local TunnelIF = Interface:extend()

function TunnelIF:send(_,port,...)
    return self.IF.send(port,...)
end

function TunnelIF:remoteData(localAddress, remoteAddress, port, distance,port, l1Header, data)
    return false
end

function TunnelIF:broadcast(port, ...)
    return self.IF.send(port,...)
end

function TunnelIF:open(port)
    self.ports[port] = true
    return self.ports[port]
end

function TunnelIF:close(port)
    self.ports[port] = false
    return self.ports[port]
end

function TunnelIF:getPortStatus(port)
    return self.ports[port]
end

function TunnelIF:isWireless()
    return true
end



---Creates new interface around a given modem
---@param modem Modem
---@return Interface
function Interface:new(modem)
    local o = {
        IF = modem
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return Interface