-- HealerTracker.lua - Critical heal tracking module for WoW 1.12
-- Compatible with original 2006 WoW API and Lua 5.0

-- Make HealerTracker global for WoW 1.12 compatibility
HealerTracker = {}

-- Internal data structure
local healerData = {
    personalHighest = {
        amount = 0,
        spell = "Unknown",
        target = "Unknown"
    },
    groupHighest = {
        amount = 0,
        spell = "Unknown",
        caster = "Unknown",
        target = "Unknown"
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
    local _, _, spellName, target, healAmount = string.find(message, "Your ([^%s]+) critically heals ([^%s]+) for (%d+)")
    if spellName and target and healAmount then
        return {
            amount = tonumber(healAmount),
            spell = spellName,
            target = target,
            caster = UnitName("player") or "You",
            isCritical = true
        }
    end
    
    -- Pattern 2: "Your SpellName heals Target for X. (Critical)"
    local _, _, spellName2, target2, healAmount2 = string.find(message, "Your ([^%s]+) heals ([^%s]+) for (%d+)%..*[Cc]ritical")
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
    
    -- Pattern 4: Look for any heal with "critical" in the message
    if string.find(message, "[Cc]ritical") and string.find(message, "heal") then
        local _, _, anyAmount = string.find(message, "for (%d+)")
        if anyAmount then
            return {
                amount = tonumber(anyAmount),
                spell = "Heal",
                target = "target",
                caster = UnitName("player") or "You",
                isCritical = true
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
    local _, _, caster, spellName, target, healAmount = string.find(message, "([^']+)'s ([^%s]+) critically heals ([^%s]+) for (%d+)")
    if caster and spellName and target and healAmount then
        return {
            amount = tonumber(healAmount),
            spell = spellName,
            target = target,
            caster = caster,
            isCritical = true
        }
    end
    
    -- Pattern 2: "PlayerName's SpellName heals Target for X. (Critical)"
    local _, _, caster2, spellName2, target2, healAmount2 = string.find(message, "([^']+)'s ([^%s]+) heals ([^%s]+) for (%d+)%..*[Cc]ritical")
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
    
    -- Pattern 4: Look for any heal with "critical" and extract caster
    if string.find(message, "[Cc]ritical") and string.find(message, "heal") then
        local _, _, anyCaster, anyAmount = string.find(message, "([^%s]+).*for (%d+)")
        if anyCaster and anyAmount then
            return {
                amount = tonumber(anyAmount),
                spell = "Heal",
                target = "target",
                caster = anyCaster,
                isCritical = true
            }
        end
    end
    
    return nil
end

-- Update personal heal record
function HealerTracker.UpdatePersonalRecord(healData)
    if not healData or not healerData.enabled then return false end
    
    local updated = false
    if healData.amount > healerData.personalHighest.amount then
        healerData.personalHighest = {
            amount = healData.amount,
            spell = healData.spell,
            target = healData.target
        }
        updated = true
    end
    
    return updated
end

-- Update group heal record
function HealerTracker.UpdateGroupRecord(healData)
    if not healData or not healerData.enabled or not healerData.groupMode then return false end
    
    local updated = false
    if healData.amount > healerData.groupHighest.amount then
        local previousCaster = healerData.groupHighest.caster
        healerData.groupHighest = {
            amount = healData.amount,
            spell = healData.spell,
            caster = healData.caster,
            target = healData.target
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
        target = "Unknown"
    }
end

-- Reset group heal record
function HealerTracker.ResetGroup()
    healerData.groupHighest = {
        amount = 0,
        spell = "Unknown",
        caster = "Unknown",
        target = "Unknown"
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
        return record.amount .. " (" .. record.spell .. " on " .. record.target .. ")"
    else
        return "No critical heals recorded"
    end
end

-- Format group heal record for display
function HealerTracker.FormatGroupRecord()
    local record = healerData.groupHighest
    if record.amount > 0 then
        return record.amount .. " (" .. record.spell .. " by " .. record.caster .. " on " .. record.target .. ")"
    else
        return "No group critical heals recorded"
    end
end

-- HealerTracker module is now globally available
