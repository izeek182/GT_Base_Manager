if (_NetUtil == nil) then
    _NetUtil = {
    }
    if(_LogUtil == nil) then
        require("logUtils")
    end
    require("netDefs")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")

    local logID = _LogUtil.newLogger("netUtil",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)
    _LogUtil.trace(logID,"New Logger")

    _NetVar = {
        Callbacks = {}, -- {port:Callback}
        packetNum = 0,
        modems = {}
    }
    local function packPacket(header,data) 
        return serial.serialize({header,data})
    end

    local function unpackPacket(packet)
        packet = serial.unserialize(packet)
        return table.unpack(packet)
    end

    local function packHeader(PacketNum,PacketAge)
        local header = {PacketNum,PacketAge}
        return header
    end

    local function unpackHeader(header)
        return table.unpack(header)
    end
    
    local function netMaintaince()
        os.sleep(5)
    end
    
    local function initModems()
        local list = component.list("modem")
        _NetVar.modems = {}
        for index, value in pairs(list) do
            _NetUtil.HostName = index
            _NetVar.modems[index] = component.proxy(index)
        end
    end
    
    local function netProcessing(eventName, localAddress, remoteAddress, port, distance, --l1
        packet)
        _LogUtil.trace(logID,"new message on:",localAddress,":",port," \"",packet,"\"")
        local header , data = unpackPacket(packet)

        local pNum,pAge = unpackHeader(header) -- Do something with the packetData....... someday

        if(_NetVar.Callbacks[port] == nil) then
            _LogUtil.error(logID,"NetUtils: could not find callback assosiated with port:"..port)
        else
            _LogUtil.trace(logID,"passing data on:"..serial.serialize(data) )
            _LogUtil.logFailures(logID,_NetVar.Callbacks[port],eventName, localAddress, remoteAddress, port, distance,table.unpack(data))
        end

    end

    local function reset()
        _NetVar = {
            Callbacks = {}, -- {port:Callback}
            packetNum = 0,
            modems = {}
        }
        initModems()
    end

    function _NetUtil.send(dest,port,...)
        _NetVar.packetNum = _NetVar.packetNum + 1;
        local header = packHeader(_NetVar.packetNum,0)
        local packet = packPacket(header, {...})
        _LogUtil.trace(logID,"Dest",dest,":",port,"Sending:",packet)
        for key, value in pairs(_NetVar.modems) do
            local sent = _NetVar.modems[key].send(dest,port,packet)
        end
    end

    function _NetUtil.broadcast(port,...)
        _LogUtil.trace(logID,"Broadcasting:",...)
        _NetVar.packetNum = _NetVar.packetNum + 1;
        local header = packHeader(_NetVar.packetNum,0)
        local packet = packPacket(header, {...})
        for key, value in pairs(_NetVar.modems) do
            _NetVar.modems[key].broadcast(port,packet)
        end
    end
    
    function _NetUtil.open(port,callback)
        _LogUtil.trace(logID,"opening Port:",port)
        for key, value in pairs(_NetVar.modems) do
            _NetVar.modems[key].open(port)
        end
        
        if(_NetVar.Callbacks[port] == nil) then
            _NetVar.Callbacks[port] = callback
        end
    end

    function _NetUtil.close(port)
        _LogUtil.trace(logID,"closing port:",port)
        for key, value in pairs(_NetVar.modems) do
            _NetVar.modems[key].close(port)
        end
        _NetVar.Callbacks[port] = nil
    end

    function _NetUtil.checkPortOpen(port)
        return (not _NetVar.Callbacks[port] == nil)
    end
    
    local function init()
        _LogUtil.info(logID,"initial startup")
        reset()
        local t = thread.create(netMaintaince)
        if(t == nil) then
            _LogUtil.error(logID,"thread failed to create")
            return
        end
        t:detach() 
        -- RegisterEventHandlers
        local status = event.listen("modem_message", netProcessing)
        if (status == false) then
            _LogUtil.error(logID,"Failed to register listener for network data returned:"..status)
        end
    end
    init()
end
