-- CriTrack for Turtle WoW (1.12 Vanilla Client)
-- Compatible with original 2006 WoW API

-- Simple variables - no complex namespace needed for 1.12
local CriTrack = CreateFrame("Frame", "CriTrackFrame")
local highestCrit = 0
local highestCritSpell = "Unknown"
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
        highestCritSpell = CriTrackDB.highestCritSpell or "Unknown"
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        
        local spellText = ""
        if highestCritSpell ~= "Unknown" then
            spellText = " (" .. highestCritSpell .. ")"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack loaded! Current record: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")")
        
    elseif event == "UNIT_COMBAT" then
        -- Debug: Show all event arguments for 1.12 troubleshooting
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: UNIT_COMBAT triggered")
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: arg1=" .. tostring(arg1) .. ", arg2=" .. tostring(arg2) .. ", arg3=" .. tostring(arg3) .. ", arg4=" .. tostring(arg4) .. ", arg5=" .. tostring(arg5))
        
        -- 1.12 UNIT_COMBAT event handling
        if arg1 == "player" and arg5 == 1 then -- arg1=unit, arg5=isCrit
            local critAmount = tonumber(arg3) -- arg3=damage
            local spellName = arg2 or "Melee Attack" -- arg2=action/spell
            
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: Player crit detected! Amount=" .. tostring(critAmount) .. ", Spell=" .. tostring(spellName))
            
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                highestCritSpell = spellName
                CriTrackDB.highestCrit = highestCrit
                CriTrackDB.highestCritSpell = highestCritSpell
                DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: New record set!")
                SendChatMessage("New crit record: " .. critAmount .. " (" .. spellName .. ")!", announcementChannel)
            else
                DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: Crit not higher than current record (" .. highestCrit .. ")")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack DEBUG: Not player crit - arg1=" .. tostring(arg1) .. ", arg5=" .. tostring(arg5))
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
    local spellText = ""
    if highestCritSpell ~= "Unknown" then
        spellText = " with " .. highestCritSpell
    end
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Current highest crit: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")")
end

SLASH_CRITRESET1 = "/critreset"
SlashCmdList["CRITRESET"] = function()
    highestCrit = 0
    highestCritSpell = "Unknown"
    CriTrackDB.highestCrit = 0
    CriTrackDB.highestCritSpell = "Unknown"
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: High score reset to 0")
end

-- Debug command for 1.12
SLASH_CRITDEBUG1 = "/critdebug"
SlashCmdList["CRITDEBUG"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Debug Info ===")
    DEFAULT_CHAT_FRAME:AddMessage("Frame: " .. CriTrack:GetName())
    DEFAULT_CHAT_FRAME:AddMessage("Highest Crit: " .. highestCrit)
    DEFAULT_CHAT_FRAME:AddMessage("Highest Crit Spell: " .. highestCritSpell)
    DEFAULT_CHAT_FRAME:AddMessage("Channel: " .. announcementChannel)
    DEFAULT_CHAT_FRAME:AddMessage("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
    if CriTrackDB then
        DEFAULT_CHAT_FRAME:AddMessage("Saved Crit: " .. tostring(CriTrackDB.highestCrit or 0))
        DEFAULT_CHAT_FRAME:AddMessage("Saved Spell: " .. tostring(CriTrackDB.highestCritSpell or "Unknown"))
    end
    DEFAULT_CHAT_FRAME:AddMessage("Events: PLAYER_LOGIN, UNIT_COMBAT")
    DEFAULT_CHAT_FRAME:AddMessage("==========================")
end

-- Test command to manually set a crit (for debugging)
SLASH_CRITTEST1 = "/crittest"
SlashCmdList["CRITTEST"] = function(msg)
    local testAmount = tonumber(msg) or 100
    if testAmount > highestCrit then
        highestCrit = testAmount
        highestCritSpell = "Test Spell"
        CriTrackDB.highestCrit = highestCrit
        CriTrackDB.highestCritSpell = highestCritSpell
        SendChatMessage("New crit record: " .. testAmount .. " (Test Spell)!", announcementChannel)
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test crit set to " .. testAmount)
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test amount must be higher than current record (" .. highestCrit .. ")")
    end
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon loaded for 1.12 Vanilla!")
