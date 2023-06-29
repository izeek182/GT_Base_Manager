local RDT = require("netRDT")

local dest = "Dest";
local portA = 15;
local portB = 20;

local client = 1;

local clients = {}


local function newClient(skt)
    clients[skt.remoteAddress] = skt
end

local function serverRxMessage(skt,...)
    print("serverMessage:")
    for key, value in pairs(arg) do
        print(" "..key..":"..value)
    end
end

local function clientRxMessage(skt,...)
    print("clientMessage:")
    for key, value in pairs(arg) do
        print(" "..key..":"..value)
    end
end


local serverSkt = RDT.listen(portA,newClient,serverRxMessage)
local clientSkt = RDT.openSocket(dest,portA,clientRxMessage)

local function txMessage(message)
    RDT.send(clientSkt,message)
end


txMessage("test")

