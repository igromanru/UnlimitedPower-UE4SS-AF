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
---- Infinite Gear Charge ------
local InfiniteGearChargeKey = Key.F7
local InfiniteGearChargeKeyModifiers = {}
local InfiniteGearCharge = true
-- If set to true, the equipment of all players will be charged
local InfiniteGearChargeForAll = false
-- If set to true, only the Held Item will be charged, otherwise Held Item and equipped gear
local ApplyToHeldItemOnly = false
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "UnlimitedPower"
ModVersion = "2.3.0"
DebugMode = true

LogInfo("Starting mod initialization")

local IsModEnabled = true

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
            
            LogDebug("[BatteryTick] called:")
            LogDebug("Liquid type: " .. liquidType)
            LogDebug("LiquidLevel: " .. liquidLevel)
            LogDebug("Set Liquid type: " .. deployedBattery.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
            LogDebug("Set LiquidLevel: " .. deployedBattery.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
            LogDebug("FreezeBatteryDrain: " .. tostring(deployedBattery.FreezeBatteryDrain))
            LogDebug("------------------------------")
        end
    end
end

local IsBatteryTickHooked = false
local BatteryTickFuncName = "/Game/Blueprints/DeployedObjects/Misc/Deployed_Battery_ParentBP.Deployed_Battery_ParentBP_C:BatteryTick"
local function TryHookBatteryTick()
    if not IsBatteryTickHooked then
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

---@param playerCharacter AAbiotic_PlayerCharacter_C
local function FillPlayersGear(playerCharacter)
    AFUtils.FillHeldItemWithEnergy(playerCharacter)
    if not ApplyToHeldItemOnly then
        AFUtils.FillAllEquippedItemsWithEnergy(playerCharacter)
    end
end

local function ChargeGear()
    if InfiniteGearCharge then
        ExecuteInGameThread(function()
            if InfiniteGearChargeForAll then
                local gameState = AFUtils.GetSurvivalGameState()
                if gameState:IsValid() then
                    for i = 1, #gameState.PlayerArray do
                        local playerState = gameState.PlayerArray[i]
                        if playerState:IsValid() then
                            local playerCharacter = playerState.PawnPrivate ---@cast playerCharacter AAbiotic_PlayerCharacter_C
                            FillPlayersGear(playerCharacter)
                        end
                    end
                end
            else
                FillPlayersGear(AFUtils.GetMyPlayer())
            end
        end)
    end
end

-- For hot reload
if DebugMode then
    InfiniteBatteryCharge = false
    InfiniteGearCharge = false
    TryHookBatteryTick()
end

LoopAsync(500, function()
    if IsModEnabled then
        TryHookBatteryTick()
        ChargeGear()
    end
    return false
end)

local function SetInfiniteBatteryChargeState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        InfiniteBatteryCharge = Enable
        local state = "Disabled"
        local warningColor =  AFUtils.CriticalityLevels.Red
        if InfiniteBatteryCharge then
            state = "Enabled"
            warningColor =  AFUtils.CriticalityLevels.Green
        end
        local stateMessage = "Infinite Battery Charge: " .. state
        LogInfo(stateMessage)
        AFUtils.ModDisplayTextChatMessage(stateMessage)
        AFUtils.ClientDisplayWarningMessage(stateMessage, warningColor)
    end)
end

RegisterKeyBind(InfiniteBatteryChargeKey, InfiniteBatteryChargeKeyModifiers, function()
    SetInfiniteBatteryChargeState(not InfiniteBatteryCharge)
end)

local function SetInfiniteGearChargeState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        InfiniteGearCharge = Enable
        local state = "Disabled"
        local warningColor =  AFUtils.CriticalityLevels.Red
        if InfiniteGearCharge then
            state = "Enabled"
            warningColor =  AFUtils.CriticalityLevels.Green
        end
        local stateMessage = "Infinite Gear Charge: " .. state
        LogInfo(stateMessage)
        AFUtils.ModDisplayTextChatMessage(stateMessage)
        AFUtils.ClientDisplayWarningMessage(stateMessage, warningColor)
    end)
end

RegisterKeyBind(InfiniteGearChargeKey, InfiniteGearChargeKeyModifiers, function()
    SetInfiniteGearChargeState(not InfiniteGearCharge)
end)

LogInfo("Mod loaded successfully")
