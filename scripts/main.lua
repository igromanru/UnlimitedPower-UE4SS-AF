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
local InfiniteBatteryCharge = false
---- Infinite Held Item Charge ------
local InfiniteHeldItemChargeKey = Key.F7
local InfiniteHeldItemChargeKeyModifiers = {}
local InfiniteHeldItemCharge = false
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "UnlimitedPower"
ModVersion = "2.1.0"
DebugMode = false

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

---@param Context AAbiotic_PlayerCharacter_C
---@param Success boolean
---@param ItemSlotInfo FAbiotic_InventoryItemSlotStruct
---@param ItemData FAbiotic_InventoryItemStruct
---@param Blueprint AAbiotic_Item_ParentBP_C
local function GetCurrentHeldItemHook(Context, Success, ItemSlotInfo, ItemData, Blueprint)
    local playerCharacter = Context:get()
    local success = Success:get()
    -- local itemSlotInfo = ItemSlotInfo:get()
    -- local itemData = ItemData:get()
    -- local blueprint = Blueprint:get()

    if success and IsModEnabled and InfiniteHeldItemCharge then
        AFUtils.FillHeldItemWithEnergy(playerCharacter)
    end
end

local function BatteryTickHook(Context)
    local deployedBattery = Context:get()

    if IsModEnabled and InfiniteBatteryCharge and deployedBattery.ChangeableData then
        local liquidType = deployedBattery.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109
        local liquidLevel = deployedBattery.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A
        if liquidType == AFUtils.LiquidType.None or not deployedBattery.FreezeBatteryDrain or liquidLevel < deployedBattery.MaxBattery then
            deployedBattery.FreezeBatteryDrain = true
            deployedBattery.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A = deployedBattery.MaxBattery
            if not AFUtils.IsEnergyLiquidType(liquidType) then
                deployedBattery.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109 = AFUtils.LiquidType.Energy
            end
            
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
