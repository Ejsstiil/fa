----------------------------------------------------------------------
-- File     : /lua/editor/AMPlatoonHelperFunctions.lua
-- Author(s): Dru Staltman
-- Summary  : Functions to help with AM Platoons
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------
local ScenarioFramework = import('/lua/scenarioframework.lua')

---@param time number
---@param name string
function UnlockTimer(time, name)
    WaitSeconds( time )
    ScenarioInfo.AMLockTable[name] = false
end

---@param pName string
---@param time number
function PlatoonDeathUnlockThread( pName, time )
    if time > 0 then
        WaitSeconds(time)
    end
    ScenarioInfo.AMLockTable[pName] = false
end

---@param brain AIBrain
---@param platoon Platoon
function PlatoonDeathUnlockTimer( brain, platoon )
    local time = platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty] or platoon.PlatoonData.LockTimer or 0
    ForkThread(PlatoonDeathUnlockThread, platoon.PlatoonData.BuilderName, time )
end

--- AMLockPlatoon = AddFunction
---@param platoon Platoon
function AMLockPlatoon(platoon)
    if not ScenarioInfo.AMLockTable then
        ScenarioInfo.AMLockTable = {}
    end
    ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = true
end

--- PBMLockAndUnlock = AddFunction
---@param platoon Platoon
function PBMLockAndUnlock(platoon)
    if not ScenarioInfo.AMLockTable then
        ScenarioInfo.AMLockTable = {}
    end
    ScenarioInfo.AMLockTable[platoon.PlatoonData.BuilderName] = true
    platoon:AddDestroyCallback(PlatoonDeathUnlockTimer)
end

---AMUnlockPlatoon = BuildCallback
---@param brain AIBrain
---@param platoon Platoon
function AMUnlockPlatoon(brain, platoon)
    if ScenarioInfo.AMLockTable and ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] then
        if platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty] then
            ForkThread(UnlockTimer, platoon.PlatoonData['DiffLockTimerD'..ScenarioInfo.Options.Difficulty], platoon.PlatoonData.PlatoonName)
        elseif platoon.PlatoonData.LockTimer then
            ForkThread(UnlockTimer, platoon.PlatoonData.LockTimer, platoon.PlatoonData.PlatoonName)
        else
            ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = false
        end
    end
end

--- AMUnlockPlatoonTimer = BuildCallback
---@param brain AIBrain
---@param platoon Platoon
---@param duration number
function AMUnlockPlatoonTimer(brain, platoon, duration)
    local callback = function()
        if ScenarioInfo.AMLockTable and ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] then
            ScenarioInfo.AMLockTable[platoon.PlatoonData.PlatoonName] = false
        end
    end
    ScenarioFramework.CreateTimerTrigger( callback, duration )
end

---AMCheckPlatoonLock = BuildCondition
---@param brain AIBrain
---@param AMPlatoonName string
---@return boolean
function AMCheckPlatoonLock(brain, AMPlatoonName)
    if ScenarioInfo.AMLockTable[AMPlatoonName] then
        return false
    end
    return true
end

--- ChildCountDifficulty = BuildCondition
---@param aiBrain AIBrain
---@param master string
---@return boolean
function ChildCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
	local difficulty = ScenarioInfo.Options.Difficulty or 3
	local number = ScenarioInfo.OSPlatoonCounter[master..'_D'..difficulty] or difficulty
	
	return counter < number
end

--- MasterCountDifficulty = BuildCondition
---@param aiBrain AIBrain
---@param master string
---@return boolean
function MasterCountDifficulty(aiBrain, master)
    local counter = ScenarioFramework.AMPlatoonCounter(aiBrain, master)
	local difficulty = ScenarioInfo.Options.Difficulty or 3
	local number = ScenarioInfo.OSPlatoonCounter[master..'_D'..difficulty] or difficulty
	
	return counter >= number
end

-- Unused Files but moved for Mod Support
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")