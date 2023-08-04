local RDT = require("netRDT")

require("logUtils")
local logID = _LogUtil.newLogger("rdtDebug",_LogLevel.trace,_LogLevel.trace,_LogLevel.noLog)

local port = 15;

local clients = {}

local function newClient(skt)
    clients[skt.remoteAddress] = skt
end

local function serverRxMessage(skt,...)
    _LogUtil.info(logID,"serverMessage:",...)
    -- for key, value in pairs(arg) do
    --     print(" "..key..":"..value)
    -- end
    RDT.send(skt,...)
end

_LogUtil.info(logID,"Opening Listening Socket On ",_NetUtil.HostName,":",port)
local serverSkt = RDT.listen(port,newClient,serverRxMessage)

while true do
    os.sleep(10)
end
