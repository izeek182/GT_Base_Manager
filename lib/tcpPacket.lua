
require("logUtils")
local serial = require("serialization")

local logID = _LogUtil.newLogger("TCP_Packet",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)

local tcpPacket = {
}

local function compileFlags(...)
    local sum = 0
    for index, value in ipairs({...}) do
        if(value) then
            sum = sum + (2^index)
        end
    end
end

local function getFlags(number)
    local maxFlag = 4
    local flags = {}
    for i = maxFlag, 1, -1 do
        local flagVal = (2^i)
        if number > flagVal then
            number = number - flagVal
            flags[i] = true
        else
            flags[i] = false
        end
    end
end

function tcpPacket.tcpPkt(synF,ackF,finF,srcPort,syn,ack,payload)
    local pkt = {}
    pkt.synF,pkt.ackF,pkt.finF =  synF,ackF,finF
    pkt.payload = payload
    pkt.srcPort = srcPort
    pkt.syn = syn
    pkt.ack = ack
    return pkt
end

function tcpPacket.syn(srcPort)
    return tcpPacket.tcpPkt(true,false,false,srcPort,0,0,nil)
end

function tcpPacket.synAck(srcPort,ack)
    return tcpPacket.tcpPkt(true,true,false,srcPort,0,ack,nil)
end

function tcpPacket.Ack(srcPort)
    return tcpPacket.tcpPkt(false,true,false,srcPort,1,1,nil)
end

function tcpPacket.fin(srcPort,seq,ack)
    return tcpPacket.tcpPkt(false,true,true,srcPort,seq,ack,nil)
end

function tcpPacket.std(srcPort,seq,ack,payload)
    tcpPacket.tcpPkt(false,true,false,srcPort,seq,ack,payload)
end

function tcpPacket.toCompact(pkt)
    local flag = compileFlags(pkt.synF,pkt.ackF,pkt.finF)
    local header = {pkt.srcPort,flag,pkt.seq,pkt.ack}
    local pktStr = {header,pkt.payload}
    return pktStr
end

function tcpPacket.fromCompact(pktStr)
    local header , payload = table.unpack(pktStr)
    local srcPort,flag,seq,ack = table.unpack(header)
    return tcpPacket.tcpPkt(getFlags(flag),srcPort,seq,ack,payload)
end

return tcpPacket