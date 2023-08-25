if (RDT == nil) then
    RDT = {
    }

    local Logger = require("logUtil")
    local que = require("que")
    local tcpPkt = require("tcpPacket.lua")
    require("netDefs")
    require("netUtils")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")

    local log = Logger:new("netRDT",LogLevel.error,LogLevel.trace,LogLevel.noLog)
    log:clearLog()

    local _RdtMode = {
        syn1      = 1,
        syn2      = 2,
        hb        = 3,
        data      = 4,
        listening = 5,
        close     = 9,
    }

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
        --        pktQue:[pktQue],
        --        winOffset:
        --        dupAck
        --        pktRxBuf:{}}}}openSocket
        newMessagecb = {}, -- {<portNumber>:<callback>}
        newClientcb = {},  -- {<portNumber>:<callback>}
    }

    local function timeSince(someTime)
        if (someTime < _NetRDT.time) then
            return _NetRDT.time - someTime;
        else
            return _NetRDT.time + (_NetRDT.maxTime - someTime);
        end
    end

    local function setCallback(localPort, callback)
        log:Trace( "setting Callback on", localPort)
        _NetRDT.Sockets[localPort].callback = callback
    end
    local function callCallback(localPort, data)
        log:Trace( " Calling back on port ", localPort)
        _NetRDT.Sockets[localPort].callback(data)
    end

    local function openSocket(port, remotePort, remoteHost, callback)
        log:Info( "Opening RDT socket on:", port, " to ", remoteHost, ":", remotePort)
        _NetRDT.portTypes[port] = _RdtMode.data
        _NetUtil.open(port, _NetRDT.safeNetProcessing)
        local socket          = {};
        socket.remoteHost     = remoteHost
        socket.remotePort     = remotePort
        socket.callback       = callback
        socket.pktNum         = 0
        socket.ackNum         = 1
        socket.LastTx         = _NetRDT.time
        socket.LastRx         = _NetRDT.time
        socket.pktQue         = que.Queue(_NetDefs.rdtConst.bufferSize)
        socket.winOffset      = 0
        socket.dupAck         = 0
        socket.pktRxBuf       = {}
        _NetRDT.Sockets[port] = socket
    end

    local function buildNextPkt(localPort, data)
        return tcpPkt.pack(localPort, _RdtMode.data, data)
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

    local function sendPkt(localPort, pkt,num)
        local skt = _NetRDT.Sockets[localPort]
        local ack = skt.ackNum
        pkt = tcpPkt.setSeqAck(pkt, ack, num)
        log:Info( "Sending on:", localPort, " -> ", serial.serialize(pkt))
        _NetRDT.Sockets[localPort].LastTx = _NetRDT.time
        _NetUtil.send(
            _NetRDT.Sockets[localPort].remoteHost,
            _NetRDT.Sockets[localPort].remotePort,
            pkt
        )
    end

    local function sendFromQue(localPort,n)
        local skt = _NetRDT.Sockets[localPort]
        local num = skt.pktNum+n
        sendPkt(localPort, que.peak(skt.pktQue, n),num)
    end
    
    local function resendFirstPacket(localPort)
        sendFromQue(localPort,1)
    end
    
    local function sendNextPacket(localPort)
        local skt = _NetRDT.Sockets[localPort]
        sendFromQue(localPort,skt.winOffset + 1)
    end

    local function sendSignal(localPort, RdtMode, data)
        local num = _NetRDT.Sockets[localPort].pktNum
        sendPkt(localPort,
            tcpPkt.pack(
                localPort,
                RdtMode,
                data),
            num
        )
    end

    local function closeSocket(port, graceful)
        log:Info( "closing RDT port:", port)
        if graceful then
            sendSignal(port, _RdtMode.close)
        end
        _NetUtil.close(port)
        _NetRDT.portTypes[port] = nil
        _NetRDT.Sockets[port] = nil
    end

    local function ackDistance(recivedAck, currentPktNum)
        if (recivedAck > currentPktNum) then
            return recivedAck - currentPktNum
        end
        local bufLen = _NetDefs.rdtConst.bufferSize
        return ((bufLen + recivedAck) - currentPktNum) % bufLen
    end

    -- Recived an ack for a packed dont resend that packet
    local function registerAckPacket(ackNum, port)
        local ackDist = ackDistance(ackNum, _NetRDT.Sockets[port].pktNum)
        log:Trace( "Recived packet with ack:", ackNum, " Last PacketNum:", _NetRDT.Sockets[port].pktNum,
            " on port:", port, " distance from last ack:", ackDist)
        if(ackDist == 0) then
            _NetRDT.Sockets[port].dupAck = _NetRDT.Sockets[port].dupAck + 1
            -- and que.len(_NetRDT.Sockets[port].pktQue) > 0
            if(_NetRDT.Sockets[port].dupAck == 2 and que.len(_NetRDT.Sockets[port].pktQue) > 0) then
                resendFirstPacket(port)
            end
        else
            _NetRDT.Sockets[port].dupAck = 0
            if(ackDist < _NetDefs.rdtConst.maxWindowSize and _NetRDT.Sockets[port].winOffset > (0.8*_NetDefs.congestionControl.maxPkt)) then
                _NetDefs.ackedPacket()
                log:Trace("packet Acked, with many packets in flight expanding maxPkts in flight, now:".._NetDefs.congestionControl.maxPkt)
            end
            log:Trace("packet:"..ackNum.." Acked. dequeuing")
            if(que.len(_NetRDT.Sockets[port].pktQue) > 0) then
                _NetRDT.Sockets[port].pktQue = que.dequeue(_NetRDT.Sockets[port].pktQue)
                _NetRDT.Sockets[port].pktNum = _NetRDT.Sockets[port].pktNum + 1
                _NetRDT.Sockets[port].winOffset = _NetRDT.Sockets[port] - 1  
                registerAckPacket(ackNum, port)
            end

        end
    end

    local function passOnData(port, data)
        callCallback(port, data)
    end

    local function ackPacket(port)
        local nextData = _NetRDT.Sockets[port].ackNum
        local dataInQue = _NetRDT.Sockets[port].pktRxBuf[nextData]
        log:Info("nextIndex:"..nextData.." ack packet, data Received but not used"..serial.serialize(_NetRDT.Sockets[port].pktRxBuf))
        if not (dataInQue == nil) then
            _NetRDT.Sockets[port].ackNum = nextData + 1
            passOnData(port, dataInQue)
            _NetRDT.Sockets[port].pktRxBuf[nextData] = nil
            ackPacket(port)
            -- The the next send packet(HB or data with deliver this ack no need to press the issue)
        end
    end

    local function newSocket(localPortIn, remoteAddressIn, remotePortIn)
        return { localPort = localPortIn, remoteAddress = remoteAddressIn, remotePort = remotePortIn }
    end

    local function recievedData(port, remoteAddress, pktNum, ackNum, data)
        log:Info( "Received data on:", port, " -> ", serial.serialize(data))
        _NetRDT.Sockets[port].LastRx = _NetRDT.time
        _NetRDT.Sockets[port].pktRxBuf[pktNum] = data
        registerAckPacket(ackNum, port)
        ackPacket(port)
        -- processRdtPacket(remoteAddress, port, pktNum, ackNum)
    end

    local function connectionRequest(port, remoteAddress, remotePort)
        log:Info( "Received connection request on:", port)
        if (_NetRDT.portTypes[port] == _RdtMode.listening) then
            local newLocalPort = getFreePort()
            -- new client callback returns new message callback
            local newCallback = _NetRDT.newClientcb[port](newSocket(newLocalPort, remoteAddress, remotePort))
            if (newCallback == nil) then
                log:Trace( " no callback returned, replacing with default ", _NetRDT.newMessagecb[port])
                newCallback = _NetRDT.newMessagecb[port]
            end
            openSocket(newLocalPort, remotePort, remoteAddress, newCallback)
            sendSignal(newLocalPort, _RdtMode.syn2, port)
        end
    end
    local function tempCallback()
        log:Error( "callback never set after connection Accepted")
    end
    local function connectionAccepted(port, remoteAddress, remotePort)
        log:Info( "Connection accepted:", port)
        if (_NetRDT.portTypes[port] == _RdtMode.syn1) then
            openSocket(port, remotePort, remoteAddress, tempCallback)
            event.push(_NetDefs.events.syncResponse, port, remoteAddress, remotePort)
        end
    end

    local function gotHeartbeat(ackNum, port)
        log:Info( "Received Heart Beat on:", port)
        registerAckPacket(ackNum, port)
        _NetRDT.Sockets[port].LastRx = _NetRDT.time
    end

    local function closeConnection(port)
        log:Info( "port:", port, "Closed by remote host")
        if _NetRDT.portTypes[port] == _RdtMode.data then
            closeSocket(port, false)
        end
    end

    local function netProcessing(_, _, remoteAddress, port, _, pkt)
        local srcPort, pktNum, ackNum, RDT_mode, data = tcpPkt.unpack(pkt)
        if (RDT_mode == _RdtMode.data) then
            recievedData(port, remoteAddress, pktNum, ackNum, data)
        elseif (RDT_mode == _RdtMode.syn1) then
            connectionRequest(port, remoteAddress, srcPort)
        elseif (RDT_mode == _RdtMode.syn2) then
            connectionAccepted(port, remoteAddress, srcPort)
        elseif (RDT_mode == _RdtMode.hb) then
            gotHeartbeat(ackNum, port)
        elseif (RDT_mode == _RdtMode.close) then
            closeConnection(port)
        end
    end

    function _NetRDT.safeNetProcessing(...)
        return log:logFailures( netProcessing, ...)
    end

    local function sendSyn(remoteHost, remotePort, localPort)
        _NetUtil.open(localPort, _NetRDT.safeNetProcessing)
        _NetUtil.send(
            remoteHost,
            remotePort,
            tcpPkt.pack(
                localPort,
                _RdtMode.syn1,
                {})
        )
    end

    local function advanceTimer()
        _NetRDT.time = _NetRDT.time + 1
        if (_NetRDT.time > _NetRDT.maxTime) then
            _NetRDT.time = 0
        end
    end

    local function resendQue(localPort)
        _NetRDT.Sockets[localPort].winOffset = 0
    end

    local function handleTimouts()
        for localPort, socket in pairs(_NetRDT.Sockets) do
            local LastTx = socket.LastTx
            local LastRx = socket.LastRx
            if (socket.winOffset > 0 and timeSince(LastTx) > _NetDefs.timeOut.resend) then
                _NetDefs.queTimeout()
                log:Trace( "timeout on que resending, redusing max pktsInflight to:".._NetDefs.congestionControl.maxPkt)
                resendQue(localPort)
            elseif (socket.winOffset == 0 and timeSince(LastTx) > _NetDefs.timeOut.sendHB and _NetRDT.portTypes[localPort] == _RdtMode.data) then
                log:Trace( "timeout on POL sending Heartbeat")
                sendSignal(localPort, _RdtMode.hb)
            end

            if (timeSince(LastRx) > _NetDefs.timeOut.cold) then
                log:Error( "Socket Has timed out on port:", localPort)
                closeSocket(localPort, false)
            end
        end
    end

    local function processQueue()
        for localPort, socket in pairs(_NetRDT.Sockets) do
            local LastTx = socket.LastTx
            if(timeSince(LastTx) > _NetDefs.timeOut.genSend) then 
                local queLen = que.len(socket.pktQue)
                if (socket.winOffset < queLen) and (socket.winOffset < _NetDefs.congestionControl.maxPkt) then
                    log:Trace( "sending data from que, len:", queLen, " winOffset:", socket.winOffset,
                    " windowSize:", _NetDefs.congestionControl.maxPkt)
                    sendNextPacket(localPort)
                end
            end
        end
    end

    local function netMaintaince()
        local status, err
        while true do
            os.sleep(_NetDefs.timming.serviceInterval)
            log:logFailures( processQueue)
            log:logFailures( advanceTimer)
            log:logFailures( handleTimouts)
        end
    end

    local function reset()
        -- math.randomseed(os.time())
    end

    local function init()
        log:Info( "initial startup")
        reset()
        local t = thread.create(netMaintaince)
        if (t == nil) then
            log:Error( "thread failed to create")
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
        sendSyn(dest, port, newLocalPort)
        local _, localPort, remoteAddress, remotePort = event.pull(30, _NetDefs.events.syncResponse, newLocalPort)
        if localPort == nil then
            error("Port failed to open") -- Timed out :(
        end
        local skt = newSocket(localPort, remoteAddress, remotePort)
        setCallback(localPort, callback)
        return skt
    end

    function RDT.closeSocket(socket)
        closeSocket(socket.localPort, true)
    end

    function RDT.send(socket, data)
        local queue = _NetRDT.Sockets[socket.localPort].pktQue
        _NetRDT.Sockets[socket.localPort].pktQue = que.enqueue(queue, buildNextPkt(socket.localPort, data))
    end

    init()
end

return RDT
