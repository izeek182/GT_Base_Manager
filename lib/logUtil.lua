local _LogUtil = {}
require("fileUtils")
local _MaxLogSize = 1000

---@alias LogLevel integer
LogLevel          = {
    trace = 1,
    info = 2,
    debug = 3,
    error = 4,
    noLog = 10,
    tostring = function(level)
        if level < 1 then
            return "-----"
        elseif level == 1 then
            return "trace"
        elseif level == 2 then
            return "info "
        elseif level == 3 then
            return "debug"
        elseif level == 4 then
            return "error"
        elseif level > 4 then
            return "VITAL"
        end
    end
}

---@class Logger
---@field protected name      string   Name of the logger, should give context as to the owning class
---@field protected TermLevel LogLevel Required level to log to Terminal
---@field protected FileLevel LogLevel Required level to log to File
---@field protected NetLevel  LogLevel Required level to send log on net
local Logger      = {
    -- Setting Logger Defaults
    ---@type string
    name      = "Unset",
    ---@type LogLevel
    TermLevel = LogLevel.error,
    ---@type LogLevel
    FileLevel = LogLevel.error,
    ---@type LogLevel
    NetLevel  = LogLevel.noLog
}



---Creates a new Logger Object with given Name, and returns logger handle
---Note Network Logging is disabled by default, but automaticly enabled when netUtils are loaded
---@param name string
---@param TerminalLogLevel LogLevel
---@param FileLogLevel LogLevel
---@param NetLogLevel LogLevel
---@return Logger
function Logger:new(name, TerminalLogLevel, FileLogLevel, NetLogLevel)
    local log     = {}
    log.name      = name or self.name
    log.TermLevel = TerminalLogLevel or self.TermLevel
    log.FileLevel = FileLogLevel or self.FileLevel
    log.NetLevel  = NetLogLevel or self.NetLevel
    setmetatable(log, self)
    self.__index = self
    return log
end

function Logger:getFile()
    return "/logs/" .. self.name .. ".log"
end

---takes the time in seconds and formats it to [dd:hh:mm:ss:ms]
---@param time number|nil
---@return string
local function formatTime(time)
    time = time or os.time()
    local time, ms = math.modf(time)
    ms = math.floor(ms * 100)
    local s = math.floor(time % 60)
    time = time / 60
    local m = math.floor(time % 60)
    time = time / 60
    local h = math.floor(time % 24)
    time = time / 24
    local d = math.floor(time % 100)
    return string.format("%02d:%02d:%02d:%02d:%02d", d, h, m, s, ms)
end

---Formats the prefix for all logs for this object, override to change
---@param level LogLevel
---@return string
function Logger:PreFixFormat(level)
    return "[" .. formatTime() .. "][" .. LogLevel.tostring(level) .. "][" .. self.name .. "]"
end

---This is the genral log formatter, This can be overriden to change log styles.
---@param level LogLevel
---@param ... any
---@return string
function Logger:genFormatLog(level, ...)
    local logPrefix = self:PreFixFormat(level)
    local log = logPrefix
    for _, value in pairs({ ... }) do
        log = log .. tostring(value)
    end
    return log
end

---Takes a String and logs it to the end of a file in the `/logs/` directory. to a file given the name of the logger
---@param str string
function Logger:fileLog(str)
    local fileName = self:getFile()
    if (_FileUtil.size(fileName) > _MaxLogSize) then
        _FileUtil.clear(fileName)
    end
    _FileUtil.append(fileName, str, "\n")
end

---Takes a string and logs it to console
---@param str string
function Logger:printLog(str)
    print(str)
end

---Takes a log and sends it over the network
--- This is a noop at startup, once netUtils is loaded, it will function
---@param str any
function Logger:netLog(str)
end

---Intializes the logging to the network, by replacing `netLog` with `newNetLog`
---@param newNetLog fun(Logger:Logger,string:string):any
function Logger:initNet(newNetLog)
    Logger.netLog = newNetLog
end

---Genral Log takes log and distributes it according to log level
---@param level any
---@param ... unknown
function Logger:log(level, ...)
    local logstr = self:genFormatLog(level, ...)
    if (self.TermLevel <= level) then
        self:printLog(logstr)
    end
    if (self.FileLevel <= level) then
        self:fileLog(logstr)
    end
    if (self.NetLevel <= level) then
        self:netLog(logstr)
    end
end

---Triggers a `trace` log 
---@param ... any
function Logger:Trace(...)
    self:log(LogLevel.trace,...)
end

---Triggers a `info` log 
---@param ... any
function Logger:Info(...)
    self:log(LogLevel.info,...)
end

---Triggers a `debug` log 
---@param ... any
function Logger:Debug(...)
    self:log(LogLevel.debug,...)
end

---Triggers a `error` log 
---@param ... any
function Logger:Error(...)
    self:log(LogLevel.error,...)
end

---Sets the required level to send log over net
---@param level LogLevel
function Logger:setNetLog(level)
    self.NetLevel = level
end

---Sets the required level to save to file
---@param level LogLevel
function Logger:setFileLog(level)
    self.FileLevel = level
end

---Sets the required level to send to terminal
---@param level LogLevel
function Logger:setTermLog(level)
    self.TermLevel = level
end

---Runs function and logs any thrown errors
---@param callback function
---@param ... any
---@return any
function Logger:logFailures(callback, ...)
    local results
    local arguments = { ... }
    local status, err = pcall(
        function()
            results = { callback(table.unpack(arguments)) }
        end
    )
    if (not status) then
        self:Error(err, "\n", debug.traceback())
    end
    return table.unpack(results)
end

---Clears the log file for tis logger
function Logger:clearLog()
    _FileUtil.clear(self:getFile())
end

---Clears every log in the log File
function Logger:clearAllLogs()
    _FileUtil.clear("/logs",true)
    _FileUtil.ensureDir("/logs/")
end

local function initFile()
    _FileUtil.ensureDir("/logs/")
end

local function init()
    initFile()
end

init()
return Logger
