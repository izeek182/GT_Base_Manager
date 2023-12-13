local serial = require("serialization")
---@alias hostname string
---@alias mac string

---@type number 
local _entryTTL = 60*6
---@class DNSEntry
---@field mac mac
---@field hostname hostname
---@field expire number
---@field interface integer
---@field distance integer

---makes new hostEntry
---@param mac mac
---@param hostname hostname
---@param interface integer
local function NewEntry(mac,hostname,interface,distance)
    return {mac=mac,ip=hostname,expire=os.time() + _entryTTL,interface=interface,distance=distance}
end

---@class DNSTable
---@field private macTb table<mac,DNSEntry>
---@field private hostTb table<hostname,DNSEntry>
local DNSTable = { macTb = {}, hostTb = {} }

---Trims Exspired host entries from host table
function DNSTable:trimTable()
    for hostname, entry in pairs(self.hostTb) do
        if entry.expire < os.time() then
            self.hostTb[hostname] = nil
            self.macTb[entry.mac] = nil
        end
    end
end


---Adds the given host data to the table
---@param mac mac
---@param hostname hostname
---@param interface integer
function DNSTable:addEntry(mac,hostname,interface)
    local entry = NewEntry(mac,hostname,interface)
    self.macTb[mac] = entry
    self.hostTb[hostname] = entry
end

---Creates new hostTable
---@return DNSTable
function DNSTable:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---get the IP of a given address
---@param mac mac
---@return hostname
function DNSTable:getHost(mac)
    return self.macTb[mac].hostname
end

---Gets the interface number for the given IP
---@param hostname hostname
---@return integer
function DNSTable:getIF(hostname)
    return self.hostTb[hostname].interface
end

---Gets the Mac address of the given IP
---@param hostname hostname
---@return string
function DNSTable:getMAC(hostname)
    return self.hostTb[hostname].mac
end

---Gets the Mac address of the given IP
---@param hostname hostname
---@return string
function DNSTable:getShortestPath(hostname)
    return self.hostTb[hostname].mac
end

---Gets A serial representation of the table Excluding the given interface
---@param interface integer|nil
function DNSTable:GetSerial(interface)
    local serialTable = {}
    for host, entry in pairs(self.hostTb) do
        if not entry.interface == interface then
            table.insert(serialTable,{host,entry.mac,entry.distance})
        end
    end
    return serial.serialize(serialTable)
end

return DNSTable