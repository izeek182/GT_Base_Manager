local que = {}
require("logUtils")
local serial = require("serialization")

local logID = _LogUtil.newLogger("que",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)

function que.enqueue(queue,data)
    if(queue.len >= queue.max) then
        _LogUtil.error(logID,debug.traceback("Que full! Not appending"))
        return queue
    end
    local i = (queue.ini + (queue.len)) % queue.max
    queue.data[i] = data
    queue.len = queue.len + 1
    _LogUtil.trace(logID,"queuing index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return queue
end

function que.peak(queue,n)
    if(n > queue.len) then
        _LogUtil.error(logID,debug.traceback("peaking outside of que range:"..n.." max"..queue.len.." returning nil"))
        return nil
    end
    local i = (queue.ini + (n-1)) % queue.max
    local d = queue.data[i]
    _LogUtil.trace(logID,"Peaking at index:"..i.." d:"..serial.serialize(d))
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return d
end

function que.dequeue(queue)
    if(queue.len <=0) then
        _LogUtil.error(logID,debug.traceback("Cant dequeue from an empty que."))
        return nil
    end
    local i = queue.ini
    local d = queue.data[i]
    queue.len = queue.len - 1
    queue.ini = (queue.ini + 1) % queue.max
    queue.data[i] = nil
    _LogUtil.trace(logID,"dequeuing From index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    _LogUtil.trace(logID,"queue:"..serial.serialize(queue))
    return queue,d
end

function que.len(queue)
    return queue.len
end

function que.Queue(max)
    return {len=0,ini=1,data={},max=max}
end

return que