-- CriTrack for Turtle WoW (1.12 Vanilla Client)
-- Compatible with original 2006 WoW API

-- Simple variables - no complex namespace needed for 1.12
local CriTrack = CreateFrame("Frame", "CriTrackFrame")
local highestCrit = 0
local announcementChannel = "SAY"

-- Simple channel validation for 1.12
local function GetValidChannel(input)
    if not input then return nil end
    local lower = string.lower(input)
    
    if lower == "say" then return "SAY" end
    if lower == "party" then return "PARTY" end
    if lower == "raid" then return "RAID" end
    if lower == "guild" then return "GUILD" end
    if lower == "yell" then return "YELL" end
    
    return nil
end

-- Event handler compatible with 1.12
local function OnEvent()
    local event = event -- 1.12 uses global 'event' variable
    
    if event == "PLAYER_LOGIN" then
        -- Initialize saved variables (1.12 style)
        if not CriTrackDB then
            CriTrackDB = {}
        end
        
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack loaded! Current record: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
        
    elseif event == "UNIT_COMBAT" then
        -- 1.12 UNIT_COMBAT event handling
        if arg1 == "player" and arg5 == 1 then -- arg1=unit, arg5=isCrit
            local critAmount = tonumber(arg3) -- arg3=damage
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CriTrackDB.highestCrit = highestCrit
                SendChatMessage("New crit record: " .. critAmount .. "!", announcementChannel)
            end
        end
    end
end

-- Set up event handler (1.12 style)
CriTrack:SetScript("OnEvent", OnEvent)
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("UNIT_COMBAT")

-- Slash commands (1.12 compatible)
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = GetValidChannel(msg)
    if newChannel then
        announcementChannel = newChannel
        CriTrackDB.announcementChannel = newChannel
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Channel set to " .. newChannel)
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /critchannel say|party|raid|guild|yell")
    end
end

SLASH_CRITHIGH1 = "/crithigh"
SlashCmdList["CRITHIGH"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Current highest crit: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
end

SLASH_CRITRESET1 = "/critreset"
SlashCmdList["CRITRESET"] = function()
    highestCrit = 0
    CriTrackDB.highestCrit = 0
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: High score reset to 0")
end

-- Debug command for 1.12
SLASH_CRITDEBUG1 = "/critdebug"
SlashCmdList["CRITDEBUG"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Debug Info ===")
    DEFAULT_CHAT_FRAME:AddMessage("Frame: " .. CriTrack:GetName())
    DEFAULT_CHAT_FRAME:AddMessage("Highest Crit: " .. highestCrit)
    DEFAULT_CHAT_FRAME:AddMessage("Channel: " .. announcementChannel)
    DEFAULT_CHAT_FRAME:AddMessage("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
    DEFAULT_CHAT_FRAME:AddMessage("Events: PLAYER_LOGIN, UNIT_COMBAT")
    DEFAULT_CHAT_FRAME:AddMessage("==========================")
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon loaded for 1.12 Vanilla!")
