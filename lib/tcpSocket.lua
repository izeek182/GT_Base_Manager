require("logUtils")
local dq = require("dataQue")
local serial = require("serialization")
local logID = _LogUtil.newLogger("TCP_Socket",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)
local SocketTypes = {
    listener = 1,
    synSent  = 2,
    synReci  = 3,
    active   = 4,
    closing  = 5
}

local tcpSocket = {
}

local function PacketoOnListener(skt,pkt)

end

local function PacketoOnActive(skt,pkt)

end

local function PacketoOnSyn(skt,pkt)

end

local function PacketoOnClosing(skt,pkt)

end


local function newSocket(socketType,newclientCB,msgCB,localPort,remoteAddr,remotePort)
    local skt = {
        socketType     = socketType,
        localPort      = localPort,
        remoteAddr     = remoteAddr,
        remotePort     = remotePort,
        msgCB          = msgCB,
        pktNum         = 0,
        ackNum         = 0,
        LastTx         = 0,
        LastRx         = 0,
        dataQue        = dq.DataQue(_NetDefs.rdtConst.bufferSize),
        pktRxBuf       = {},
    }
end

function tcpSocket.newListener(newclientcb,msgCB,localPort)
    return newSocket(SocketTypes.listener,newclientcb,localPort,nil,nil)
end

function tcpSocket.newPacket(socket,packet)
    if socket.socketType == SocketTypes.listener then
        
    end
    
end
return tcpSocket