local RDT = require("netRDT")

require("logUtils")
local logID = _LogUtil.newLogger("rdtDebug",_LogLevel.debug,_LogLevel.trace,_LogLevel.noLog)
_LogUtil.clearAllFiles()

local dest = "3ae67331-1f18-49ea-866b-e8bd3e02cb8f";
local port = 15;

local function clientRxMessage(data)
    _LogUtil.debug(logID,"clientMessage:",data)
end


local clientSkt = RDT.openSocket(dest,port,clientRxMessage)

local function txMessage(message)
    RDT.send(clientSkt,message)
end

for i = 1, 25, 1 do
    txMessage("test msg:"..i)
end

os.sleep(300)

RDT.closeSocket(clientSkt)

