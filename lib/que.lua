local que = {}
local Logger = require("logUtil")
local serial = require("serialization")

local log = Logger:new("Que",LogLevel.error,LogLevel.trace,LogLevel.noLog)
log:clearLog()


function que.enqueue(queue,data)
    if(queue.len >= queue.max) then
        log:Error(debug.traceback("Que full! Not appending"))
        return queue
    end
    local i = (queue.ini + (queue.len)) % queue.max
    queue.data[i] = data
    queue.len = queue.len + 1
    log:Trace("queuing index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    log:Trace("queue:"..serial.serialize(queue))
    return queue
end

function que.peak(queue,n)
    if(n > queue.len) then
        log:Error(debug.traceback("peaking outside of que range returning nil"))
        return nil
    end
    local i = (queue.ini + (n-1)) % queue.max
    local d = queue.data[i]
    log:Trace("Peaking at index:"..i.." d:"..serial.serialize(d))
    log:Trace("queue:"..serial.serialize(queue))
    return d
end

function que.dequeue(queue)
    if(queue.len <=0) then
        log:Error(debug.traceback("Cant dequeue from an empty que."))
        return nil
    end
    local i = queue.ini
    local d = queue.data[i]
    queue.len = queue.len - 1
    queue.ini = (queue.ini + 1) % queue.max
    queue.data[i] = nil
    log:Trace("dequeuing From index:"..i.." ini:"..queue.ini.." len:"..queue.len)
    log:Trace("queue:"..serial.serialize(queue))
    return queue,d
end

function que.len(queue)
    return queue.len
end

function que.Queue(max)
    return {len=0,ini=1,data={},max=max}
end

return que