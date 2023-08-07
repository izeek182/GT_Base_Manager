local RDT = require("netRDT")

require("logUtils")
local logID = _LogUtil.newLogger("rdtDebug",_LogLevel.info,_LogLevel.trace,_LogLevel.noLog)
_LogUtil.clearAllFiles()

local port = 15;

local clients = {}


local function serverRxMessage(skt,...)
    _LogUtil.info(logID,"serverMessage:",...)
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


_LogUtil.info(logID,"Opening Listening Socket On ",_NetUtil.HostName,":",port)
local serverSkt = RDT.listen(port,newClient,serverRxMessage)

while true do
    os.sleep(10)
end

