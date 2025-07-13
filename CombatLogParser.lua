-- CombatLogParser.lua - Combat log parsing utilities for WoW 1.12
-- Compatible with original 2006 WoW API and Lua 5.0

-- Make CombatLogParser global for WoW 1.12 compatibility
CombatLogParser = {}

-- Parse combat log messages for critical hits (1.12 compatible)
function CombatLogParser.ParseCriticalHit(message)
    if not message then return nil end
    
    -- Look for critical hit patterns in the message
    if string.find(message, "crit") then
        -- Extract damage amount - look for "for X damage" or "for X points"
        local _, _, critAmount = string.find(message, "for (%d+)")
        if critAmount then
            critAmount = tonumber(critAmount)
            
            -- Try to extract spell name
            local spellName = nil
            
            -- Pattern: "Your [SpellName] crits" or "Your [SpellName] critically hits"
            local _, _, foundSpell = string.find(message, "Your ([^%s]+) crit")
            if foundSpell then
                spellName = foundSpell
            end
            
            -- If no spell found, check for "You crit" (auto-attack)
            if not spellName and string.find(message, "You crit") then
                spellName = "Auto Attack"
            end
            
            -- If still no spell name, default to "Attack"
            if not spellName then
                spellName = "Attack"
            end
            
            return {
                amount = critAmount,
                spell = spellName,
                target = "target" -- We don't parse target from 1.12 combat log
            }
        end
    end
    
    return nil
end

-- Parse combat log messages for healing (future expansion)
function CombatLogParser.ParseHealing(message)
    if not message then return nil end
    
    -- Look for healing patterns in the message
    if string.find(message, "heal") then
        -- Extract heal amount
        local _, _, healAmount = string.find(message, "for (%d+)")
        if healAmount then
            healAmount = tonumber(healAmount)
            
            -- Try to extract spell name
            local spellName = nil
            local _, _, foundSpell = string.find(message, "Your ([^%s]+) heal")
            if foundSpell then
                spellName = foundSpell
            else
                spellName = "Heal"
            end
            
            return {
                amount = healAmount,
                spell = spellName,
                type = "heal"
            }
        end
    end
    
    return nil
end

-- Check if a message contains a critical hit
function CombatLogParser.IsCriticalHit(message)
    if not message then return false end
    return string.find(message, "crit") ~= nil
end

-- Check if a message contains healing
function CombatLogParser.IsHealing(message)
    if not message then return false end
    return string.find(message, "heal") ~= nil
end

-- Extract damage amount from any combat message
function CombatLogParser.ExtractDamageAmount(message)
    if not message then return nil end
    
    local _, _, amount = string.find(message, "for (%d+)")
    if amount then
        return tonumber(amount)
    end
    
    return nil
end

-- Extract spell name from combat message
function CombatLogParser.ExtractSpellName(message)
    if not message then return nil end
    
    -- Pattern: "Your [SpellName] ..."
    local _, _, spellName = string.find(message, "Your ([^%s]+) ")
    if spellName then
        return spellName
    end
    
    -- Pattern: "You cast [SpellName]"
    local _, _, castSpell = string.find(message, "You cast ([^%s]+)")
    if castSpell then
        return castSpell
    end
    
    return nil
end

-- Parse other players' critical hits from combat log
function CombatLogParser.ParseOtherPlayerCrit(message)
    if not message then return nil end
    
    -- Look for other players' critical hit patterns
    if string.find(message, "crit") then
        -- Pattern 1: "PlayerName's SpellName crits Target for X damage"
        local _, _, playerName, spellName, critAmount = string.find(message, "([^']+)'s ([^%s]+[^%s]*) crits .* for (%d+)")
        if playerName and spellName and critAmount then
            -- Only track if player is in our group
            if Utils and Utils.IsPlayerInGroup(playerName) then
                return {
                    playerName = playerName,
                    amount = tonumber(critAmount),
                    spell = spellName,
                    isCritical = true
                }
            end
        end
        
        -- Pattern 2: "PlayerName's Multi Word Spell crits Target for X damage"
        local _, _, playerName2, multiSpell, critAmount2 = string.find(message, "([^']+)'s (.+) crits .* for (%d+)")
        if playerName2 and multiSpell and critAmount2 then
            -- Only track if player is in our group
            if Utils and Utils.IsPlayerInGroup(playerName2) then
                -- Clean up the spell name (remove any trailing text)
                local cleanSpell = multiSpell
                local spacePos = string.find(cleanSpell, " crits")
                if spacePos then
                    cleanSpell = string.sub(cleanSpell, 1, spacePos - 1)
                end
                
                return {
                    playerName = playerName2,
                    amount = tonumber(critAmount2),
                    spell = cleanSpell,
                    isCritical = true
                }
            end
        end
        
        -- Pattern 3: "PlayerName crits Target for X damage" (auto-attack, only if no possessive)
        if not string.find(message, "'s") then
            local _, _, altPlayerName, altAmount = string.find(message, "([^%s]+) crits .* for (%d+)")
            if altPlayerName and altAmount then
                -- Only track if player is in our group
                if Utils and Utils.IsPlayerInGroup(altPlayerName) then
                    return {
                        playerName = altPlayerName,
                        amount = tonumber(altAmount),
                        spell = "Auto Attack",
                        isCritical = true
                    }
                end
            end
        end
        
        -- Pattern 4: "PlayerName critically hits Target for X damage"
        if not string.find(message, "'s") then
            local _, _, critPlayerName, critAmount3 = string.find(message, "([^%s]+) critically hits .* for (%d+)")
            if critPlayerName and critAmount3 then
                -- Only track if player is in our group
                if Utils and Utils.IsPlayerInGroup(critPlayerName) then
                    return {
                        playerName = critPlayerName,
                        amount = tonumber(critAmount3),
                        spell = "Attack",
                        isCritical = true
                    }
                end
            end
        end
        end
    
    return nil
end

-- CombatLogParser module is now globally available
