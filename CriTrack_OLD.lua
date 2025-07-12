-- Simple load message for interface 11200 compatibility
print("CriTrack: Addon file loaded")

local CriTrack = CreateFrame("Frame")
print("CriTrack: Frame created")

-- Add immediate test command to verify loading
SLASH_CRITTEST1 = "/crittest"
SlashCmdList = SlashCmdList or {}
SlashCmdList["CRITTEST"] = function(msg)
    print("CriTrack: Addon is working! Type /critchannel, /crithigh, or /critreset")
end
print("CriTrack: Test command (/crittest) registered")

-- Initialize saved variables with validation (delayed until PLAYER_LOGIN)
local function InitializeSavedVariables()
    -- SavedVariables are only available after PLAYER_LOGIN in interface 11200
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

-- Variables will be initialized in PLAYER_LOGIN event
local highestCrit = 0
local announcementChannel = "SAY"

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

-- Safe chat message sending (simplified for interface 11200)
local function SafeSendChatMessage(message, channel)
    if not message or not channel then return end
    
    -- Simple approach for interface 11200
    SendChatMessage(message, channel)
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
        print("CriTrack: PLAYER_LOGIN event fired!")
        
        -- Initialize SavedVariables after login
        InitializeSavedVariables()
        
        -- Load values from SavedVariables
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
print("CriTrack: Registering events...")
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("UNIT_COMBAT")
CriTrack:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Enter combat
CriTrack:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Exit combat
print("CriTrack: Events registered successfully")
