-- This will be a logging utility capable of logging to File and broadcasting over the network
if (_LogUtil == nil) then 
    _LogUtil = {
        loggerCount = 0
    }
    _LogLevel = {
        trace = 1,
        info = 2,
        debug = 3,
        error = 4,
        noLog = 10,
        tostring = function (level)
            if      level <  1 then
                return "-----"
            elseif  level == 1 then
                return "trace"
            elseif  level == 2 then
                return "info "
            elseif  level == 3 then
                return "debug"
            elseif  level == 4 then
                return "error"
            elseif  level > 4 then
                return "VITAL"
            end
        end
    }

    local loggers = {}

    if(_NetUtil == nil) then
        pcall(require,"netUtils")
    end
    
    if(_FileUtil == nil) then
        pcall(require,"fileUtils")
    end

    local function formatLog(logID,level,...)
        local log = "[".._LogLevel.tostring(level).."]["..loggers[logID].name.."]"
        for _, value in pairs({...}) do
            log=log..tostring(value)
        end
        return log
    end

    local function broadcastLog(str)
        _NetUtil.broadcast(_NetDefs.portEnum.logger,str,_NetDefs.HostName)
    end

    local function printLog(str)
        print(str)
    end

    local function fileLog(str)
        -- TODO implment file logging
    end

    function _LogUtil.newLogger(FileName,ConLevel,FileLevel,NetLevel)
        local cnt = _LogUtil.loggerCount + 1
        local logger = {
            name=FileName,
            cl=ConLevel,
            fl=FileLevel,
            nl=NetLevel
        }
        loggers[cnt] = logger
        _LogUtil.loggerCount = cnt
        return cnt
    end

    function _LogUtil.log(logID,level,...)
        local log = loggers[logID]
        local logstr = formatLog(logID,level,...)
        if(log.cl <= level)then
            printLog(logstr)
        end
        if(log.fl <= level)then
            fileLog(logstr)
        end
        if(log.nl <= level)then
            broadcastLog(logstr)
        end
    end

    function _LogUtil.trace(logID,...)
        _LogUtil.log(logID,_LogLevel.trace,...)
    end

    function _LogUtil.info(logID,...)
        _LogUtil.log(logID,_LogLevel.info,...)
    end

    function _LogUtil.debug(logID,...)
        _LogUtil.log(logID,_LogLevel.debug,...)
    end

    function _LogUtil.error(logID,...)
        _LogUtil.log(logID,_LogLevel.error,...)
    end

    function _LogUtil.setNetLog(logID,level)
        loggers[logID].nl = level
    end

    function _LogUtil.setFileLog(logID,level)
        loggers[logID].fl = level
    end

    function _LogUtil.setConsoleLog(logID,level)
        loggers[logID].cl = level
    end

    function _LogUtil.logFailures(logID,callback,...)
        local results
        local arguments = {...}
        local status,err = pcall(
            function ()
                results = {callback(table.unpack(arguments))}
            end
        )
        if(not status) then
            _LogUtil.log(logID,_LogLevel.error,err,"\n",debug.traceback())
        end
        return table.unpack(results)
    end

end