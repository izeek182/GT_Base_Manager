local RDT = require("netRDT")

local Logger = require("logUtil")
local log = Logger:new("rdt",LogLevel.info,LogLevel.trace,LogLevel.noLog)
log:clearLog()

local dest = "3ae67331-1f18-49ea-866b-e8bd3e02cb8f";
local port = 15;

local function clientRxMessage(data)
    log:Debug("clientMessage:",data)
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

