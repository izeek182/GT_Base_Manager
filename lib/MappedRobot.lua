---@module "components"

---@class move 
---@field takeAction fun():boolean

---@class step : move
---@field takeAction fun():boolean

---@class turn : move 
---@field takeAction fun():boolean


---@class path 
---@field steps move[]

---@class SmartBot
---@field GoHome fun():boolean
---@field MoveTo fun(x:integer,y:integer):boolean
---@field remoteData fun(if:Interface,localAddress:string, remoteAddress:string, port:number, distance:number, l1Header:string, data):boolean
---@field broadcast fun(if:Interface,port:number, ...):boolean
---@field open fun(if:Interface,port:number):boolean
---@field close fun(if:Interface,port:number):boolean
---@field getPortStatus fun(if:Interface,port:number):boolean
---@field isWireless fun(if:Interface):boolean


