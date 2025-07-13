-- Utils.lua - Utility functions for CriTrack
-- Compatible with WoW 1.12 and Lua 5.0

-- Make Utils global for WoW 1.12 compatibility
Utils = {}

-- Simple channel validation for 1.12
function Utils.GetValidChannel(input)
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
function Utils.CreateDebugger(prefix)
    return function(msg, enabled)
        if enabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff9900" .. prefix .. " DEBUG:|r " .. msg)
        end
    end
end

-- Check if unit should be debugged based on debug mode
function Utils.ShouldDebugUnit(unit, debugMode)
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

-- Parse command arguments (simple implementation for 1.12)
function Utils.ParseCommand(msg, pattern)
    if not msg or not pattern then return nil end
    
    -- Simple pattern matching for "/command arg1 arg2 arg3"
    if pattern == "player_amount_spell" then
        -- Parse: PlayerName Amount SpellName
        local words = Utils.ParseWords(msg)
        
        if table.getn(words) >= 2 then
            local playerName = words[1]
            local amount = tonumber(words[2])
            local spellName = ""
            
            -- Concatenate remaining words as spell name
            for i = 3, table.getn(words) do
                if i == 3 then
                    spellName = words[i]
                else
                    spellName = spellName .. " " .. words[i]
                end
            end
            
            if spellName == "" then
                spellName = "Unknown Spell"
            end
            
            return {
                playerName = playerName,
                amount = amount,
                spellName = spellName
            }
        end
    end
    
    return nil
end

-- Parse command arguments using string splitting (Lua 5.0 compatible)
function Utils.ParseWords(msg)
    if not msg or msg == "" then
        return {}
    end
    
    local words = {}
    local start = 1
    while start <= string.len(msg) do
        local wordStart, wordEnd = string.find(msg, "%S+", start)
        if wordStart then
            table.insert(words, string.sub(msg, wordStart, wordEnd))
            start = wordEnd + 1
        else
            break
        end
    end
    
    return words
end

-- Create a formatted message with colors
function Utils.FormatMessage(text, color)
    local colorCode = "|cffffffff" -- Default white
    
    if color == "yellow" then
        colorCode = "|cffff9900"
    elseif color == "green" then
        colorCode = "|cff00ff00"
    elseif color == "red" then
        colorCode = "|cffff0000"
    elseif color == "blue" then
        colorCode = "|cff0099ff"
    elseif color == "gray" then
        colorCode = "|cffcccccc"
    end
    
    return colorCode .. text .. "|r"
end

-- Check if a string is empty or nil
function Utils.IsEmpty(str)
    return not str or str == ""
end

-- Capitalize first letter of a string
function Utils.Capitalize(str)
    if not str or string.len(str) == 0 then
        return str
    end
    
    local firstLetter = string.sub(str, 1, 1)
    local rest = string.sub(str, 2)
    return string.upper(firstLetter) .. string.lower(rest)
end

-- Safe tonumber conversion
function Utils.SafeNumber(value, default)
    local num = tonumber(value)
    if num then
        return num
    else
        return default or 0
    end
end

-- Get player name safely
function Utils.GetPlayerName()
    local playerName = UnitName("player")
    return playerName or "Unknown Player"
end

-- Check if a player is in your group (party or raid)
function Utils.IsPlayerInGroup(playerName)
    if not playerName then return false end
    
    -- In WoW 1.12, check party members first
    if GetNumPartyMembers then
        local numPartyMembers = GetNumPartyMembers()
        for i = 1, numPartyMembers do
            local partyMemberName = UnitName("party" .. i)
            if partyMemberName == playerName then
                return true
            end
        end
    end
    
    -- Check raid members
    if GetNumRaidMembers then
        local numRaidMembers = GetNumRaidMembers()
        for i = 1, numRaidMembers do
            local raidMemberName = UnitName("raid" .. i)
            if raidMemberName == playerName then
                return true
            end
        end
    end
    
    -- If we're not in WoW environment, return true for all players
    -- This allows testing and avoids filtering in standalone mode
    return true
end

-- Utils module is now globally available
