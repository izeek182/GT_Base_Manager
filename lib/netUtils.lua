if (_NetUtil == nil) then
    require("netDefs")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")

    _NetVar = {
        Callbacks = {}, -- {port:Callback}
        packetNum = 0
    }
    _NetUtil = {

    }
        
    local function packHeader(PacketNum,PacketAge)
        local header = {PacketNum,PacketAge}
        return serial.serialize(header)
    end

    local function unpackHeader(header)
        local header = serial.unserialize(header)
        return table.unpack(header)
    end
    
    local function netMaintaince()
        os.sleep(5)
    end
    
    local function initModems()
        local list = component.list("modem")
        modems = {}
        for index, value in pairs(list) do
            if(modems == {})then
                defaultModem = component.proxy(index)
            end
            modems[index] = component.proxy(index)
        end
    end
    
    local function netProcessing(eventName, localAddress, remoteAddress, port, distance, --l1
        header,     -- netUtilHeader 
        ,...)    -- Next Levels
        
        local pNum,pAge = unpackHeader(header) -- Do something with the packetData....... someday

        if(_NetVar.Callbacks[port] ~= nil) then
            _NetVar.Callbacks[port].callback(eventName, localAddress, remoteAddress, port, distance,unpack(arg))
        else
            print("NetUtils: could not find callback assosiated with port:"..port)
        end

    end

    local function reset()
        initModems()
        _NetVar = {
            Callbacks = {}, -- {port:Callback}
            packetNum = 0
        }
    end

    function _NetUtil.send(dest,port,...)
        _NetVar.packetNum = _NetVar.packetNum + 1;
        local header = packHeader(_NetVar.packetNum,0)
        for key, value in pairs(modems) do
            modems[key].send(dest,port,header,unpack(arg))
        end
    end

    function _NetUtil.broadcast(port,...)
        _NetVar.packetNum = _NetVar.packetNum + 1;
        local header = packHeader(_NetVar.packetNum,0)
        for key, value in pairs(modems) do
            modems[key].broadcast(port,header,unpack(arg))
        end
    end
    
    function _NetUtil.open(port,callback)
        for key, value in pairs(modems) do
            modems[key].open(port)
        end
        if(_NetVar.Callbacks[port] ~= nil) then
            _NetVar.Callbacks[port] = callback
        end
    end
    
    local function init()
        reset()
        local t = thread.create(netMaintaince)
        if(t == nil) then
            print("thread failed to create")
            return
        end
        t:detach() 
        -- RegisterEventHandlers
        local status = event.listen("modem_message", netProcessing)
        if (status == false) then
            error("Failed to register listener for network data returned:"..status)
        end
    end

    init()
end
