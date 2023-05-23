if (_SubUtil == nil) then
    local net = require("netUtils")
    local thread = require("thread")

    _SubUtil = {

    }
    _SubVal = {
        callbacks = {},     -- callbacks[subType][subKey] = {Mode,callbacks}
        subRefreshRate = 60 -- every 60 seconds we re broadcast our request for data
    }

    local function sendSubscribe() 
        net.broadcast()
    end

    function _SubUtil.refreshSubscriptions()
        for subType, subTable in pairs(_SubVal.callbacks) do
            for subKey, value in pairs(subTable) do
                
            end
        end
        os.sleep(_SubVal.subRefreshRate)
    end

    local function processData()

    end

    function _SubUtil.subscribe(subType,subKey,subModel,callback)
        if(_SubVal.callbacks[subType] == nil) then
            _SubVal.callbacks[subType] = {}
        end
        
        if(_SubVal.callbacks[subType][subKey] == nil) then
            _SubVal.callbacks[subType][subKey] = {}
        end
        
        local i = 1
        
        while((_SubVal.callbacks[subType][subKey][i]~=nil)&(_SubVal.callbacks[subType][subModel][i]~=callback)) do
            i = i + 1;
        end
        
        if((_SubVal.callbacks[subType][subKey][i]==nil)) then
            _SubVal.callbacks[subType][subKey][i] = {subModel,callback}
        end
        
    end

    

    local function init()
        net.open(_NetDefs.portEnum.subData,processData);

        local t = thread.create(refreshSubscriptions)
        if(t == nil) then
            print("Subscriber refresh failed to create")
            return
        end
        t:detach() 


    end

    init()

end
return _SubUtil