if(_L2 == nil) then
    require("netDefs")
    local component = require("component")
    local computer = require("computer")
    local serial = require("serialization")
    local event = require("event")
    local thread = require("thread")


    local modems = {}
    _L2Vars = {
        hostNameTouuid  = {},   -- HostName : uuid 
        uuidToHostName  = {},   -- uuid : HostName
        localHostNames  = {},
        routingTable    = {},   -- HostName -> {modemUUid,nextStepuuid}
        recentMessages  = {},    -- HostName -> {messageNumber : true | nil}
        packetNum       = 0
    }

    _L2 = {
    }

    local function packHeader(DestHostName,SrcHostName,PacketNum,PacketAge)
        local header = {DestHostName,SrcHostName,PacketNum,PacketAge}
        return serial.serialize(header)
    end

    local function unpackHeader(header)
        local header = serial.unserialize(header)
        return table.unpack(header)
    end

    function _L2.send(src,dest,port,...)
        _L2Vars.packetNum = _L2Vars.packetNum + 1;
        local header = packHeader(dest,src,_L2Vars.packetNum,0)
        local payload = serial.serialize({...})
        if(_L2Vars.routingTable[dest] == nil)then
            for key, value in pairs(modems) do
                modems[key].broadcast(port,header,payload)
            end
        else
            modems[_L2Vars.routingTable[dest].modem].send(_L2Vars.routingTable[dest].dest,port,header,payload)
        end
    end

    function _L2.createHost(name,port,callback)
        local Lhost = {
            Name = name,
            send = function (host,dest,...)
                _L2.send(host.Name,dest,host.Port,...)
            end,
            close = function (host)
                _L2Vars.localHostNames[host.Name] = nil
                host.active = false;
            end,
            Port = port,
            cb = callback,
            active = true
        }
        if(callback ~= nil) then
            _L2.open(port)
        end
        if(_L2Vars.localHostNames[name] == nil) then
            _L2Vars.localHostNames[name] = {}
            _L2Vars.localHostNames[name][tostring(port)] = Lhost
        else
            if(_L2Vars.localHostNames[name][tostring(port)] == nil)then
                _L2Vars.localHostNames[name][tostring(port)] = Lhost                
            else
                print("Port:"..port.."already taken for host:"..name.." callback fucntion not overrwitten")
                return Lhost
            end
        end
        return Lhost
    end

    function _L2.open(port)
        for key, value in pairs(modems) do
            modems[key].open(port)
        end        
    end

    local function CheckNewMessage(SrcHostName,packetNum)
        local key = tostring(packetNum)
        if(_L2Vars.recentMessages[SrcHostName] == nil) then 
            _L2Vars.recentMessages[SrcHostName] = {}
            _L2Vars.recentMessages[SrcHostName][key] = {}
            _L2Vars.recentMessages[SrcHostName][key].b = true
            _L2Vars.recentMessages[SrcHostName][key].t = computer.uptime()
            
            -- print("host Not found in recent list adding:"..SrcHostName)
            return true
        else
            if(_L2Vars.recentMessages[SrcHostName][key] == nil) then
                _L2Vars.recentMessages[SrcHostName][key] = {}
                _L2Vars.recentMessages[SrcHostName][key].b = true
                _L2Vars.recentMessages[SrcHostName][key].t = computer.uptime()
                -- print("host Found, but message id not found marking it:"..key)
                return true
            else
                -- print("Message is a repeat host:"..SrcHostName.." key:"..key)
                return false
            end
        end
    end

    local function l2Processing(eventName, localAddress, remoteAddress, port, distance, --l1
        header,     --l2
        payload)    -- Next Levels
        -- print("Message H:"..payload.." P:"..payload)
        local dest,src,pNum,pAge = unpackHeader(header)
        local payloadT = serial.unserialize(payload)
        local new = CheckNewMessage(src,pNum)
        if(new == false) then
            -- print("Repeat Message H:"..header.." P:"..payload)
            return
        end
        --print("New Message H:"..header.." P:"..payload)
        if(_L2Vars.localHostNames[dest][tostring(port)] ~= nil) then
            if(_L2Vars.localHostNames[dest][tostring(port)].cb(src,payloadT)==nil) then
                return
            end
        end

        if(_L2Vars.routingTable[src] == nil) then
            _L2Vars.routingTable[src] = {modem = localAddress,dest = remoteAddress}
        else
            if _L2Vars.routingTable[src].modem ~= localAddress |
            _L2Vars.routingTable[src].modem ~= remoteAddress
            then
                -- Add a packetAge to optimize routes?
            end
        end
        local newHeader = packHeader(dest,src,pNum,(pAge+1))

        if(_L2Vars.routingTable[dest] == nil)then
            for key, value in pairs(modems) do
                if key ~= localAddress then
                    modems[key].broadcast(port,newHeader,payload)
                end
            end
        else
            modems[_L2Vars.routingTable[dest].modem].send(_L2Vars.routingTable[dest].dest,port,newHeader,payload)
        end
    end

    local function initModems()
        local list = component.list("modem")

        modems = {}

        for index, value in pairs(list) do
            modems[index] = component.proxy(index)
        end
    end

    local function cleanRecentMessages()
        while true do
            -- print("Checking for recentMessages that needs cleaning")
            for key, value in pairs(_L2Vars.recentMessages) do
                -- print("Checking host:"..key)
                for key2, value2 in pairs(_L2Vars.recentMessages[key]) do
                    -- print("entry:"..key..":"..key2)
                    -- print(_L2Vars.recentMessages[key][key2].t)
                    -- print("entry:"..key..":"..key2.." is "..(os.difftime(computer.uptime(),_L2Vars.recentMessages[key][key2].t)).." seconds old")
                    if(os.difftime(computer.uptime(),_L2Vars.recentMessages[key][key2].t) > 10)then
                        -- print("cleaning out message from:"..key)
                        _L2Vars.recentMessages[key][key2] = nil
                    end
                end                
            end
            os.sleep(5)
        end
    end

    function _L2.reset()
        initModems()
        _L2Vars = {
            hostNameTouuid  = {},   -- HostName : uuid 
            uuidToHostName  = {},   -- uuid : HostName
            localHostNames  = {},
            routingTable    = {},   -- HostName -> {modemUUid,nextStepuuid}
            recentMessages  = {},    -- HostName -> {messageNumber : true | nil}
            packetNum       = 0
        }
    end

    local function init()
        -- RegisterEventHandlers
        _L2.reset()
        local t = thread.create(cleanRecentMessages)
        if(t == nil) then
            print("thread failed to create")
        end
        for key, value in pairs(t) do
            
        end
        t:detach()

        local status = event.listen("modem_message", l2Processing)
        if (status == false) then
            error("Failed to register listener for network data returned:"..status)
        end
    end

    init()
end
return _L2