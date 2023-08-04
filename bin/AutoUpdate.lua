
-- Local Files --------------------------
--      /cgf/NetworkVersion
--          table{installedprograms={},program={version,clients}}
--      /cgf/programDepenancies
--          table{program = {depenantCnt=int(number of progams depenant on this program), dependees={Programs that this program dependends on}}}

local git    = require("gitInstall")
local thread = require("thread")


local function checkLocalVersions()
    print("Testa")
    while true do
        print("TestB")
        git:updateLibs()
        os.sleep(1)
    end
end

local function install()
    git:install("AutoUpdate")
end


local function init()
    install()
    local t = thread.create(checkLocalVersions)
    if(t == nil) then
        print("thread failed to create")
    end
    print("thread Created")
    os.sleep(10)
    for key, value in pairs(t) do
    end
    t:detach()
end

init()
-- Sudo Code --------------------------
-- Request Repo Version Information,
-- Read localhosts Used Versions hosts
-- cross referance ve3rsions in repo
-- pull updated libs + program files,
-- Distribute to the clients on network
-- On confirmation, record new version number locally


