Interface = require("Modem")

local Tunnel = {}

Tunnel.portStatus = Interface:new()


function Interface:bringUp()
    if self.type == "tunnel" then
        self.status = true
        local ARPsignal = self:open(_NetDefs.portEnum.arp)
        self:sendARPRequest()
    end
end

--Sends message over interface to given IP and port
function Tunnel:sendMAC(mac, port, ...)
    error("abstract Function not implmented")
end

--Broadcasts message over interface to any listening machines
function Tunnel:broadcast(port, ...)
    error("abstract Function not implmented")
end

-- Opens given port on interface with callback on new messages
-- Returns signal to listen on for messages on this port
function Tunnel:open(port)
    error("abstract Function not implmented")
end

-- Closes given port on interface and removes any callback
function Tunnel:close(port)
    error("abstract Function not implmented")
end

-- returns boolean indicating if port is open
function Tunnel:getPortStatus()
    error("abstract Function not implmented")
end

-- return if interface is wireless
function Tunnel:isWireless()
    return true
end
return Tunnel