local Logger = require("logUtil")

local log = Logger:new("LoggerA",LogLevel.trace,LogLevel.trace,LogLevel.trace)
log:clearLog()

log:Trace("Trace Log")
log:Info("info Log")
log:Debug("debug Log")
log:Error("error Log")