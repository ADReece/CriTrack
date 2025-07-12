local critTracker = CreateFrame("Frame")
local highestCrit = 0

-- Load previous highscore if saved
critTracker:RegisterEvent("VARIABLES_LOADED")

-- Listen for combat log events
critTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- SavedVariables
CritTrackerDB = CritTrackerDB or {}

local function GetCritAmount(...)
    local eventType = select(2, ...)
    if eventType == "SWING_DAMAGE" then
        local isCrit = select(18, ...)
        local damage = select(12, ...)
        if isCrit and damage then
            return damage
        end
    elseif eventType == "SPELL_DAMAGE" or eventType == "RANGE_DAMAGE" then
        local isCrit = select(21, ...)
        local damage = select(15, ...)
        if isCrit and damage then
            return damage
        end
    end
    return nil
end

critTracker:SetScript("OnEvent", function(self, event, ...)
    if event == "VARIABLES_LOADED" then
        highestCrit = CritTrackerDB.highestCrit or 0
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, eventType, hideCaster,
              sourceGUID, sourceName, sourceFlags,
              destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

        -- Only track the player's own crits
        if sourceGUID == UnitGUID("player") then
            local critAmount = GetCritAmount(CombatLogGetCurrentEventInfo())
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CritTrackerDB.highestCrit = highestCrit
                SendChatMessage("New crit highscore: " .. critAmount .. "!", "SAY")
            end
        end
    end
end)
