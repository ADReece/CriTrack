-- CriTrack - Minimal version for Turtle WoW
print("CriTrack: Loading...")

-- Global variables
CriTrackDB = CriTrackDB or {}
local highestCrit = 0
local announcementChannel = "SAY"

-- Create frame
local frame = CreateFrame("Frame")

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("CriTrack: Player login detected")
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        print("CriTrack: Loaded! High score: " .. highestCrit)
    elseif event == "UNIT_COMBAT" then
        local unit, action, damage, _, isCrit = ...
        if unit == "player" and isCrit == 1 then
            local critAmount = tonumber(damage)
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CriTrackDB.highestCrit = highestCrit
                SendChatMessage("New crit record: " .. critAmount .. "!", announcementChannel)
            end
        end
    end
end)

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UNIT_COMBAT")

-- Slash commands
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    if msg == "say" then
        announcementChannel = "SAY"
        CriTrackDB.announcementChannel = "SAY"
        print("CriTrack: Channel set to SAY")
    elseif msg == "party" then
        announcementChannel = "PARTY"
        CriTrackDB.announcementChannel = "PARTY"
        print("CriTrack: Channel set to PARTY")
    else
        print("CriTrack: Usage /critchannel say|party")
    end
end

SLASH_CRITHIGH1 = "/crithigh"
SlashCmdList["CRITHIGH"] = function()
    print("CriTrack: Current high score: " .. highestCrit)
end

print("CriTrack: Addon loaded successfully")
