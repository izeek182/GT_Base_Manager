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

    local logID = _LogUtil.newLogger("netRDT",_LogLevel.trace,_LogLevel.trace,_LogLevel.noLog)

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

    local function setCallback(localPort,callback)
        _LogUtil.trace(logID,"setting Callback on",localPort)
        _NetRDT.Sockets[localPort].callback = callback
    end
    local function callCallback(localPort,...)
        _LogUtil.trace(logID," Calling back on port ",localPort)
        _NetRDT.Sockets[localPort].callback(...)
    end

    local function openSocket(port, remotePort, remoteHost, callback)
        _LogUtil.info(logID,"Opening RDT socket on:",port," to ",remoteHost,":",remotePort)
        _NetRDT.portTypes[port] = _RdtMode.data
        _NetUtil.open(port,  _NetRDT.safeNetProcessing)
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
        return header
    end

    local function unpackHeader(header)
        return table.unpack(header)
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
            ...
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
        _LogUtil.trace(logID,"Passing on data:"..serial.serialize({...}))
        callCallback(port,...)
    end

    local function processRdtPacket(remoteAddress, port, pktNum, ackNum, ...)
        registerAckPacket(ackNum, port)
        if (expectedPacket(port, pktNum)) then
            ackPacket(port, pktNum)
            passOnData(port, ...)
        end
    end

    local function newSocket(localPortIn,remoteAddressIn,remotePortIn)
        return {localPort=localPortIn,remoteAddress=remoteAddressIn,remotePort=remotePortIn}
    end

    local function recievedData(port,remoteAddress,pktNum, ackNum,...)
        _LogUtil.info(logID,"Received data on:",port," -> ",serial.serialize({...}))
        processRdtPacket(remoteAddress, port, pktNum, ackNum, table.unpack({...}))
    end

    local function connectionRequest(port,remoteAddress,remotePort)
        _LogUtil.info(logID,"Received connection request on:",port)
        if (_NetRDT.portTypes[port] == _RdtMode.listening) then
            local newLocalPort = getFreePort()
            -- new client callback returns new message callback
            local newCallback = _NetRDT.newClientcb[port](newSocket(newLocalPort,remoteAddress,remotePort))
            if(newCallback == nil) then 
                _LogUtil.trace(logID," no callback returned, replacing with default ",_NetRDT.newMessagecb[port])
                newCallback = _NetRDT.newMessagecb[port]
            end
            openSocket(newLocalPort,remotePort, remoteAddress, newCallback)
            sendSocket(newLocalPort, _RdtMode.syn2,port)
        end
    end
    local function tempCallback()
        _LogUtil.error(logID,"callback never set after connection Accepted")
    end
    local function connectionAccepted(port,remoteAddress,remotePort)
        _LogUtil.info(logID,"Connection accepted:",port)
        if (_NetRDT.portTypes[port] == _RdtMode.syn1) then
            openSocket(port, remotePort,remoteAddress,tempCallback)
            event.push(_NetDefs.events.syncResponse,  port, remoteAddress, remotePort)
        end
    end

    local function gotHeartbeat(port)
        _LogUtil.info(logID,"Received Heart Beat on:",port)
        if (_NetRDT.portTypes[port] == _RdtMode.data) then
            _NetRDT.Sockets[port].LastRx = _NetRDT.time
        end
    end

    local function closeConnection(port)
        _LogUtil.info(logID,"port:",port, "Closed by remote host")
        if _NetRDT.portTypes[port] == _RdtMode.data then
            closeSocket(port,false)
        end
    end

    local function netProcessing(eventName, localAddress, remoteAddress, port, distance, --l1
                                 RDT_header,                                             -- RDT_Header
                                 ...)                                                    -- Next Levels
        local srcPort, pktNum, ackNum, RDT_mode  = unpackHeader(RDT_header) 
        if (RDT_mode == _RdtMode.data) then
            recievedData(port,remoteAddress,pktNum, ackNum,...)
        elseif (RDT_mode == _RdtMode.syn1) then
            connectionRequest(port,remoteAddress,srcPort)
        elseif (RDT_mode == _RdtMode.syn2) then
            connectionAccepted(port,remoteAddress,srcPort)
        elseif (RDT_mode == _RdtMode.hb) then
            gotHeartbeat(port)
        elseif (RDT_mode == _RdtMode.close) then
            closeConnection(port)
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
        _LogUtil.trace(logID," queuing new data at:",bufI," to send on port:",port,", ",serial.serialize(packedData))
        _NetRDT.Sockets[port].pktQue[bufI] = packedData
        _NetRDT.Sockets[port].lenQue = _NetRDT.Sockets[port].lenQue + 1
    end

    local function dequeue(port)
        local i = _NetRDT.Sockets[port].pktNum
        local data = _NetRDT.Sockets[port].pktQue[i]
        _NetRDT.Sockets[port].pktNum = i + 1
        _NetRDT.Sockets[port].lenQue = _NetRDT.Sockets[port].lenQue - 1
        _LogUtil.trace(logID," dequeuing data from:",i," to send on port:",port,", ",serial.serialize(data))
        return data
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
                _LogUtil.trace(logID,"timeout on que resending")
                resendQue(localPort)
            elseif (socket.pktInFlight == 0 and timeSince(LastTx) > _NetDefs.timeOut.sendHB and _NetRDT.portTypes[localPort] == _RdtMode.data) then
                _LogUtil.trace(logID,"timeout on POL sending Heartbeat")
                sendSocket(localPort, _RdtMode.hb)
            end

            if (timeSince(LastRx) > _NetDefs.timeOut.cold) then
                _LogUtil.error(logID,"Socket Has timed out on port:",localPort)
                closeSocket(localPort,false) 
            end
        end
    end

    local function sendNextPacket(localPort)
        sendSocket(localPort,_RdtMode.data,dequeue(localPort))
    end

    local function processQueue()
        for localPort, socket in pairs(_NetRDT.Sockets) do
            if (socket.pktInFlight < socket.lenQue )and (socket.pktInFlight <__windowSize) then
                _LogUtil.trace(logID,"sending data from que, len:",socket.lenQue," pktInFlight:",socket.pktInFlight," windowSize:",__windowSize)
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
 
    function RDT.openSocket(dest, port, callback)
        local newLocalPort = getFreePort()
        _NetRDT.portTypes[newLocalPort] = _RdtMode.syn1
        sendSyn(dest,port,newLocalPort)
        local _, localPort, remoteAddress, remotePort = event.pull(30, _NetDefs.events.syncResponse, newLocalPort)
        if localPort == nil then
            error("Port failed to open")-- Timed out :(
        end
        local skt = newSocket(localPort,remoteAddress,remotePort)
        setCallback(localPort,callback)
        return skt
    end

    function RDT.closeSocket(socket)
        closeSocket(socket.localPort,true)
    end

    function RDT.send(socket,...)
        enqueue(socket.localPort,{...})
    end

    init()
end

return RDT
