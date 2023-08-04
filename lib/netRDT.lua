if (RDT == nil) then
    RDT = {
    }

    if(_LogUtil == nil) then
        require("logUtils")
    end

    require("netDefs")
    require("netUtils")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")

    local logID = _LogUtil.newLogger("netRDT",_LogLevel.error,_LogLevel.trace,_LogLevel.error)

    local _RdtMode = {
        syn1      = 1,
        syn2      = 2,
        hb        = 3,
        data      = 4,
        listening = 5,
        close     = 9,
    }
    
    local __windowSize = 16
    local __serviceInterval = 0.5
    local __bufferSize = (__windowSize) * 2
    local __MaxInFlight = 2

    local _NetRDT = {
        time = 0,
        maxTime = 100,
        portTypes = {}, --{<portNumber>,<PortType RDT|Listen>}
        Sockets = {},   --{<LocalportNumber>:{
        --        callback:<Callback>,
        --        pktNum:<packetcount>,
        --        ackNum:<LastPacket>,
        --        LastTx:<timestamp>,
        --        LastRx:<timestamp>,
        --        dataQue:[pktQue],
        --        lenQue:<length of que>,
        --        pktsInFlight:
        --        pktInFlight:<packet in flight> }}}openSocket
        newMessagecb = {}, -- {<portNumber>:<callback>}
        newClientcb = {}, -- {<portNumber>:<callback>}
    }

    local function timeSince(someTime)
        if (someTime < _NetRDT.time) then
            return _NetRDT.time - someTime;
        else
            return _NetRDT.time + (_NetRDT.maxTime - someTime);
        end
    end

    local function openSocket(port, remotePort, remoteHost, callback)
        _LogUtil.info(logID,"Opening RDT socket on:",port," to ",remoteHost,":",remotePort)
        _NetRDT.portTypes[port] = _RdtMode.data
        _NetUtil.open(port, callback)
        local socket            = {};
        socket.remoteHost       = remoteHost
        socket.remotePort       = remotePort
        socket.callback         = callback
        socket.pktNum           = 1
        socket.ackNum           = 1
        socket.LastTx           = _NetRDT.time
        socket.LastRx           = _NetRDT.time
        socket.pktQue           = {}
        socket.lenQue           = 0
        socket.pktInFlight      = 0
        _NetRDT.Sockets[port]   = socket
    end

    local function getFreePort()
        for i = 1, 100, 1 do
            local rand = math.random(_NetDefs.portEnum.RDT_start, _NetDefs.portEnum.RDT_end)
            if (not _NetUtil.checkPortOpen(rand)) then
                return rand
            end
        end
        return -1
    end

    local function packHeader(srcPort, pktNum, ackNum, RDT_mode)
        local header = { srcPort, pktNum, ackNum, RDT_mode }
        return serial.serialize(header)
    end

    local function unpackHeader(header)
        local header = serial.unserialize(header)
        return table.unpack(header)
    end

    local function unpackData(dataStr)
        local data = serial.unserialize(dataStr)
        return table.unpack(data)
    end

    local function packData(...)
        return serial.serialize({...})
    end

    local function sendSocket(localPort, RdtMode, ...)
        _LogUtil.info(logID,"Sending on:",localPort," -> ",...)
        _NetRDT.Sockets[localPort].LastTx = _NetRDT.time
        _NetUtil.send(
            _NetRDT.Sockets[localPort].remoteHost,
            _NetRDT.Sockets[localPort].remotePort,
            packHeader(
                localPort,
                _NetRDT.Sockets[localPort].pktNum,
                _NetRDT.Sockets[localPort].ackNum,
                RdtMode
            ),
            packData(...)
            )
    end

    local function closeSocket(port,graceful)
        _LogUtil.info(logID,"closing RDT port:",port)
        if graceful then
            sendSocket(port,_RdtMode.close)
        end
        _NetUtil.close(port)
        _NetRDT.portTypes[port] = nil
        _NetRDT.Sockets[port] = nil
    end

    local function expectedPacket(port, pktNum)
        return _NetRDT.Sockets[port].ackNum == pktNum
    end

    local function ackDistance(recivedAck, currentPktNum)
        if(recivedAck > currentPktNum) then
            return recivedAck - currentPktNum
        end
        return (__bufferSize + recivedAck) - currentPktNum
    end

    local function calcPos(currentPktNum, dist)
        return (currentPktNum + dist) % __bufferSize
    end

    -- Recived an ack for a packed dont resend that packet
    local function registerAckPacket(ackNum, port)
        local ackDist = ackDistance(ackNum, _NetRDT.Sockets[port].pktNum)
        _LogUtil.trace(logID,"Recived packet with ack:",ackNum," on port:",port," distance from last ack:",ackDist)
        while ackDist < __windowSize and ackDist > 0 do
            _NetRDT.Sockets[port].pktInFlight =- 1
            _NetRDT.Sockets[port].lenQue =- 1
            _NetRDT.Sockets[port].pktQue[_NetRDT.Sockets[port].pktNum] = nil
            if _NetRDT.Sockets[port].pktNum == __bufferSize then
                _NetRDT.Sockets[port].pktNum = 1                
            else
                _NetRDT.Sockets[port].pktNum = _NetRDT.Sockets[port].pktNum + 1
            end
            ackDist = ackDistance(ackNum, _NetRDT.Sockets[port].pktNum)
        end
    end

    local function ackPacket(port, pktNum)
        _NetRDT.Sockets[port].ackNum = pktNum
        -- The the next send packet(HB or data with deliver this ack no need to press the issue)
    end

    local function passOnData(port,...)
        _NetRDT.Sockets[port].callback(...)
    end

    local function processRdtPacket(remoteAddress, port, RDT_header, ...)
        local srcPort, pktNum, ackNum, RDT_mode = unpackHeader(RDT_header)
        registerAckPacket(ackNum, port)
        if (expectedPacket(port, pktNum)) then
            ackPacket(port, pktNum)
            passOnData(port, ...)
        end
    end

    local function newSocket(localPortIn,remoteAddressIn,remotePortIn)
        return {localPort=localPortIn,remoteAddress=remoteAddressIn,remotePort=remotePortIn}
    end
    
    local function netProcessing(eventName, localAddress, remoteAddress, port, distance, --l1
                                 RDT_header,                                             -- RDT_Header
                                 data,
                                 ...)                                                    -- Next Levels
        local srcPort, pktNum, ackNum, RDT_mode  = unpackHeader(RDT_header) 
        if (RDT_mode == _RdtMode.data) then
            _LogUtil.info(logID,"Received data on:",port," -> ",...)
            processRdtPacket(remoteAddress, port, pktNum, ackNum, table.unpack({...}))
        elseif (RDT_mode == _RdtMode.syn1) then
            _LogUtil.info(logID,"Received syn1 on:",port," -> ",...)
            if (_NetRDT.portTypes[port] == _RdtMode.listening) then
                local newLocalPort = getFreePort()
                openSocket(newLocalPort,srcPort, remoteAddress, _NetRDT.safeNetProcessing)
                sendSocket(newLocalPort, _RdtMode.syn2,port)
                _NetRDT.newClientcb[port](newSocket(newLocalPort,remoteAddress,srcPort))
            end
        elseif (RDT_mode == _RdtMode.syn2) then
            _LogUtil.info(logID,"Received syn2 on:",port," -> ",...)
            if (_NetRDT.portTypes[port] == _RdtMode.syn1) then
                openSocket(port,srcPort, remoteAddress, _NetRDT.safeNetProcessing)
                event.push(_NetDefs.events.syncResponse,  port, remoteAddress, srcPort)
            end
        elseif (RDT_mode == _RdtMode.hb) then
            _LogUtil.info(logID,"Received Heart Beat on:",port," -> ",...)
            if (_NetRDT.portTypes[port] == _RdtMode.data) then
                _NetRDT.Sockets[port].LastRx = _NetRDT.time
            end
        elseif (RDT_mode == _RdtMode.close) then
            _LogUtil.info(logID,"port:",port, "Closed by remote host"," -> ",...)
            if _NetRDT.portTypes[port] == _RdtMode.data then
                closeSocket(port,false)
            end
        end
end

    function _NetRDT.safeNetProcessing(...)
        return _LogUtil.logFailures(logID,netProcessing,...)
    end

    local function sendSyn(remoteHost,remotePort,localPort, RdtMode)
        _NetUtil.open(localPort, _NetRDT.safeNetProcessing)
        _NetUtil.send(
            remoteHost,
            remotePort,
            packHeader(
                localPort,
                0,
                0,
                _RdtMode.syn1
            )
        )
    end

    local function enqueue(port, packedData)
        if(_NetRDT.Sockets[port].lenQue==__bufferSize) then
            return
        end
        local bufI = calcPos(_NetRDT.Sockets[port].pktNum,_NetRDT.Sockets[port].lenQue)
        _NetRDT.Sockets[port].pktQue[bufI] = packedData
        _NetRDT.Sockets[port].lenQue = _NetRDT.Sockets[port].lenQue + 1
    end

    local function advanceTimer()
        _NetRDT.time = _NetRDT.time + 1
        if (_NetRDT.time > _NetRDT.maxTime) then
            _NetRDT.time = 0
        end
    end

    local function resendQue(localPort)
        _NetRDT.Sockets[localPort].pktInFlight = 0
    end

    local function handleTimouts()
        for localPort, socket in pairs(_NetRDT.Sockets) do
            local LastTx = socket.LastTx
            local LastRx = socket.LastRx
            if (socket.pktInFlight > 0 and timeSince(LastTx) > _NetDefs.timeOut.resend) then
                resendQue(localPort)
            elseif (socket.pktInFlight == 0 and timeSince(LastTx) > _NetDefs.timeOut.sendHB and _NetRDT.portTypes[localPort] == _RdtMode.data) then
                sendSocket(localPort, _RdtMode.hb)
            end

            if (timeSince(LastRx) > _NetDefs.timeOut.cold) then
                _LogUtil.error(logID,"Socket Has timed out on port:",localPort)
                closeSocket(localPort,false) 
            end
        end
    end

    local function sendNextPacket(localPort)
        sendSocket(localPort,_RdtMode.data,)
    end

    local function processQueue()
        for localPort, socket in pairs(_NetRDT.Sockets) do
            if (socket.pktInFlight < socket.lenQue )and (socket.pktInFlight <__windowSize) then
                sendNextPacket(localPort)
            end
        end
    end

    local function netMaintaince()
        local status,err
        while true do
            os.sleep(__serviceInterval)
            _LogUtil.logFailures(logID,processQueue)
            _LogUtil.logFailures(logID,advanceTimer)
            _LogUtil.logFailures(logID,handleTimouts)
        end
    end

    local function reset()
        -- math.randomseed(os.time())
    end

    local function init()
        _LogUtil.info(logID,"initial startup")
        reset()
        local t = thread.create(netMaintaince)
        if (t == nil) then
            _LogUtil.error(logID,"thread failed to create")
            return
        end
        t:detach()
    end

    function RDT.listen(port, newClientcb, newMessagecb)
        _NetRDT.newClientcb[port] = newClientcb
        _NetRDT.newMessagecb[port] = newMessagecb
        _NetRDT.portTypes[port] = _RdtMode.listening
        _NetUtil.open(port, _NetRDT.safeNetProcessing)
    end

    function RDT.closeLister(port)
        _NetRDT.newClientcb[port] = nil
        _NetRDT.newMessagecb[port] = nil
        _NetRDT.portTypes[port] = nil
        _NetUtil.close(port)
    end
 
    function RDT.openSocket(dest, port, callBack)
        local newLocalPort = getFreePort()
        _NetRDT.portTypes[newLocalPort] = _RdtMode.syn1
        sendSyn(dest,port,newLocalPort)
        local _, localPort, remoteAddress, remotePort = event.pull(30, _NetDefs.events.syncResponse, newLocalPort)
        if localPort == nil then
            error("Port failed to open")-- Timed out :(
        end
        return newSocket(localPort,remoteAddress,remotePort)
    end

    function RDT.closeSocket(socket)
        closeSocket(socket.localPort,true)
    end

    function RDT.send(socket,...)
        enqueue(socket.localPort)
    end

    init()
end

return RDT
