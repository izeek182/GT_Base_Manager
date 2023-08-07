if(_NetDefs == nil) then 
    _NetDefs = {}

    _NetDefs.loggerEnum = {
        error = 0,
        info  = 1,
        toString = function(num)
            if num == _NetDefs.loggerEnum.error then
                return "Error"
            end
            if num == _NetDefs.loggerEnum.info then
                return "Info "
            end
        end
    }
    _NetDefs.hbEnum = {
        live    = 0,
        waiting = 1,
        overdue = 2
    }
    _NetDefs.remoteEnum = {
        server      = 0,
        componant   = 1,
        display     = 2,
        terminal    = 3
    }
    _NetDefs.portEnum = {
        logger          = 8,
        adp             = 20,
        ping            = 21,
        heartBeat       = 25,
        componantCmd    = 30,
        FTP             = 40,
        newSubscription = 50,
        subData         = 51,
        RDT_start       = 1000,
        RDT_end         = 65534
    }
    _NetDefs.pktTypes = {
        RDT             = 1,
        UDP             = 2,
    }
    local maxWinSz = 32
    _NetDefs.rdtConst = {
        maxWindowSize = maxWinSz,
        bufferSize = (maxWinSz) * 2,
    }

    _NetDefs.timming = {
        serviceInterval = 0.1,      -- Time between service calls (seconds)
        sendRate        = 0.5,      -- Time between sending packets from the que
        resendInterval  = 2,        -- Time since last Ack before resending Que (seconds)
        sendHBInterval  = 3,        -- Time since last transmuit before sending proof of life (seconds)
        coldInterval    = 10,       -- Time since last Ack before resending Que (seconds)
        sendRateInc     = -0.1,     -- Time change when increacing the rate general sending (seconds)
        sendRateDec     = 0.1,      -- Time change when decreasing the rate general sending (seconds)
    }

    function _NetDefs.reCalcTimeouts() 
        --timming measured in units of serviceInterval 
        _NetDefs.timeOut = {
            genSend = _NetDefs.timming.sendRate/_NetDefs.timming.serviceInterval,
            resend  = _NetDefs.timming.resendInterval/_NetDefs.timming.serviceInterval,
            sendHB  = _NetDefs.timming.sendHBInterval/_NetDefs.timming.serviceInterval,
            cold    = _NetDefs.timming.coldInterval  /_NetDefs.timming.serviceInterval,
        }
    end
    
    function _NetDefs.incSendRate()
        local t = _NetDefs.timming
        t.sendRate = t.sendRate + t.sendRateInc
        if t.sendRate < t.serviceInterval then
            t.sendRate = t.serviceInterval
        end
        _NetDefs.timming = t
        _NetDefs.reCalcTimeouts()
    end

    function _NetDefs.decSendRate()
        local t = _NetDefs.timming
        t.sendRate = t.sendRate + t.sendRateDec
        if t.sendRate < t.serviceInterval then
            t.sendRate = t.serviceInterval
        end
        _NetDefs.timming = t
        _NetDefs.reCalcTimeouts()
    end
    _NetDefs.reCalcTimeouts()
    -- these values may be adjusted over the course of opperation
    _NetDefs.congestionControl = {
        lossScaleDownFactor = 0.5,
        scaleUpRate = 0.25,
        maxPkt = 10
    }

    function _NetDefs.queTimeout()
        local cc = _NetDefs.congestionControl
        cc.maxPkt = cc.maxPkt * cc.lossScaleDownFactor
        if(cc.maxPkt < 1) then
            cc.maxPkt = 1
        end
        _NetDefs.congestionControl = cc
        _NetDefs.reCalcTimeouts()
    end

    function _NetDefs.ackedPacket() 
        local cc = _NetDefs.congestionControl
        cc.maxPkt = cc.maxPkt + cc.scaleUpRate
        _NetDefs.congestionControl = cc
        _NetDefs.reCalcTimeouts()
    end


    _NetDefs.events = {
        syncResponse = "NetSynResponse"
    }
    _NetDefs.START = 0
    _NetDefs.END   = 420
    _NetDefs.HostName = "NA"
    
end