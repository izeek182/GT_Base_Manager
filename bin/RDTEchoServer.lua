local RDT = require("netRDT")

local Logger,LogLevel = require("logUtil")
local log = Logger:new("rdtDebug",LogLevel.info,LogLevel.trace,LogLevel.noLog)

local port = 15;

local clients = {}


local function serverRxMessage(skt,...)
    log:Info("serverMessage:",...)
    -- for key, value in pairs(arg) do
    --     print(" "..key..":"..value)
    -- end
    RDT.send(skt,...)
end

local function newClient(skt)
    clients[skt.remoteAddress] = skt
    return function (...)
        serverRxMessage(skt,...)
    end
end


log:Info("Opening Listening Socket On ",_NetUtil.HostName,":",port)
local serverSkt = RDT.listen(port,newClient,serverRxMessage)

while true do
    os.sleep(10)
end

