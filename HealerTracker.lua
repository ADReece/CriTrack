-- HealerTracker.lua - Critical heal tracking module for WoW 1.12
-- Compatible with original 2006 WoW API and Lua 5.0

-- Make HealerTracker global for WoW 1.12 compatibility
HealerTracker = {}

-- Internal data structure
local healerData = {
    personalHighest = {
        amount = 0,
        spell = "Unknown",
        target = "Unknown",
        isCritical = false
    },
    groupHighest = {
        amount = 0,
        spell = "Unknown",
        caster = "Unknown",
        target = "Unknown",
        isCritical = false
    },
    enabled = false,
    groupMode = false -- Track group heals when enabled
}

-- Initialize the healer tracker
function HealerTracker.Initialize(savedData)
    if savedData then
        healerData.personalHighest = savedData.personalHighest or healerData.personalHighest
        healerData.groupHighest = savedData.groupHighest or healerData.groupHighest
        healerData.enabled = savedData.enabled or false
        healerData.groupMode = savedData.groupMode or false
    end
end

-- Enable/disable healer tracking
function HealerTracker.SetEnabled(enabled)
    healerData.enabled = enabled
end

-- Check if healer tracking is enabled
function HealerTracker.IsEnabled()
    return healerData.enabled
end

-- Enable/disable group heal tracking
function HealerTracker.SetGroupMode(enabled)
    healerData.groupMode = enabled
end

-- Check if group heal tracking is enabled
function HealerTracker.IsGroupModeEnabled()
    return healerData.groupMode
end

-- Parse critical heal from combat log message
function HealerTracker.ParseCriticalHeal(message)
    if not message then return nil end
    
    -- Look for critical heal patterns in WoW 1.12 format
    -- Pattern 1: "Your SpellName critically heals Target for X."
    local _, _, spellName, target, healAmount = string.find(message, "Your (.+) critically heals ([^%s]+) for (%d+)")
    if spellName and target and healAmount then
        return {
            amount = tonumber(healAmount),
            spell = spellName,
            target = target,
            caster = UnitName("player") or "You",
            isCritical = true
        }
    end
    
    -- Pattern 2: "Your SpellName critically heals Target for X points."
    local _, _, spellName2, target2, healAmount2 = string.find(message, "Your (.+) critically heals ([^%s]+) for (%d+) points")
    if spellName2 and target2 and healAmount2 then
        return {
            amount = tonumber(healAmount2),
            spell = spellName2,
            target = target2,
            caster = UnitName("player") or "You",
            isCritical = true
        }
    end
    
    -- Pattern 3: "You critically heal Target for X."
    local _, _, target3, healAmount3 = string.find(message, "You critically heal ([^%s]+) for (%d+)")
    if target3 and healAmount3 then
        return {
            amount = tonumber(healAmount3),
            spell = "Heal",
            target = target3,
            caster = UnitName("player") or "You",
            isCritical = true
        }
    end
    
    -- Pattern 4: "You critically heal Target for X points."
    local _, _, target4, healAmount4 = string.find(message, "You critically heal ([^%s]+) for (%d+) points")
    if target4 and healAmount4 then
        return {
            amount = tonumber(healAmount4),
            spell = "Heal",
            target = target4,
            caster = UnitName("player") or "You",
            isCritical = true
        }
    end
    
    -- Pattern 5: Non-critical heals that we want to track (for testing)
    -- "Your SpellName heals Target for X."
    local _, _, spellName5, target5, healAmount5 = string.find(message, "Your (.+) heals ([^%s]+) for (%d+)")
    if spellName5 and target5 and healAmount5 then
        -- Track heals over 50 points to reduce spam but still catch most heals
        local amount = tonumber(healAmount5)
        if amount > 50 then
            return {
                amount = amount,
                spell = spellName5,
                target = target5,
                caster = UnitName("player") or "You",
                isCritical = false -- Mark as non-critical but still track
            }
        end
    end
    
    -- Pattern 6: "You heal Target for X."
    local _, _, target6, healAmount6 = string.find(message, "You heal ([^%s]+) for (%d+)")
    if target6 and healAmount6 then
        local amount = tonumber(healAmount6)
        if amount > 50 then
            return {
                amount = amount,
                spell = "Heal",
                target = target6,
                caster = UnitName("player") or "You",
                isCritical = false
            }
        end
    end
    
    return nil
end

-- Parse group member critical heal from combat log
function HealerTracker.ParseGroupCriticalHeal(message)
    if not message or not healerData.groupMode then return nil end
    
    -- Look for other players' critical heals in WoW 1.12 format
    -- Pattern 1: "PlayerName's SpellName critically heals Target for X."
    local _, _, caster, spellName, target, healAmount = string.find(message, "([^']+)'s (.+) critically heals ([^%s]+) for (%d+)")
    if caster and spellName and target and healAmount then
        return {
            amount = tonumber(healAmount),
            spell = spellName,
            target = target,
            caster = caster,
            isCritical = true
        }
    end
    
    -- Pattern 2: "PlayerName's SpellName critically heals Target for X points."
    local _, _, caster2, spellName2, target2, healAmount2 = string.find(message, "([^']+)'s (.+) critically heals ([^%s]+) for (%d+) points")
    if caster2 and spellName2 and target2 and healAmount2 then
        return {
            amount = tonumber(healAmount2),
            spell = spellName2,
            target = target2,
            caster = caster2,
            isCritical = true
        }
    end
    
    -- Pattern 3: "PlayerName critically heals Target for X."
    local _, _, caster3, target3, healAmount3 = string.find(message, "([^%s]+) critically heals ([^%s]+) for (%d+)")
    if caster3 and target3 and healAmount3 then
        return {
            amount = tonumber(healAmount3),
            spell = "Heal",
            target = target3,
            caster = caster3,
            isCritical = true
        }
    end
    
    -- Pattern 4: "PlayerName critically heals Target for X points."
    local _, _, caster4, target4, healAmount4 = string.find(message, "([^%s]+) critically heals ([^%s]+) for (%d+) points")
    if caster4 and target4 and healAmount4 then
        return {
            amount = tonumber(healAmount4),
            spell = "Heal",
            target = target4,
            caster = caster4,
            isCritical = true
        }
    end
    
    -- Pattern 5: Non-critical group heals (for testing)
    -- "PlayerName's SpellName heals Target for X."
    local _, _, caster5, spellName5, target5, healAmount5 = string.find(message, "([^']+)'s (.+) heals ([^%s]+) for (%d+)")
    if caster5 and spellName5 and target5 and healAmount5 then
        local amount = tonumber(healAmount5)
        if amount > 50 then
            return {
                amount = amount,
                spell = spellName5,
                target = target5,
                caster = caster5,
                isCritical = false
            }
        end
    end
    
    -- Pattern 6: "PlayerName heals Target for X."
    local _, _, caster6, target6, healAmount6 = string.find(message, "([^%s]+) heals ([^%s]+) for (%d+)")
    if caster6 and target6 and healAmount6 then
        local amount = tonumber(healAmount6)
        if amount > 50 then
            return {
                amount = amount,
                spell = "Heal",
                target = target6,
                caster = caster6,
                isCritical = false
            }
        end
    end
    
    return nil
end

-- Update personal heal record
function HealerTracker.UpdatePersonalRecord(healData)
    if not healData or not healerData.enabled then return false end
    
    local updated = false
    -- Track both critical and non-critical heals, but prioritize critical ones
    if healData.amount > healerData.personalHighest.amount then
        healerData.personalHighest = {
            amount = healData.amount,
            spell = healData.spell,
            target = healData.target,
            isCritical = healData.isCritical
        }
        updated = true
    end
    
    return updated
end

-- Update group heal record
function HealerTracker.UpdateGroupRecord(healData)
    if not healData or not healerData.enabled or not healerData.groupMode then return {updated = false} end
    
    local updated = false
    if healData.amount > healerData.groupHighest.amount then
        local previousCaster = healerData.groupHighest.caster
        healerData.groupHighest = {
            amount = healData.amount,
            spell = healData.spell,
            caster = healData.caster,
            target = healData.target,
            isCritical = healData.isCritical
        }
        updated = true
        
        -- Check if leadership changed
        local leadershipChanged = (previousCaster ~= healData.caster and previousCaster ~= "Unknown")
        
        return {
            updated = true,
            leadershipChanged = leadershipChanged,
            isNewLeader = true
        }
    end
    
    return {updated = false}
end

-- Get personal heal record
function HealerTracker.GetPersonalRecord()
    return {
        amount = healerData.personalHighest.amount,
        spell = healerData.personalHighest.spell,
        target = healerData.personalHighest.target
    }
end

-- Get group heal record
function HealerTracker.GetGroupRecord()
    return {
        amount = healerData.groupHighest.amount,
        spell = healerData.groupHighest.spell,
        caster = healerData.groupHighest.caster,
        target = healerData.groupHighest.target
    }
end

-- Get all healer statistics
function HealerTracker.GetStats()
    return {
        enabled = healerData.enabled,
        groupMode = healerData.groupMode,
        personalRecord = HealerTracker.GetPersonalRecord(),
        groupRecord = HealerTracker.GetGroupRecord()
    }
end

-- Reset personal heal record
function HealerTracker.ResetPersonal()
    healerData.personalHighest = {
        amount = 0,
        spell = "Unknown",
        target = "Unknown",
        isCritical = false
    }
end

-- Reset group heal record
function HealerTracker.ResetGroup()
    healerData.groupHighest = {
        amount = 0,
        spell = "Unknown",
        caster = "Unknown",
        target = "Unknown",
        isCritical = false
    }
end

-- Reset all heal records
function HealerTracker.ResetAll()
    HealerTracker.ResetPersonal()
    HealerTracker.ResetGroup()
end

-- Get data for saving
function HealerTracker.GetData()
    return {
        personalHighest = healerData.personalHighest,
        groupHighest = healerData.groupHighest,
        enabled = healerData.enabled,
        groupMode = healerData.groupMode
    }
end

-- Format heal record for display
function HealerTracker.FormatPersonalRecord()
    local record = healerData.personalHighest
    if record.amount > 0 then
        local critText = record.isCritical and " (CRIT)" or ""
        return record.amount .. " (" .. record.spell .. " on " .. record.target .. ")" .. critText
    else
        return "No heals recorded"
    end
end

-- Format group heal record for display
function HealerTracker.FormatGroupRecord()
    local record = healerData.groupHighest
    if record.amount > 0 then
        local critText = record.isCritical and " (CRIT)" or ""
        return record.amount .. " (" .. record.spell .. " by " .. record.caster .. " on " .. record.target .. ")" .. critText
    else
        return "No group heals recorded"
    end
end

-- HealerTracker module is now globally available
