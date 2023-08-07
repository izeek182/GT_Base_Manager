if (TCP == nil) then
    TCP = {
    }

    if (_LogUtil == nil) then
        require("logUtils")
    end
    local que = require("que")
    local tcpPkt = require("tcpPacket.lua")
    require("netDefs")
    require("netUtils")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")

    local logID = _LogUtil.newLogger("netRDT", _LogLevel.error, _LogLevel.trace, _LogLevel.noLog)


    local _NetTCP = {
        time = 0,
        maxTime = 100,
        portTypes = {}, --{<portNumber>,<PortType RDT|Listen>}
        Sockets = {},   --{<LocalportNumber>:{
        --        callback:<Callback>,
        --        pktNum:<packetcount>,
        --        ackNum:<LastPacket>,
        --        LastTx:<timestamp>,
        --        LastRx:<timestamp>,
        --        pktQue:[pktQue],
        --        winOffset:
        --        dupAck
        --        pktRxBuf:{}}}}openSocket
        newMessagecb = {}, -- {<portNumber>:<callback>}
        newClientcb = {},  -- {<portNumber>:<callback>}
    }

    local function timeSince(someTime)
        if (someTime < _NetTCP.time) then
            return _NetTCP.time - someTime;
        else
            return _NetTCP.time + (_NetTCP.maxTime - someTime);
        end
    end
end
return TCP
