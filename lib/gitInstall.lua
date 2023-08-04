local gitInstall = {}
local net = require("internet")
local s = require("serialization")
local ft = require("tableToFile")
local localVersionFile = "/etc/gitVersion.cfg"
local localLibInfo = "/etc/gitInstalledLibs.cfg"
local installLocation = "/usr"
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
    local destFile = assert(io.open(installLocation..dest, "w"))
    destFile:write(f)
    destFile:close()
end

function gitInstall:getRemoteLibs(url)
    self.opts = getWebTable(url)
end

function gitInstall:refreshRemoteLib()
    gitInstall:getRemoteLibs("https://raw.githubusercontent.com/izeek182/GT_Base_Manager/main/programs.cfg")
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

function gitInstall:getInstalledLibs()
    if(self.installedLibs == nil)then
        self.installedLibs = ft.load(localLibInfo)
    end
    if(self.installedLibs == nil)then
        self.installedLibs = {}
        ft.save(self.installedLibs,localLibInfo)
    end
    return self.installedLibs
end

function gitInstall:logVersion(fileName,version)
    if(self.locVer == nil)then
        self.locVer = ft.load(localVersionFile)
    end
    self.locVer[fileName] = version
end

function gitInstall:diskSync()
    if(self.locVer ~= nil)then
        ft.save(self.locVer,localVersionFile)
    end
    if(self.installedLibs ~= nil) then 
        ft.save(self.installedLibs,localLibInfo)
    end
    print("saving new versions to disk")
end


function gitInstall:install(name)
    self.installedLibs[name] = true;
    if (self.opts[name] ~= nil) then
        installQue[name] = true
        installQueCnt = installQueCnt + 1;
        local p = self.opts[name]
        local url = "https://"..self.opts.githubLink
        print("url:"..url)
        local cfg = getWebTable(url.."/"..p.installConfig)
        print("Checking depenancies:")
        for index, depenant in pairs(cfg.dependencies) do
            if(installQue[depenant] ~= true) then
                print("Installing depenancy:\""..depenant.."\"")
                gitInstall:install(depenant)
                print("depenacy Installed depenancy:\""..depenant.."\"")
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
        installQueCnt = installQueCnt - 1
        if installQueCnt == 0 then
            self:diskSync()
            installQue = {}
        end
    else
        print("module \"".. name .."\" not found")
    end
end

function gitInstall:updateLibs()
    print("Checking for updates")
    for libName,meh in ipairs(gitInstall:getInstalledLibs()) do
        -- gitInstall:checkVersion(libName)
        print("Checking for update on:"..libName)
        gitInstall:install(libName)
    end
end

local function init()
    gitInstall:getInstalledLibs()
    gitInstall:getVersion()
    gitInstall.opts = {}
    gitInstall:refreshRemoteLib()
end

init()

return gitInstall