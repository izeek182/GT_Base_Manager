local Interface = {status = false}
    
function Interface:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Interface:sendARPRequest()
    self:broadcast(_NetDefs.portEnum.arp)
end

-- Returns interface status
function Interface:status()
    return self.status
end

function Interface:bringUp()
    if self.type == "modem" then
        self.status = true
        local ARPsignal = self:open(_NetDefs.portEnum.arp)
        self:sendARPRequest()
    end
end


function Interface:remoteData(localAddress, remoteAddress, port, distance, l1Header, data)
end

--Sends message over interface to given IP and port
function Interface:sendMAC(mac, port, ...)
    error("abstract Function not implmented")
end

--Broadcasts message over interface to any listening machines
function Interface:broadcast(port, ...)
    error("abstract Function not implmented")
end

-- Opens given port on interface with callback on new messages
-- Returns signal to listen on for messages on this port
function Interface:open(port)
    error("abstract Function not implmented")
end

-- Closes given port on interface and removes any callback
function Interface:close(port)
    error("abstract Function not implmented")
end

-- returns boolean indicating if port is open
function Interface:getPortStatus()
    error("abstract Function not implmented")
end

-- return if interface is wireless
function Interface:isWireless()
    error("abstract Function not implmented")
end

return Interface