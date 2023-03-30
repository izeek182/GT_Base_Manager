--Documentation:
--
--load(string: path)
--  Returns the table stored in given path.
--save(table, string: path)
--  Saves the table in a file located in path
--

local MaxMessageSize = 8192
local FONport = 2563
local serialization = require("serialization")
local fileOverNet = {}
local components = require("components")
local net = components.network

function fileOverNet.send(fileName,client)
  --returns a table stored in a file.
  local tableFile = assert(io.open(fileName))


  return serialization.unserialize(tableFile:read("*all"))
end

function fileOverNet.listen(fileName)
  --saves a table to a file
  local tableFile = assert(io.open(fileName, "w"))
  tableFile:write(serialization.serialize(table))
  tableFile:close()
end

return tableToFile