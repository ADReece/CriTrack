-- CompetitionManager.lua - Competition and leaderboard management for CriTrack
-- Compatible with WoW 1.12 and Lua 5.0

-- Make CompetitionManager global for WoW 1.12 compatibility
CompetitionManager = {}

-- Initialize competition data
function CompetitionManager.Initialize(savedData)
    CompetitionManager.competitionData = savedData or {}
    CompetitionManager.competitionMode = false
end

-- Enable or disable competition mode
function CompetitionManager.SetMode(enabled)
    CompetitionManager.competitionMode = enabled
end

-- Check if competition mode is enabled
function CompetitionManager.IsEnabled()
    return CompetitionManager.competitionMode
end

-- Update competition leaderboard
function CompetitionManager.UpdateLeaderboard(playerName, critAmount, spellName)
    if not CompetitionManager.competitionMode then 
        return {updated = false} 
    end
    
    -- Get the previous leader before updating
    local previousLeader = CompetitionManager.GetLeader()
    local previousLeaderName = previousLeader and previousLeader.playerName or nil
    
    -- Find existing entry for this player
    local playerEntry = nil
    for i, entry in ipairs(CompetitionManager.competitionData) do
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
        table.insert(CompetitionManager.competitionData, {
            playerName = playerName,
            critAmount = critAmount,
            spellName = spellName
        })
        wasUpdated = true
    end
    
    if wasUpdated then
        -- Check if leadership changed
        local newLeader = CompetitionManager.GetLeader()
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

-- Get the current competition leader
function CompetitionManager.GetLeader()
    if not CompetitionManager.competitionMode or 
       not CompetitionManager.competitionData or 
       table.getn(CompetitionManager.competitionData) == 0 then
        return nil
    end
    
    local leader = CompetitionManager.competitionData[1]
    for i = 2, table.getn(CompetitionManager.competitionData) do
        if CompetitionManager.competitionData[i].critAmount > leader.critAmount then
            leader = CompetitionManager.competitionData[i]
        end
    end
    
    return leader
end

-- Get sorted leaderboard data
function CompetitionManager.GetSortedLeaderboard()
    if not CompetitionManager.competitionData or 
       table.getn(CompetitionManager.competitionData) == 0 then
        return {}
    end
    
    -- Create a copy of the data for sorting
    local sortedData = {}
    for i, entry in ipairs(CompetitionManager.competitionData) do
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
    
    return sortedData
end

-- Get competition statistics
function CompetitionManager.GetStats()
    return {
        enabled = CompetitionManager.competitionMode,
        participantCount = table.getn(CompetitionManager.competitionData or {}),
        leader = CompetitionManager.GetLeader(),
        data = CompetitionManager.competitionData
    }
end

-- Clear all competition data
function CompetitionManager.Reset()
    CompetitionManager.competitionData = {}
end

-- Get the raw competition data (for saving)
function CompetitionManager.GetData()
    return CompetitionManager.competitionData
end

-- CompetitionManager module is now globally available
