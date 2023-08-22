if (_LogUtil == nil) then
    require("logUtils")
end
require("netDefs")
local component = require("component")
local computer = require("computer")
local serial = require("serialization")
local event = require("event")
local thread = require("thread")

local logID = _LogUtil.newLogger("netInterface", _LogLevel.error, _LogLevel.trace, _LogLevel.noLog)
_LogUtil.trace(logID, "New Logger")
local allInterfaces = {
    -- key:modemAddr -> interface
}


local function processGlobalMessage()
end

local function init()
    _LogUtil.info(logID,"initial startup")
    if(t == nil) then
        _LogUtil.error(logID,"thread failed to create")
        return
    end
    t:detach() 
    -- RegisterEventHandlers
    local status = event.listen("modem_message", processGlobalMessage)
    if (status == false) then
        _LogUtil.error(logID,"Failed to register listener for network data returned:"..status)
    end
end
init()