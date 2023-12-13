if(_NetDefs == nil) then 
    _NetDefs = {}

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

    _NetDefs.signals = {
        interface_msg = "if_msg",   -- if_msg  [interfaceNum] [port] [data]
        socket_opend  = "skt_new",  -- skt_new [skt_listener_id] [new_skt_id] [local_port] [local_ip] [remote_port] [remote_ip] 
        socket_msg    = "skt_msg",  -- skt_msg [skt_id] [data]
    }

    _NetDefs.portEnum = {
        routing         = 1,
        dns             = 2,
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