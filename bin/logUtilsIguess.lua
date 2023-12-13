local serial = require("serialization")
local fs = require("filesystem")
local io = require("io")

local function append(file,table)
    local file = io.open(file,"a")
    if not (file == nil) then
        file:write(serial.serialize(table))
        file:close()
    end
end

---@type ME_Upgrade
local me = require("upgrade_me")

local file = "me_Tables"
append(file,me.type)
append(file,me.allItems())
append(file,me.getCpus())
