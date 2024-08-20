--[[
    Author: Igromanru
    Date: 20.08.2024
    Mod Name: Unlimited Power
]]

-------------------------------------
-- Hotkey to toggle the mod on/off --
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
local ToggleModKey = Key.F8
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + L
local ToggleModKeyModifiers = {}
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "UnlimitedPower"
ModVersion = "1.0.0"
DebugMode = false

LogInfo("Starting mod initialization")

local IsModEnabled = not DebugMode
local function SetModState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        IsModEnabled = Enable
        local state = "Disabled"
        if IsModEnabled then
            state = "Enabled"
        end
        LogInfo("Mod state changed to: " .. state)
        AFUtils.ModDisplayTextChatMessage(state)
    end)
end

RegisterKeyBind(ToggleModKey, ToggleModKeyModifiers, function()
    SetModState(not IsModEnabled)
end)

local WasModEnabled = false
function BatteryTickHook(Context)
    local this = Context:get()

    if IsModEnabled then
        WasModEnabled = true
        LogDebug("[BatteryTick] called:")
        if this.ChangeableData then
            local liquidType = this.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109
            local liquidLevel = this.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A
            LogDebug("Liquid type: " .. liquidType)
            LogDebug("LiquidLevel: " .. liquidLevel)
            if liquidType == 0 or liquidLevel < this.MaxBattery then
                this.FreezeBatteryDrain = true
                this.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109 = AFUtils.LiquidType.Power
                this.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A = this.MaxBattery
                LogDebug("Set Liquid type: " .. this.ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
                LogDebug("Set LiquidLevel: " .. this.ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
            end
        else
            LogInfo("Warning: ChangeableData isn't valid!")
        end
        LogDebug("------------------------------")
    elseif WasModEnabled and this.FreezeBatteryDrain == true then
        LogDebug("[BatteryTick] called:")
        LogDebug("FreezeBatteryDrain was enabled, turning off")
        this.FreezeBatteryDrain = false
        LogDebug("------------------------------")
    end
end

local IsBatteryTickHooked = false
local function HookBatteryTick()
    if not IsBatteryTickHooked then
        RegisterHook("/Game/Blueprints/DeployedObjects/Misc/Deployed_Battery_ParentBP.Deployed_Battery_ParentBP_C:BatteryTick", BatteryTickHook)
        IsBatteryTickHooked = true
    end
end

-- For hot reload
if DebugMode then
    HookBatteryTick()
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(Context, NewPawn)
    LogDebug("[ClientRestart] called:")
    HookBatteryTick()
    LogDebug("------------------------------")
end)

LogInfo("Mod loaded successfully")
