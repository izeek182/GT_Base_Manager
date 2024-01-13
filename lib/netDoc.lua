---@module "components"

---@class Interface
---@field protected status boolean the status of the interface `true` if up
---@field send fun(if:Interface,mac:string, port:integer, ...:any):boolean Sends 
---@field remoteData fun(if:Interface,localAddress:string, remoteAddress:string, port:number, distance:number, l1Header:string, data):boolean
---@field broadcast fun(if:Interface,port:number, ...):boolean
---@field open fun(if:Interface,port:number):boolean
---@field close fun(if:Interface,port:number):boolean
---@field getPortStatus fun(if:Interface,port:number):boolean
---@field isWireless fun(if:Interface):boolean


---@class L2Frame
---@field CMD integer The Command Id of the Packet 1 for data 2 for rdp?
---@field SenderMac string UUID of the sender's InterfaceCard
---@field ReceiverMac string UUID of the receiver's InterfaceCard
---@field Data string the Rest of the packet


---@class L3Packet
---@field CMD integer The Command Id of the Packet
---@field SenderIp string UUID of the sender's Computer
---@field SenderPort integer Port Packet was sent from
---@field ReceiverIp string UUID of the receiver's Computer
---@field ReceiverPort integer Port Packet was sent to




