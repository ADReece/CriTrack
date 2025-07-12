-- Debug: Try both DEFAULT_CHAT_FRAME and print for load message
if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Lua loaded (Interface: " .. (GetAddOnMetadata("CriTrack", "Interface") or "Unknown") .. ")")
else
    print("CriTrack: Lua loaded (Interface: " .. (GetAddOnMetadata("CriTrack", "Interface") or "Unknown") .. ")")
end

local CriTrack = CreateFrame("Frame")

-- Compatibility check for interface version 11200
local function IsCompatibleInterface()
    local version = tonumber(GetAddOnMetadata("CriTrack", "Interface"))
    return version and version <= 11200
end

-- Initialize saved variables with validation
local function InitializeSavedVariables()
    -- Ensure SavedVariables are properly initialized for interface 11200
    if not CriTrackDB then
        CriTrackDB = {}
    end
    
    -- Validate saved data
    if type(CriTrackDB.highestCrit) ~= "number" then
        CriTrackDB.highestCrit = 0
    end
    
    if type(CriTrackDB.announcementChannel) ~= "string" then
        CriTrackDB.announcementChannel = "SAY"
    end
end

-- Initialize on load
InitializeSavedVariables()

local highestCrit = CriTrackDB.highestCrit or 0
local announcementChannel = CriTrackDB.announcementChannel or "SAY"

-- Normalize user input to valid chat channels
local function NormalizeChannel(input)
    local map = {
        say = "SAY",
        party = "PARTY",
        raid = "RAID",
        emote = "EMOTE",
        yell = "YELL",
        guild = "GUILD"
    }
    return map[string.lower(input or "")] or nil
end

-- Safe chat message sending with error handling (compatible with 11200)
local function SafeSendChatMessage(message, channel)
    if not message or not channel then return end
    
    -- For interface 11200, use simpler error handling
    local success = pcall(SendChatMessage, message, channel)
    
    if not success then
        print("|cff33ff99CriTrack|r: Error sending message to " .. channel)
        -- Try fallback to SAY channel
        if channel ~= "SAY" then
            pcall(SendChatMessage, message, "SAY")
        end
    end
end

-- Slash command to change the announcement channel
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList = SlashCmdList or {}
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = NormalizeChannel(msg)
    if newChannel then
        announcementChannel = newChannel
        CriTrackDB.announcementChannel = announcementChannel
        print("|cff33ff99CriTrack|r: Channel set to", announcementChannel)
    else
        print("|cff33ff99CriTrack|r usage: /critchannel say|party|raid|guild|yell|emote")
    end
end

-- Add slash command to check current high score
SLASH_CRITHIGH1 = "/crithigh"
SlashCmdList["CRITHIGH"] = function(msg)
    print("|cff33ff99CriTrack|r: Current highest crit: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
end

-- Add slash command to reset high score
SLASH_CRITRESET1 = "/critreset"
SlashCmdList["CRITRESET"] = function(msg)
    highestCrit = 0
    CriTrackDB.highestCrit = 0
    print("|cff33ff99CriTrack|r: High score reset to 0")
end

-- Event handler
CriTrack:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack: PLAYER_LOGIN event fired!")
        else
            print("CriTrack: PLAYER_LOGIN event fired!")
        end
        
        -- Compatibility check
        if not IsCompatibleInterface() then
            print("|cffff0000CriTrack Warning|r: This addon is designed for interface 11200 (Turtle WoW)")
        end
        
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        print("|cff33ff99CriTrack loaded!|r Current high score: " .. highestCrit .. ". Announcing in: " .. announcementChannel)
    elseif event == "UNIT_COMBAT" then
        -- UNIT_COMBAT is the primary event for interface 11200 (Turtle WoW)
        local unit, action, damage, _, isCrit = ...
        if unit == "player" and isCrit == 1 then
            local critAmount = tonumber(damage)
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CriTrackDB.highestCrit = highestCrit
                SafeSendChatMessage("New crit highscore: " .. critAmount .. "!", announcementChannel)
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Enter combat - could be used for additional features later
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Exit combat - could be used for additional features later
    end
end)


-- Register events
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("UNIT_COMBAT")
CriTrack:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter combat
CriTrack:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Exit combat
