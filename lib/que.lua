local que = {}
require("logUtils")
local serial = require("serialization")

local logID = _LogUtil.newLogger("que",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)

function que.enqueue(queue,data)
    local i = queue.ini + (queue.len)
    queue.data[i] = data
    queue.len = queue.len + 1
    _LogUtil.trace(logID,"queuing index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return queue
end

function que.peak(queue,n)
    local i = queue.ini + (n-1)
    local d = queue.data[i]
    _LogUtil.trace(logID,"Peaking at index:"..i.." d:"..serial.serialize(d))
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return d
end

function que.dequeue(queue)
    local i = queue.ini + (queue.len-1)
    local d = queue.data[i]
    queue.len = queue.len - 1
    queue.ini = queue.ini + 1
    queue.data[i] = nil
    _LogUtil.trace(logID,"dequeuing From index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return queue,d
end

function que.len(queue)
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return queue.len
end

function que.Queue(max)
    return {len=0,ini=1,data={},max=max}
end

return que