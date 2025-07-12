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

-- Competition mode configuration
local competitionMode = false
local competitionData = {} -- Table to store {playerName, critAmount, spellName}

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

-- Get player name from unit (for competition mode)
local function GetPlayerFromUnit(unit)
    if unit == "player" then
        return UnitName("player")
    elseif unit == "target" then
        -- In competition mode, we need to figure out who made the hit
        -- Since UNIT_COMBAT fires when YOU hit something, it's always the player
        return UnitName("player")
    end
    return nil
end

-- Update competition leaderboard
local function UpdateCompetitionLeaderboard(playerName, critAmount, spellName)
    if not competitionMode then return false end
    
    -- Get the previous leader before updating
    local previousLeader = GetCompetitionLeader()
    local previousLeaderName = previousLeader and previousLeader.playerName or nil
    local previousLeaderAmount = previousLeader and previousLeader.critAmount or 0
    
    -- Find existing entry for this player
    local playerEntry = nil
    for i, entry in ipairs(competitionData) do
        if entry.playerName == playerName then
            playerEntry = entry
            break
        end
    end
    
    -- Update or create entry
    local wasUpdated = false
    if playerEntry then
        if critAmount > playerEntry.critAmount then
            playerEntry.critAmount = critAmount
            playerEntry.spellName = spellName
            wasUpdated = true
        end
    else
        table.insert(competitionData, {
            playerName = playerName,
            critAmount = critAmount,
            spellName = spellName
        })
        wasUpdated = true
    end
    
    if wasUpdated then
        CriTrackDB.competitionData = competitionData
        
        -- Check if leadership changed
        local newLeader = GetCompetitionLeader()
        local newLeaderName = newLeader and newLeader.playerName or nil
        
        -- Return leadership change info
        return {
            updated = true,
            isNewLeader = newLeaderName == playerName,
            leadershipChanged = previousLeaderName ~= newLeaderName,
            previousLeader = previousLeaderName,
            newLeader = newLeaderName
        }
    end
    
    return {updated = false}
end

-- Get the highest crit from competition data
local function GetCompetitionLeader()
    if not competitionMode or not competitionData or table.getn(competitionData) == 0 then
        return nil
    end
    
    local leader = competitionData[1]
    for i = 2, table.getn(competitionData) do
        if competitionData[i].critAmount > leader.critAmount then
            leader = competitionData[i]
        end
    end
    
    return leader
end

-- Get a proper spell name from damage type (1.12 compatible)
local function GetSpellNameFromDamageType(damageType)
    if not damageType then
        return "Melee Attack"
    end
    
    local upper = string.upper(damageType)
    
    -- Skip heals entirely
    if upper == "HEAL" then
        return nil
    end
    
    -- Map damage types to more readable names
    if upper == "WOUND" then
        return "Melee Attack"
    elseif upper == "DAMAGE" then
        return "Ability"
    elseif upper == "FIRE" then
        return "Fire Damage"
    elseif upper == "FROST" then
        return "Frost Damage"
    elseif upper == "NATURE" then
        return "Nature Damage"
    elseif upper == "SHADOW" then
        return "Shadow Damage"
    elseif upper == "ARCANE" then
        return "Arcane Damage"
    elseif upper == "HOLY" then
        return "Holy Damage"
    else
        -- If it's not a recognized damage type, it might be a spell name
        -- Capitalize first letter for better display
        local firstLetter = string.sub(damageType, 1, 1)
        local rest = string.sub(damageType, 2)
        return string.upper(firstLetter) .. string.lower(rest)
    end
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
        competitionMode = CriTrackDB.competitionMode or false
        competitionData = CriTrackDB.competitionData or {}
        
        local spellText = ""
        if highestCritSpell ~= "Unknown" then
            spellText = " (" .. highestCritSpell .. ")"
        end
        
        local debugText = ""
        if debugEnabled then
            debugText = " |cffff9900[Debug: " .. debugMode .. "]|r"
        end
        
        local competitionText = ""
        if competitionMode then
            competitionText = " |cff00ff00[Competition Mode]|r"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack loaded! Current record: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")" .. debugText .. competitionText)
        
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
            local damageType = arg2 or "WOUND"
            
            -- Skip healing crits - we only want damage crits
            if string.upper(damageType) == "HEAL" then
                DebugMessage("Skipping heal crit: " .. tostring(critAmount))
                return
            end
            
            local spellName = GetSpellNameFromDamageType(damageType) -- Convert damage type to readable name
            if not spellName then
                DebugMessage("Skipping unknown damage type: " .. tostring(damageType))
                return
            end
            
            local playerName = UnitName("player") -- Always the player since UNIT_COMBAT fires for your hits
            
            DebugMessage("Critical hit detected! Amount=" .. tostring(critAmount) .. ", Type=" .. tostring(spellName) .. ", Target=" .. tostring(arg1))
            
            -- Handle personal record
            local personalRecord = false
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                highestCritSpell = spellName
                CriTrackDB.highestCrit = highestCrit
                CriTrackDB.highestCritSpell = highestCritSpell
                personalRecord = true
                DebugMessage("New personal record set!")
            end
            
            -- Handle competition mode
            local competitionResult = {updated = false}
            if competitionMode then
                competitionResult = UpdateCompetitionLeaderboard(playerName, critAmount, spellName)
            end
            
            -- Announce based on mode
            if personalRecord then
                -- Always announce personal records
                if competitionMode and competitionResult.updated and competitionResult.isNewLeader then
                    SendChatMessage("New group crit record: " .. critAmount .. " (" .. spellName .. ") by " .. playerName .. "!", announcementChannel)
                else
                    SendChatMessage("New crit record: " .. critAmount .. " (" .. spellName .. ")!", announcementChannel)
                end
            else
                -- Not a personal record, but maybe announce if it's a competition leadership change
                if competitionMode and competitionResult.updated and competitionResult.leadershipChanged and competitionResult.isNewLeader then
                    SendChatMessage("New group crit leader: " .. critAmount .. " (" .. spellName .. ") by " .. playerName .. "!", announcementChannel)
                end
            end
            
            if not personalRecord then
                DebugMessage("Crit not higher than current personal record (" .. highestCrit .. ")")
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
        DEFAULT_CHAT_FRAME:AddMessage("Competition Mode: " .. tostring(competitionMode))
        if competitionMode then
            DEFAULT_CHAT_FRAME:AddMessage("Competition Entries: " .. table.getn(competitionData))
        end
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

-- Add player crit to competition (manual entry)
SLASH_CRITADD1 = "/critadd"
SlashCmdList["CRITADD"] = function(msg)
    if not competitionMode then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode is not enabled. Use /critcomp on to enable it.")
        return
    end
    
    -- Parse the command: /critadd PlayerName Amount SpellName
    local playerName, amount, spellName = string.match(msg, "^(%S+)%s+(%d+)%s*(.*)$")
    
    if not playerName or not amount then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /critadd PlayerName Amount [SpellName]")
        DEFAULT_CHAT_FRAME:AddMessage("Example: /critadd Gandalf 450 Fireball")
        return
    end
    
    local critAmount = tonumber(amount)
    if not critAmount or critAmount <= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Invalid amount. Must be a positive number.")
        return
    end
    
    if not spellName or spellName == "" then
        spellName = "Unknown Spell"
    end
    
    -- Update competition leaderboard
    local competitionResult = UpdateCompetitionLeaderboard(playerName, critAmount, spellName)
    
    if competitionResult.updated then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Added " .. playerName .. "'s crit: " .. critAmount .. " (" .. spellName .. ")")
        
        -- Announce if there's a leadership change
        if competitionResult.leadershipChanged then
            SendChatMessage("New group crit leader: " .. critAmount .. " (" .. spellName .. ") by " .. playerName .. "!", announcementChannel)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: " .. playerName .. "'s crit (" .. critAmount .. ") was not higher than their current record.")
    end
end

-- Competition mode command
SLASH_CRITCOMPETITION1 = "/critcompetition"
SLASH_CRITCOMPETITION2 = "/critcomp"
SlashCmdList["CRITCOMPETITION"] = function(msg)
    if not msg or msg == "" then
        -- Show current competition status
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Competition Mode ===")
        DEFAULT_CHAT_FRAME:AddMessage("Status: " .. (competitionMode and "ENABLED" or "DISABLED"))
        if competitionMode then
            local leader = GetCompetitionLeader()
            if leader then
                DEFAULT_CHAT_FRAME:AddMessage("Current Leader: " .. leader.playerName .. " - " .. leader.critAmount .. " (" .. leader.spellName .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("No competition data yet")
            end
            DEFAULT_CHAT_FRAME:AddMessage("Participants: " .. table.getn(competitionData))
        end
        DEFAULT_CHAT_FRAME:AddMessage("===============================")
    elseif msg == "on" or msg == "enable" then
        competitionMode = true
        CriTrackDB.competitionMode = true
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode enabled! Group crit tracking active.")
    elseif msg == "off" or msg == "disable" then
        competitionMode = false
        CriTrackDB.competitionMode = false
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode disabled.")
    elseif msg == "reset" or msg == "clear" then
        competitionData = {}
        CriTrackDB.competitionData = {}
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition leaderboard cleared!")
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack Competition Usage:")
        DEFAULT_CHAT_FRAME:AddMessage("  /critcomp - Show competition status")
        DEFAULT_CHAT_FRAME:AddMessage("  /critcomp on - Enable competition mode")
        DEFAULT_CHAT_FRAME:AddMessage("  /critcomp off - Disable competition mode")
        DEFAULT_CHAT_FRAME:AddMessage("  /critcomp reset - Clear leaderboard")
    end
end

-- Leaderboard command
SLASH_CRITLEADERBOARD1 = "/critleaderboard"
SLASH_CRITLEADERBOARD2 = "/critboard"
SlashCmdList["CRITLEADERBOARD"] = function(msg)
    if not competitionMode then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode is not enabled. Use /critcomp on to enable it.")
        return
    end
    
    if not competitionData or table.getn(competitionData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: No competition data available yet.")
        return
    end
    
    -- Sort the competition data by crit amount (highest first)
    local sortedData = {}
    for i, entry in ipairs(competitionData) do
        table.insert(sortedData, entry)
    end
    
    -- Simple bubble sort for 1.12 compatibility
    for i = 1, table.getn(sortedData) - 1 do
        for j = 1, table.getn(sortedData) - i do
            if sortedData[j].critAmount < sortedData[j + 1].critAmount then
                local temp = sortedData[j]
                sortedData[j] = sortedData[j + 1]
                sortedData[j + 1] = temp
            end
        end
    end
    
    -- Announce or display leaderboard
    if msg == "announce" then
        SendChatMessage("=== Crit Leaderboard ===", announcementChannel)
        for i = 1, math.min(5, table.getn(sortedData)) do -- Top 5
            local entry = sortedData[i]
            SendChatMessage(i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")", announcementChannel)
        end
        SendChatMessage("======================", announcementChannel)
    else
        -- Display in chat frame
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Leaderboard ===")
        for i = 1, table.getn(sortedData) do
            local entry = sortedData[i]
            local medal = ""
            if i == 1 then medal = "|cfffff700🥇|r "
            elseif i == 2 then medal = "|cffc0c0c0🥈|r "
            elseif i == 3 then medal = "|cffcd7f32🥉|r "
            end
            DEFAULT_CHAT_FRAME:AddMessage(medal .. i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
        end
        DEFAULT_CHAT_FRAME:AddMessage("===========================")
        DEFAULT_CHAT_FRAME:AddMessage("Use '/critboard announce' to share in " .. string.lower(announcementChannel))
    end
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon loaded for 1.12 Vanilla!")
