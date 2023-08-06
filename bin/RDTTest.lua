local RDT = require("netRDT")

require("logUtils")
local logID = _LogUtil.newLogger("rdtDebug",_LogLevel.trace,_LogLevel.trace,_LogLevel.noLog)

local dest = "3ae67331-1f18-49ea-866b-e8bd3e02cb8f";
local port = 15;

local function clientRxMessage(skt,...)
    _LogUtil.debug(logID,"clientMessage:",...)
    print("clientMessage:")
    for key, value in pairs({...}) do
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

