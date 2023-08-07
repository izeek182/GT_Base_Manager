
require("logUtils")
local serial = require("serialization")
local que = require("que")
local logID = _LogUtil.newLogger("dataQue",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)

local dataQue = {}

function dataQue.QueueData(que,data)
    
    return que
end

function dataQue.NextInWin(que)
end

function dataQue.StartOfWin(que)
end

function dataQue.winHasNext(que)
end

function dataQue.AckPacket(que,ackNum)
end

function dataQue.DataQue(max)
    local dq={}
    dq.q = que.Queue(max)
    dq.winSize = 0
    dq.winSent = 0
    dq.seqNum = 0
    dq.ackNum = 0
    return dq
end


return dataQue