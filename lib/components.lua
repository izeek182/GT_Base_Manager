---@class CompmonentCore
---@field address string Address of Compmonent
---@field slot string slot of Compmonent
---@field type string type of Compmonent

---@class Modem : CompmonentCore
---@field isWireless fun():boolean
---@field maxPacketSize fun():number
---@field isOpen fun(port: number):boolean
---@field open fun(port: number):boolean
---@field close fun(port:number|nil):boolean
---@field send fun(address:string,port:number,...:string|number):boolean
---@field broadcast fun(port:number,data:string|number):boolean 
---@field getStrength fun():number
---@field setStrength fun(value:number):number
---@field getWakeMessage fun():string
---@field setWakeMessage fun(message:string,fuzzy:boolean|nil):string

---@class Tunnel : CompmonentCore
---@field send fun(...:any)
---@field maxPacketSize fun():number
---@field getChannel fun():string
---@field getWakeMessage fun():string
---@field setWakeMessage fun(message: string,fuzzy:boolean|nil)

---@class BeeKeeperUpgrade : CompmonentCore
---@field addIndustrialUpgrade fun(side:number):boolean -- Tries to add industrial upgrade from the selected slot to industrial apiary at the given side.,
---@field analyze fun(honeyslot:number):boolean -- Analyzes bee in selected slot, uses honey from the specified slot.,
---@field canWork fun(side:number):boolean -- Checks if current bee in the apiary at the specified side can work now.,
---@field getBeeProgress fun(side:number):number -- Get current progress percent for the apiary at the specified side.,
---@field getIndustrialUpgrade fun(side:number, slot: number):table -- Get industrial upgrade in the given slot of the industrial apiary at the given side.,
---@field removeIndustrialUpgrade fun(side:number, slot: number):boolean -- Remove industrial upgrade from the given slot of the industrial apiary at the given side.,
---@field swapDrone fun(side:number):boolean -- Swap the drone from the selected slot with the apiary at the specified side.,
---@field swapQueen fun(side:number):boolean -- Swap the queen from the selected slot with the apiary at the specified side.,

---@class cpuClass
---@field activeItems fun():table -- Get currently crafted items.,
---@field cancel fun():boolean -- Cancel this CPU current crafting job.,
---@field finalOutput fun():table -- Get crafting final output.,
---@field isActive fun():boolean -- Is cpu active?,
---@field isBusy fun():boolean -- Is cpu busy?,
---@field pendingItems fun():table -- Get pending items.,
---@field storedItems fun():table -- Get stored items.,

---@class cpuTable
---@field cpu cpuClass cpuClass
---@field busy boolean if the CPU is currently in use
---@field type string always userdata
---@field name string Name of the crafting CPU
---@field storage number Amount of storage space
---@field coprocessors number number of CoProcessors

---@class craftableTable
---@field getItemStack fun():table -- Returns the item stack representation of the crafting result.,
---@field request fun(amount:integer,prioritizePower:boolean,cpuName:string):userdata -- Requests the item to be crafted, returning an object that allows tracking the crafting status.,
---@field type string

---@class liquidStorage
---@field amount integer
---@field hasTag boolean
---@field isCraftable boolean
---@field label string 
---@field name string

---@class ItemStack
---@field damage number
---@field hasTag boolean
---@field isCraftable boolean
---@field label string
---@field maxDamage number
---@field name string
---@field size number

---@class ME_Upgrade : CompmonentCore
---@field allItems fun ():userdata -- Get an iterator object for the list of the items in the network.,
---@field getAvgPowerInjection fun ():number -- Get the average power injection into the network.,
---@field getAvgPowerUsage fun ():number -- Get the average power usage of the network.,
---@field getCpus fun ():cpuTable[] -- Get a list of tables representing the available CPUs in the network.,
---@field getCraftables fun (filter:table?):craftableTable[] -- Get a list of known item recipes. These can be used to issue crafting requests.,
---@field getFluidsInNetwork fun ():table -- Get a list of the stored fluids in the network.,
---@field getIdlePowerUsage fun ():number -- Get the idle power usage of the network.,
---@field getItemsInNetwork fun (filter:table?):ItemStack[] -- Get a list of the stored items in the network.,
---@field getMaxStoredPower fun ():number -- Get the maximum stored power in the network.,
---@field getStoredPower fun ():number -- Get the stored power in the network. ,
---@field isLinked fun ():boolean -- Return true if the card is linked to your ae network.,
---@field requestFluids fun (database:string,entry:number,amount:integer?):number -- Get fluid from your ae system.,
---@field requestItems fun (database:string,entry:number,amount:integer?):number -- Get items from your ae system.,
---@field sendFluids fun (amount:integer?):number -- Transfer selected fluid to your ae system.,
---@field sendItems fun (amount:integer?):number -- Transfer selected items to your ae system.,
---@field store fun (filter:table,dbAddress:string,startSlot:number?,count:number?):boolean -- Store items in the network matching the specified filter in the database with the specified address.,

---@class inventory_controller:CompmonentCore
---@field areStacksEquivalent fun(side:number, slotA:number, slotB:number):boolean -- Get whether the items in the two specified slots of the inventory on the specified side of the device are equivalent (have shared OreDictionary IDs).,
---@field compareStackToDatabase fun(side:number, slot:number, dbAddress:string, dbSlot:number, checkNBT:boolean?):boolean -- Compare an item in the specified slot in the inventory on the specified side with one in the database with the specified address.,
---@field compareStacks fun(side:number, slotA:number, slotB:number, checkNBT:boolean?):boolean -- Get whether the items in the two specified slots of the inventory on the specified side of the device are of the same type.,
---@field compareToDatabase fun(slot:number, dbAddress:string, dbSlot:number, checkNBT:boolean?):boolean -- Compare an item in the specified slot with one in the database with the specified address.,
---@field dropIntoItemInventory fun(inventorySlot:number, slot:number, count:number?):number -- Drops an item into the specified slot in the item inventory.,
---@field dropIntoSlot fun(facing:number, slot:number, count:number?, fromSide:number?):boolean -- Drops the selected item stack into the specified slot of an inventory.,
---@field equip fun():boolean -- Swaps the equipped tool with the content of the currently selected inventory slot.,
---@field getAllStacks fun(side:number):userdata -- Get a description of all stacks in the inventory on the specified side of the device.,
---@field getInventoryName fun(side:number):string -- Get the the name of the inventory on the specified side of the device.,
---@field getInventorySize fun(side:number):number -- Get the number of slots in the inventory on the specified side of the device.,
---@field getItemInventorySize fun(slot:number):number -- The size of an item inventory in the specified slot.,
---@field getSlotMaxStackSize fun(side:number, slot:number):number -- Get the maximum number of items in the specified slot of the inventory on the specified side of the device.,
---@field getSlotStackSize fun(side:number, slot:number):number -- Get number of items in the specified slot of the inventory on the specified side of the device.,
---@field getStackInInternalSlot fun(slot:number?):ItemStack -- Get a description of the stack in the specified slot or the selected slot.,
---@field getStackInSlot fun(side:number, slot:number):ItemStack -- Get a description of the stack in the inventory on the specified side of the device.,
---@field getUpgradeContainerTier fun(slot:number):number -- get upgrade container tier at the given slot.,
---@field getUpgradeContainerType fun(slot:number):string -- get upgrade container type at the given slot.,
---@field installUpgrade fun(slot:number?):boolean -- Swaps the installed upgrade in the slot (1 by default) with the content of the currently selected inventory slot.,
---@field isEquivalentTo fun(otherSlot:number):boolean -- Get whether the stack in the selected slot is equivalent to the item in the specified slot (have shared OreDictionary IDs).,
---@field setStackDisplayName fun(side:number, slot:number, label:string):boolean -- Change the display name of the stack in the inventory on the specified side of the device.,
---@field store fun(side:number, slot:number, dbAddress:string, dbSlot:number):boolean -- Store an item stack description in the specified slot of the database with the specified address.,
---@field storeInternal fun(slot:number, dbAddress:string, dbSlot:number):boolean -- Store an item stack description in the specified slot of the database with the specified address.,
---@field suckFromItemInventory fun(inventorySlot:number, slot:number, count:number?):number -- Sucks an item out of the specified slot in the item inventory.,
---@field suckFromSlot fun(facing:number, slot:number, count:number?, fromSide:number?):boolean -- Sucks items from the specified slot of an inventory.,

---@class redstone_controller : CompmonentCore
---@field getBundledInput fun(side:number?, color:number?):number|table -- Fewer params returns set of inputs,
---@field getBundledOutput fun(side:number?, color:number?):number|table -- Fewer params returns set of outputs,
---@field getComparatorInput fun(side:number):number -- Get the comparator input on the specified side.,
---@field getInput fun(side:number?):number|table -- Get the redstone input (all sides, or optionally on the specified side),
---@field getOutput fun(side:number?):number|table -- Get the redstone output (all sides, or optionally on the specified side),
---@field getWakeThreshold fun():number -- Get the current wake-up threshold.,
---@field getWirelessFrequency fun():number -- Get the currently set wireless redstone frequency.,
---@field getWirelessInput fun():number -- Get the wireless redstone input.,
---@field getWirelessOutput fun():boolean -- Get the wireless redstone output.,
---@field setBundledOutput fun(side:number?, color:number?, value:number|table):number or table --  Fewer params to assign set of outputs. Returns previous values,
---@field setOutput fun(side:number?, value:number|table):number or table --  Set the redstone output (all sides, or optionally on the specified side). Returns previous values,
---@field setWakeThreshold fun(threshold:number):number -- Set the wake-up threshold.,
---@field setWirelessFrequency fun(frequency:number):number -- Set the wireless redstone frequency to use.,
---@field setWirelessOutput fun(value:boolean):boolean -- Set the wireless redstone output.,

---@class robot : CompmonentCore
---@field compare fun(side:number, fuzzy:boolean?):boolean -- Compare the block on the specified side with the one in the selected slot. Returns true if equal.,
---@field compareFluid fun(side:number , tank:number?):boolean -- Compare the fluid in the selected tank with the fluid in the specified tank on the specified side. Returns true if equal.,
---@field compareFluidTo fun(index:number):boolean -- Compares the fluids in the selected and the specified tank. Returns true if equal.,
---@field compareTo fun(otherSlot:number, checkNBT:boolean?):boolean -- Compare the contents of the selected slot to the contents of the specified slot.,
---@field count fun(slot:number?):number -- Get the number of items in the specified slot, otherwise in the selected slot.,
---@field detect fun(side:number):boolean, string -- Checks the contents of the block on the specified sides and returns the findings.,
---@field drain fun(side:boolean, amount:number?):boolean, number|string -- Drains the specified amount of fluid from the specified side. Returns the amount drained, or an error message.,
---@field drop fun(side:number, count:number?):boolean -- Drops items from the selected slot towards the specified side.,
---@field durability fun():number -- Get the durability of the currently equipped tool.,
---@field fill fun(side:number, amount:number?):boolean, number|string -- Eject the specified amount of fluid to the specified side. Returns the amount ejected or an error message.,
---@field getLightColor fun():number -- Get the current color of the activity light as an integer encoded RGB value (0xRRGGBB).,
---@field inventorySize fun():number -- The size of this device's internal inventory.,
---@field move fun(direction:number):boolean -- Move in the specified direction.,
---@field name fun():string -- Get the name of the agent.,
---@field place fun(side:number, face:number?, sneaky:boolean?):boolean -- Place a block towards the specified side. The `face' allows a more precise click calibration, and is relative to the targeted blockspace.,
---@field select fun(slot:number?):number -- Get the currently selected slot; set the selected slot if specified.,
---@field selectTank fun(index:number?):number -- Select a tank and/or get the number of the currently selected tank.,
---@field setLightColor fun(value:number):number -- Set the color of the activity light to the specified integer encoded RGB value (0xRRGGBB).,
---@field space fun(slot:number?):number -- Get the remaining space in the specified slot, otherwise in the selected slot.,
---@field suck fun(side:number, count:number?):boolean -- Suck up items from the specified side.,
---@field swing fun(side:number, face:number?, sneaky:boolean?):boolean, string -- Perform a 'left click' towards the specified side. The `face' allows a more precise click calibration, and is relative to the targeted blockspace.,
---@field tankCount fun():number -- The number of tanks installed in the device.,
---@field tankLevel fun(index:number?):number -- Get the fluid amount in the specified or selected tank.,
---@field tankSpace fun(index:number?):number -- Get the remaining fluid capacity in the specified or selected tank.,
---@field transferFluidTo fun(index:number, count:number?):boolean -- Move the specified amount of fluid from the selected tank into the specified tank.,
---@field transferTo fun(toSlot:number, amount:number?):boolean -- Move up to the specified amount of items from the selected slot into the specified slot.,
---@field turn fun(clockwise:boolean):boolean -- Rotate in the specified direction.,
---@field use fun(side:number, face:number?, sneaky:boolean?, duration:number?):boolean, string -- Perform a 'right click' towards the specified side. The `face' allows a more precise click calibration, and is relative to the targeted blockspace.},

---@class tank_controller
---@field drain fun(amount:number?):boolean -- Transfers fluid from a tank in the selected inventory slot to the selected tank.,
---@field fill fun(amount:number?):boolean -- Transfers fluid from the selected tank to a tank in the selected inventory slot.,
---@field getFluidInInternalTank fun(tank:number):table -- Get a description of the fluid in the tank in the specified slot or the selected slot.,
---@field getFluidInTank fun(side:number , tank:number?):table -- Get a description of the fluid in the the specified tank on the specified side.,
---@field getFluidInTankInSlot fun(slot:number?):table -- Get a description of the fluid in the tank item in the specified slot or the selected slot.,
---@field getTankCapacity fun(side:number , tank:number?):number -- Get the capacity of the specified tank on the specified side.,
---@field getTankCapacityInSlot fun(slot:number?):number -- Get the capacity of the tank item in the specified slot of the robot or the selected slot.,
---@field getTankCount fun(side:number):number -- Get the number of tanks available on the specified side.,
---@field getTankLevel fun(side:number , tank:number?):number -- Get the amount of fluid in the specified tank on the specified side.,
---@field getTankLevelInSlot fun(slot:number?):number -- Get the amount of fluid in the tank item in the specified slot or the selected slot.,


---@class BeeSpeciesTraits
---@field humidity string Nominal humidity 
---@field temperature string Nominal Tempeture
---@field uid string Minecraft Id of this bee
---@field name string The CommonName of this Bee

---@class BeeGeneticTraits
---@field speed number The rate at witch this bee process resources
---@field flowerProvider string The type of flower required for this bee
---@field territory table the size of the area the bee will apply effects/pollinate
---@field nocturnal boolean Will this bee work through the night
---@field species BeeSpeciesTraits The species specific data
---@field effect string This is the effect the Bee produces in its area
---@field flowering integer This is the pollination rate of the bee(how quickly the bee "spreads" its flowers)
---@field tolerantFlyer boolean Will this bee work in the rain
---@field fertility integer The number of drones this bee will produce
---@field lifespan integer an Integer representing the length of this bees life
---@field temperatureTolerance string String Representing the humidity tolerance of this bee 
---@field caveDwelling boolean number of CoProcessors
---@field humidityTolerance string String Representing the humidity tolerance of this bee 

---@class BeeIndividualTraits
---@field canSpawn boolean true if its a queen
---@field generation integer This is the number of generations old this bee is, 0 for drones
---@field isAnalyzed boolean true of the bee is Analyzed and can bee inspected
---@field isAlive boolean always true? 
---@field isNatural boolean true of born in nature? 
---@field health integer the health of the bee
---@field active BeeGeneticTraits the active genetic traits of the bee
---@field type string always "bee"
---@field hasEffect boolean recipe in the name
---@field inactive BeeGeneticTraits inactive trait
---@field displayName string species display name
---@field isSecret boolean the visibility of the traits
---@field ident string the minecraft Id of the species
---@field maxHealth integer the max health of the bee


---@class BeeStack : ItemStack
---@field individual BeeIndividualTraits the stats of the bee
