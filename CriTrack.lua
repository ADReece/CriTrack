-- CriTrack for Turtle WoW (Interface 11200)
-- Simple and reliable critical hit tracker

-- Addon isolation: Create unique namespace
local CRITRACK_NAMESPACE = "CriTrack_" .. math.random(1000, 9999)
print("CriTrack: Starting with namespace " .. CRITRACK_NAMESPACE)

-- Check for addon conflicts
local function CheckAddonConflicts()
    local conflicts = {}
    
    -- Check for SlashCmdList conflicts
    if SlashCmdList["CRITCHANNEL"] then
        table.insert(conflicts, "CRITCHANNEL command already exists")
    end
    if SlashCmdList["CRITHIGH"] then
        table.insert(conflicts, "CRITHIGH command already exists")
    end
    if SlashCmdList["CRITRESET"] then
        table.insert(conflicts, "CRITRESET command already exists")
    end
    
    -- Check for global variable conflicts
    if _G["CriTrackDB"] and type(_G["CriTrackDB"]) ~= "table" then
        table.insert(conflicts, "CriTrackDB global variable conflict")
    end
    
    -- Report conflicts
    if #conflicts > 0 then
        print("CriTrack: WARNING - Potential conflicts detected:")
        for i, conflict in ipairs(conflicts) do
            print("  - " .. conflict)
        end
    else
        print("CriTrack: No conflicts detected")
    end
    
    return #conflicts == 0
end

-- Initialize variables
local CriTrack = CreateFrame("Frame", CRITRACK_NAMESPACE .. "_MainFrame")
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

-- Event handler with detailed debugging
local function OnEvent(self, event, ...)
    print("CriTrack: Event received - " .. event)
    
    if event == "PLAYER_LOGIN" then
        print("CriTrack: Processing PLAYER_LOGIN...")
        
        -- Check for conflicts first
        if not CheckAddonConflicts() then
            print("CriTrack: WARNING - Conflicts detected, addon may not work properly")
        end
        
        -- Initialize saved variables
        if not CriTrackDB then
            CriTrackDB = {}
            print("CriTrack: Created new CriTrackDB")
        else
            print("CriTrack: Using existing CriTrackDB")
        end
        
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        
        print("CriTrack loaded! Current record: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
        
    elseif event == "UNIT_COMBAT" then
        local unit, action, damage, _, isCrit = ...
        print("CriTrack: UNIT_COMBAT - Unit: " .. tostring(unit) .. ", Damage: " .. tostring(damage) .. ", Crit: " .. tostring(isCrit))
        
        if unit == "player" and isCrit == 1 then
            local critAmount = tonumber(damage)
            print("CriTrack: Player crit detected - " .. tostring(critAmount))
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CriTrackDB.highestCrit = highestCrit
                print("CriTrack: New record set - " .. critAmount)
                SendChatMessage("New crit record: " .. critAmount .. "!", announcementChannel)
            end
        end
    end
end

-- Set up event handler with debugging
print("CriTrack: Setting up event handler...")
CriTrack:SetScript("OnEvent", OnEvent)
print("CriTrack: Registering PLAYER_LOGIN event...")
CriTrack:RegisterEvent("PLAYER_LOGIN")
print("CriTrack: Registering UNIT_COMBAT event...")
CriTrack:RegisterEvent("UNIT_COMBAT")
print("CriTrack: Event registration complete")

-- Slash command: Change channel (with conflict protection)
print("CriTrack: Registering slash commands...")
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList = SlashCmdList or {}
SlashCmdList["CRITCHANNEL"] = function(msg)
    print("CriTrack: /critchannel command executed with: " .. tostring(msg))
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
    print("CriTrack: /crithigh command executed")
    print("CriTrack: Current highest crit: " .. highestCrit .. " (Channel: " .. announcementChannel .. ")")
end

-- Slash command: Reset high score
SLASH_CRITRESET1 = "/critreset"
SlashCmdList["CRITRESET"] = function()
    print("CriTrack: /critreset command executed")
    highestCrit = 0
    CriTrackDB.highestCrit = 0
    print("CriTrack: High score reset to 0")
end

-- Add debug command to check addon status
SLASH_CRITDEBUG1 = "/critdebug"
SlashCmdList["CRITDEBUG"] = function()
    print("CriTrack: === DEBUG INFO ===")
    print("Frame: " .. tostring(CriTrack:GetName()))
    print("Highest Crit: " .. highestCrit)
    print("Channel: " .. announcementChannel)
    print("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
    if CriTrackDB then
        print("CriTrackDB.highestCrit: " .. tostring(CriTrackDB.highestCrit))
        print("CriTrackDB.announcementChannel: " .. tostring(CriTrackDB.announcementChannel))
    end
    print("Events registered: PLAYER_LOGIN, UNIT_COMBAT")
    print("===================")
end

print("CriTrack: All slash commands registered")
print("CriTrack: Addon loaded successfully!")
print("CriTrack: Use /critdebug to check addon status")
