require("logUtils")


local loggerALvl = _LogLevel.trace
local loggerA = _LogUtil.newLogger("LoggerA",loggerALvl,loggerALvl,loggerALvl)


_LogUtil.log(loggerA,_LogLevel.trace,"Trace Log")
_LogUtil.log(loggerA,_LogLevel.info,"info Log")
_LogUtil.log(loggerA,_LogLevel.debug,"debug Log")
_LogUtil.log(loggerA,_LogLevel.error,"erro Log")
_LogUtil.log(loggerA,8,"Num Log")
