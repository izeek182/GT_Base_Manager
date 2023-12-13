---@module "components"
---@module "components"

---@class BeeBreeder
---@field IsPureBreed fun(bee:BeeStack):integer Returns A integer representing the quality of a Bee  
---@field remoteData fun(if:Interface,localAddress:string, remoteAddress:string, port:number, distance:number, l1Header:string, data):boolean
---@field broadcast fun(if:Interface,port:number, ...):boolean
---@field open fun(if:Interface,port:number):boolean
---@field close fun(if:Interface,port:number):boolean
---@field getPortStatus fun(if:Interface,port:number):boolean
---@field isWireless fun(if:Interface):boolean
local Interface = {status = false}


