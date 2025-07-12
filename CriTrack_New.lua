-- CriTrack for Turtle WoW (Interface 11200)
-- Simple and reliable critical hit tracker

-- Initialize variables
local CriTrack = CreateFrame("Frame")
local highestCrit = 0
local announcementChannel = "SAY"

-- Function to normalize channel input
local function GetValidChannel(input)
    local channels = {
        ["say"] = "SAY",
        ["party"] = "PARTY", 
        ["raid"] = "RAID",
        ["guild"] = "GUILD",
        ["yell"] = "YELL"
    }
    return channels[string.lower(input or "")] or nil
end

-- Event handler
local function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Initialize saved variables
        if not CriTrackDB then
            CriTrackDB = {}
        end
        
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        
        print("CriTrack loaded! Current record: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
        
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
end

-- Set up event handler
CriTrack:SetScript("OnEvent", OnEvent)
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("UNIT_COMBAT")

-- Slash command: Change channel
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = GetValidChannel(msg)
    if newChannel then
        announcementChannel = newChannel
        CriTrackDB.announcementChannel = newChannel
        print("CriTrack: Announcement channel set to " .. newChannel)
    else
        print("CriTrack: Usage - /critchannel say|party|raid|guild|yell")
    end
end

-- Slash command: Check current high score
SLASH_CRITHIGH1 = "/crithigh"  
SlashCmdList["CRITHIGH"] = function()
    print("CriTrack: Current highest crit: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
end

-- Slash command: Reset high score
SLASH_CRITRESET1 = "/critreset"
SlashCmdList["CRITRESET"] = function()
    highestCrit = 0
    CriTrackDB.highestCrit = 0
    print("CriTrack: High score reset to 0")
end

print("CriTrack: Addon loaded successfully!")
