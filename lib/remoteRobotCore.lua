local comp  = require("component")
local computer = require("computer")
local thread = require("thread")
if(_LogUtil == nil) then
    require("logUtils")
end

local ae    = comp.upgrade_me
local gen   = comp.generator
local db    = comp.database
local rb    = comp.robot

local _maintInterval = 10
local logID = _LogUtil.newLogger("Robot",_LogLevel.error,_LogLevel.trace,_LogLevel.noLog)
local generatorOn = true
local fuelSlot = rb.inventorySize()
local fuelSlotDb = 81
_LogUtil.trace(logID,"New Logger")

local function getEnergyLevel()
    return computer.energy() / computer.maxEnergy()
end

local function disableGenerator()
    gen.remove()
    generatorOn = false
    _LogUtil.info(logID,"disabled Generator")
end

local function enableGenrator()
    gen.insert()
    generatorOn = true
    _LogUtil.info(logID,"enabled Genrator")
end

local function topOffGen()
    local fuelCount = gen.count()
    if(fuelCount < 32)then
        local reserve = rb.count()
        local topOff = 64-(fuelCount+reserve)
        _LogUtil.info(logID,"Generator running low on fuel, adding ",topOff," more fuel from AE2")
        ae.requestItems(db.address,fuelSlotDb,topOff)
        reserve = rb.count()
        gen.insert(reserve - 1)
    end
end

local function CheckOverStockGen()
    local fuelTotal = gen.count() + rb.count()
    local fuelMax = 64
    if(not generatorOn)then
        fuelMax = 32
    end
    if (fuelTotal > fuelMax) then
        ae.sendItems(fuelTotal - fuelMax)
        _LogUtil.info(logID,"Generator has surplus fuel sending ",fuelTotal - fuelMax," back to AE2")
    end
end

local function maintainPowerLevel()
    local invSlot = rb.select()
    rb.select(fuelSlot)
    energyLevel = getEnergyLevel()
    if generatorOn and energyLevel > 0.9 then
        disableGenerator()
    elseif (not generatorOn) and energyLevel < 0.4 then
        enableGenrator()
    end
    if(generatorOn) then
        topOffGen()
    end
    CheckOverStockGen()
    rb.select(invSlot)
end

local function coreMaintaince()
    while true do
        _LogUtil.logFailures(logID,maintainPowerLevel)
        os.sleep(_maintInterval)
    end
end

local function init()
    _LogUtil.info(logID,"initial startup")
    local t = thread.create(coreMaintaince)
    if(t == nil) then
        _LogUtil.error(logID,"thread failed to create")
        return
    end
    t:detach() 
end

init()