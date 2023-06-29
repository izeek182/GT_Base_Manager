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
        RTD             = 1, 
        UDP             = 2,
    }

    _NetDefs.timeOut = {
        resend = 10,
        sendHB = 10,
        cold   = 50,
    }
    _NetDefs.events = {
        syncResponse = "NetSynResponse"
    }
    _NetDefs.START = 0
    _NetDefs.END   = 420
    _NetDefs.HostName = "NA"
    
end