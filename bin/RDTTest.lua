local RDT = require("netRDT")

require("logUtils")
local logID = _LogUtil.newLogger("rdtDebug",_LogLevel.trace,_LogLevel.trace,_LogLevel.noLog)

local dest = "d302a6b6-1453-4753-9ef4-7fcde060ff50";
local port = 15;

local function clientRxMessage(skt,...)
    _LogUtil.debug(logID,"clientMessage:",...)
    print("clientMessage:")
    for key, value in pairs(arg) do
        print(" "..key..":"..value)
    end
end


local clientSkt = RDT.openSocket(dest,port,clientRxMessage)

local function txMessage(message)
    RDT.send(clientSkt,message)
end

txMessage("test1")

os.sleep(30)

RDT.closeSocket(clientSkt)

