local gitInstall = {}
local net = require("internet")
local s = require("serialization")
local ft = require("tableToFile")
local localVersionFile = "/etc/gitVersion.cfg"
local installQue = {} 
local installQueCnt = 0
local function downloadPage(url)
    local a = net.request(url)
    local s = ""
    for c in a do
        s = s .. c
    end
    return s
end

local function getWebTable(url)
    local f = downloadPage(url)
    return s.unserialize(f)
end

local function getWebFile(url,dest)
    local f = downloadPage(url)
    local tableFile = assert(io.open(dest, "w"))
    tableFile:write(f)
    tableFile:close()
end

function gitInstall:getVersion(fileName)
    if(self.locVer == nil)then
        self.locVer = ft.load(localVersionFile)
    end
    if(self.locVer[fileName] ~= nil)then
        return self.locVer[fileName]
    else
        return 0
    end
end

function gitInstall:logVersion(fileName,version)
    if(self.locVer == nil)then
        self.locVer = ft.load(localVersionFile)
    end
    self.locVer[fileName] = version
end

function gitInstall:diskSync()
    if(self.locVer == nil)then
        return
    else
        print("saving new versions to disk")
        ft.save(self.locVer,localVersionFile)
    end
end

function gitInstall:getOptions(url)
    self.opts = getWebTable(url)
end

function gitInstall:install(name)
    if (self.opts[name] ~= nil) then 
        installQue[name] = true
        installQueCnt = installQueCnt + 1;
        local p = self.opts[name]
        local url = "https://"..self.opts.githubLink
        print("retiving config file from "..url..p.installConfig)
        local cfg = getWebTable(url.."/"..p.installConfig)

        print("Checking depenancys:")
        for index, depenant in pairs(cfg.files) do
            if(installQue[depenant] ~= true) then
                gitInstall:install(depenant)
            end
        end

        for index, file in pairs(cfg.files) do
            local v = cfg.fileVersion[file]
            if (self:getVersion(file) < v) then
                print("\"" .. file .. "\" is out of date, updating to V"..v)
                getWebFile(url..file,file)
                self:logVersion(file,v)
            else 
                print("\"" .. file .. "\" up to date skipping")
            end
        end
        installQue[name] = nil
        installQueCnt = installQueCnt - 1
        if installQueCnt == 0 then
            self:diskSync()
        end
    else
        print("module not found")
    end
end

local function init()
    gitInstall:getVersion()
    gitInstall.opts = {}
    gitInstall:getOptions("https://raw.githubusercontent.com/izeek182/GT_Base_Manager/main/programs.cfg")
end

init()

return gitInstall