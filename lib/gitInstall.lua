local gitInstall = {}
local net = require("internet")
local s = require("serialization")
local tf = require("tableToFile")
gitInstall.ProgramsTable = {}



local function getWebTable(url)
    local a = net.request(url)
    a.read()
    local file = a.read()
    return s.unserialize(file)
end

local function getWebFile(url,location)
    local a = net.request(url)
    a.read()
    local file = a.read()
    local tableFile = assert(io.open(location, "w"))
    tableFile:write(file)
    tableFile:close()
end

function gitInstall.getOptions(url)
    gitInstall.ProgramsTable = getWebTable(url)
end

function gitInstall.install(name)
    gitInstall.getOptions("https://raw.githubusercontent.com/izeek182/GT_Base_Manager/main/programs.cfg")
    if (gitInstall.ProgramsTable[name] ~= nil) then 
        local p = gitInstall.ProgramsTable[name]
        local url = "https://"..gitInstall.ProgramsTable.githubLink
        local cfg = getWebTable(url..p.installConfig)
        for index, file in pairs(cfg.bin) do
            getWebFile(url..file,"bin/"..file)
        end
        for index, file in pairs(cfg.lib) do
            getWebFile(url..file,"lib/"..file)
        end
    end
end