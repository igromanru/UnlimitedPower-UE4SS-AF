--[[
    Author: Igromanru
    Date: 20.08.2024
    Mod Name: Unlimited Power
]]

-------------------------------------
---------- Configurations -----------
-------------------------------------
-- Possible Key value: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
-- ModifierKey alues: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + {Key]

----- Infinite Battery Charge -------
local InfiniteBatteryChargeKey = Key.F8
local InfiniteBatteryChargeKeyModifiers = {}
local InfiniteBatteryCharge = true
---- Infinite Held Item Charge ------
local InfiniteHeldItemChargeKey = Key.F7
local InfiniteHeldItemChargeKeyModifiers = {}
local InfiniteHeldItemCharge = true
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "UnlimitedPower"
ModVersion = "2.0.1"
DebugMode = true

LogInfo("Starting mod initialization")

local IsModEnabled = true

local function SetInfiniteBatteryChargeState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        InfiniteBatteryCharge = Enable
        local state = "Disabled"
        if InfiniteBatteryCharge then
            state = "Enabled"
        end
        LogInfo("Infinite Battery Charge state changed to: " .. state)
        AFUtils.ModDisplayTextChatMessage("Infinite Battery Charge: " .. state)
    end)
end

RegisterKeyBind(InfiniteBatteryChargeKey, InfiniteBatteryChargeKeyModifiers, function()
    SetInfiniteBatteryChargeState(not InfiniteBatteryCharge)
end)

local function SetInfiniteHeldItemChargeState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        InfiniteHeldItemCharge = Enable
        local state = "Disabled"
        if InfiniteHeldItemCharge then
            state = "Enabled"
        end
        LogInfo("Infinite Held Item Charge state changed to: " .. state)
        AFUtils.ModDisplayTextChatMessage("Infinite Held Item Charge: " .. state)
    end)
end

RegisterKeyBind(InfiniteHeldItemChargeKey, InfiniteHeldItemChargeKeyModifiers, function()
    SetInfiniteHeldItemChargeState(not InfiniteHeldItemCharge)
end)

local function GetCurrentHeldItemHook(Context, Success, ItemSlotInfo, ItemData, Blueprint)
    local playerCharacter = Context:get()
    local success = Success:get()
    -- local itemSlotInfo = ItemSlotInfo:get()
    -- local itemData = ItemData:get()
    local blueprint = Blueprint:get() -- AAbiotic_Item_ParentBP_C

    if success and IsModEnabled and InfiniteHeldItemCharge then
        if AFUtils.SetItemLiquidLevel(blueprint, AFUtils.LiquidType.Power) then
            local inventory = playerCharacter.CurrentHotbarSlotSelected.Inventory_2_B69CD60741EFD551F09ED5AFF44B1E46
            local slotIndex = playerCharacter.CurrentHotbarSlotSelected.Index_5_6BDC7B3944A5DE0B319F9FA20720872F
            -- LogDebug("CurrentHotbarSlotSelected.Index: " .. slotIndex)
            if inventory:IsValid() and inventory.CurrentInventory and #inventory.CurrentInventory > slotIndex then
                local luaIndex = slotIndex + 1
                -- LogDebug("Lua index: " .. luaIndex)
                -- LogDebug("CurrentInventory:GetArrayNum: " .. #inventory.CurrentInventory)
                local inventoryItemSlotStruct = inventory.CurrentInventory[luaIndex]
                if inventoryItemSlotStruct:IsValid() then
                    local itemDataTable = inventoryItemSlotStruct.ItemDataTable_18_BF1052F141F66A976F4844AB2B13062B
                    if itemDataTable.RowName and itemDataTable.RowName:GetComparisonIndex() > 0 then
                        -- LogDebug("InventoryItemSlotStruct.RowName: " .. itemDataTable.RowName:ToString())
                        -- LogDebug("InventoryItemSlotStruct.ChangeableData.LiquidLevel: " .. inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
                        -- LogDebug("InventoryItemSlotStruct.ChangeableData.CurrentLiquid: " .. inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
                        inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A = blueprint.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A
                        inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109 = blueprint.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109
                        -- LogDebug("New LiquidLevel: " .. inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
                        -- LogDebug("New CurrentLiquid: " .. inventoryItemSlotStruct.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
                    end
                end
            end
        end
    end
end

local function BatteryTickHook(Context)
    local deployedBattery = Context:get()

    if IsModEnabled and InfiniteBatteryCharge and deployedBattery.ChangeableData then
        local liquidType = deployedBattery.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109
        local liquidLevel = deployedBattery.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A
        if liquidType == 0 or not deployedBattery.FreezeBatteryDrain or liquidLevel < deployedBattery.MaxBattery then
            deployedBattery.FreezeBatteryDrain = true
            deployedBattery.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109 = AFUtils.LiquidType.Power
            deployedBattery.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A = deployedBattery.MaxBattery
            
            -- this["Update Current Item Data"]()

            -- LogDebug("[BatteryTick] called:")
            -- LogDebug("Liquid type: " .. liquidType)
            -- LogDebug("LiquidLevel: " .. liquidLevel)
            -- LogDebug("Set Liquid type: " .. this.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
            -- LogDebug("Set LiquidLevel: " .. this.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
            -- LogDebug("FreezeBatteryDrain: " .. tostring(this.FreezeBatteryDrain))
            -- LogDebug("------------------------------")
        end
    end
end


local IsGetCurrentHeldItemHooked = false
local function HookGetCurrentHeldItem()
    if not IsGetCurrentHeldItemHooked then
        RegisterHook("/Game/Blueprints/Characters/Abiotic_PlayerCharacter.Abiotic_PlayerCharacter_C:GetCurrentHeldItem", GetCurrentHeldItemHook)
        IsGetCurrentHeldItemHooked = true
    end
end

local IsBatteryTickHooked = false
local function TryHookBatteryTick()
    if not IsBatteryTickHooked then
        local BatteryTickFuncName = "/Game/Blueprints/DeployedObjects/Misc/Deployed_Battery_ParentBP.Deployed_Battery_ParentBP_C:BatteryTick"
        local BatteryTickFunction = StaticFindObject(BatteryTickFuncName)
        if BatteryTickFunction and BatteryTickFunction:IsValid() then
            RegisterHook(BatteryTickFuncName, BatteryTickHook)
            IsBatteryTickHooked = true
        -- else
        --     LogDebug("TryHookBatteryTick: Function BatteryTick doesn't yet exist, hook skipped")
        end
    end
    return IsBatteryTickHooked
end

-- For hot reload
if DebugMode then
    HookGetCurrentHeldItem()
    TryHookBatteryTick()
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(Context, NewPawn)
    LogDebug("[ClientRestart] called:")
    HookGetCurrentHeldItem()
    LoopAsync(2000, TryHookBatteryTick)
    LogDebug("------------------------------")
end)

LogInfo("Mod loaded successfully")
