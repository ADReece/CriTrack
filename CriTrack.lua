-- CriTrack for Turtle WoW (1.12 Vanilla Client)
-- Compatible with original 2006 WoW API

-- Simple variables - no complex namespace needed for 1.12
local CriTrack = CreateFrame("Frame", "CriTrackFrame")
local highestCrit = 0
local highestCritSpell = "Unknown"
local announcementChannel = "SAY"

-- Debug configuration
local debugEnabled = false
local debugMode = "player" -- "player" or "party"

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

-- Debug output function
local function DebugMessage(msg)
    if debugEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900CriTrack DEBUG:|r " .. msg)
    end
end

-- Check if unit should be debugged based on debug mode
local function ShouldDebugUnit(unit)
    if not debugEnabled then return false end
    
    if debugMode == "player" then
        return unit == "player" or unit == UnitName("player")
    elseif debugMode == "party" then
        -- Check if unit is player or party member
        if unit == "player" or unit == UnitName("player") then
            return true
        end
        -- Check party members
        for i = 1, 4 do
            if UnitExists("party" .. i) and unit == UnitName("party" .. i) then
                return true
            end
        end
        return false
    end
    
    return false
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
        debugEnabled = CriTrackDB.debugEnabled or false
        debugMode = CriTrackDB.debugMode or "player"
        
        local spellText = ""
        if highestCritSpell ~= "Unknown" then
            spellText = " (" .. highestCritSpell .. ")"
        end
        
        local debugText = ""
        if debugEnabled then
            debugText = " |cffff9900[Debug: " .. debugMode .. "]|r"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack loaded! Current record: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")" .. debugText)
        
    elseif event == "UNIT_COMBAT" then
        -- Debug all UNIT_COMBAT events if debug is enabled
        if debugEnabled then
            DebugMessage("UNIT_COMBAT triggered")
            DebugMessage("arg1=" .. tostring(arg1) .. ", arg2=" .. tostring(arg2) .. ", arg3=" .. tostring(arg3) .. ", arg4=" .. tostring(arg4) .. ", arg5=" .. tostring(arg5))
        end
        
        -- 1.12 UNIT_COMBAT event handling - check for critical hits
        -- In 1.12, UNIT_COMBAT fires when YOU hit something, not when something hits you
        -- arg1 = target unit, arg2 = damage type, arg3 = "CRITICAL" for crits, arg4 = damage amount
        if arg3 == "CRITICAL" then
            local critAmount = tonumber(arg4) -- arg4=damage amount
            local spellName = arg2 or "Melee Attack" -- arg2=damage type/spell
            
            DebugMessage("Critical hit detected! Amount=" .. tostring(critAmount) .. ", Type=" .. tostring(spellName) .. ", Target=" .. tostring(arg1))
            
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                highestCritSpell = spellName
                CriTrackDB.highestCrit = highestCrit
                CriTrackDB.highestCritSpell = highestCritSpell
                DebugMessage("New record set!")
                SendChatMessage("New crit record: " .. critAmount .. " (" .. spellName .. ")!", announcementChannel)
            else
                DebugMessage("Crit not higher than current record (" .. highestCrit .. ")")
            end
        elseif debugEnabled then
            DebugMessage("Not a critical hit - arg3=" .. tostring(arg3))
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
SlashCmdList["CRITDEBUG"] = function(msg)
    if not msg or msg == "" then
        -- Show current debug status
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Debug Info ===")
        DEFAULT_CHAT_FRAME:AddMessage("Frame: " .. CriTrack:GetName())
        DEFAULT_CHAT_FRAME:AddMessage("Highest Crit: " .. highestCrit)
        DEFAULT_CHAT_FRAME:AddMessage("Highest Crit Spell: " .. highestCritSpell)
        DEFAULT_CHAT_FRAME:AddMessage("Channel: " .. announcementChannel)
        DEFAULT_CHAT_FRAME:AddMessage("Debug Enabled: " .. tostring(debugEnabled))
        DEFAULT_CHAT_FRAME:AddMessage("Debug Mode: " .. debugMode)
        DEFAULT_CHAT_FRAME:AddMessage("Player Name: " .. UnitName("player"))
        DEFAULT_CHAT_FRAME:AddMessage("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
        if CriTrackDB then
            DEFAULT_CHAT_FRAME:AddMessage("Saved Crit: " .. tostring(CriTrackDB.highestCrit or 0))
            DEFAULT_CHAT_FRAME:AddMessage("Saved Spell: " .. tostring(CriTrackDB.highestCritSpell or "Unknown"))
        end
        DEFAULT_CHAT_FRAME:AddMessage("Events: PLAYER_LOGIN, UNIT_COMBAT")
        DEFAULT_CHAT_FRAME:AddMessage("==========================")
    elseif msg == "on" then
        debugEnabled = true
        CriTrackDB.debugEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Debug mode enabled (" .. debugMode .. ")")
    elseif msg == "off" then
        debugEnabled = false
        CriTrackDB.debugEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Debug mode disabled")
    elseif msg == "player" then
        debugMode = "player"
        CriTrackDB.debugMode = "player"
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Debug mode set to player only")
    elseif msg == "party" then
        debugMode = "party"
        CriTrackDB.debugMode = "party"
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Debug mode set to party members")
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack Debug Usage:")
        DEFAULT_CHAT_FRAME:AddMessage("  /critdebug - Show debug info")
        DEFAULT_CHAT_FRAME:AddMessage("  /critdebug on - Enable debug messages")
        DEFAULT_CHAT_FRAME:AddMessage("  /critdebug off - Disable debug messages")
        DEFAULT_CHAT_FRAME:AddMessage("  /critdebug player - Debug player only")
        DEFAULT_CHAT_FRAME:AddMessage("  /critdebug party - Debug all party members")
    end
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
