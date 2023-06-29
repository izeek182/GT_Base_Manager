require("netUtils")



local function printLog(_, _, _, _, _,log)
    print(log)
end

_NetUtil.open(_NetDefs.portEnum.logger,printLog)

while true do
    os.sleep(1)
end

