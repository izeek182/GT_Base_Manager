if (_FileUtil == nil) then
    _FileUtil = {
    }
    local fs = require("filesystem")
    local io = require("io")

    function _FileUtil.append(file,...)
        local file = io.open(file,"a")
        if not (file == nil) then
            file:write(...)
            file:close()
        end
    end

    function _FileUtil.size(file)
        return fs.size(file)
    end

    function _FileUtil.clear(file,force)
        if(fs.isDirectory(file) and not force) then
            error("attempted to delete a directory rather then a file pass true to force deletion")
        else
            fs.remove(file)
        end        
    end

    function _FileUtil.reader(file)
        return io.open(file,"r")
    end

    function _FileUtil.ensureDir(dir)
        if fs.isDirectory(dir) then
            return
        else
            fs.makeDirectory(dir)
        end
    end

    function _FileUtil.rm(file)
        if(fs.exists(file)) then
            fs.remove(file)
        end
    end
end