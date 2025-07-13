-- CriTrack for Turtle WoW (1.12 Vanilla Client)
-- Compatible with original 2006 WoW API
-- Note: Module files are loaded automatically via .toc file

-- Simple variables - no complex namespace needed for 1.12
local CriTrack = CreateFrame("Frame", "CriTrackFrame")
local highestCrit = 0
local highestCritSpell = "Unknown"
local announcementChannel = "SAY"

-- Debug configuration
local debugEnabled = false
local debugMode = "player" -- "player" or "party"

-- Loading state
local modulesLoaded = false

-- Module references will be available after .toc loads them
local DebugMessage

-- Initialize modules when addon loads
local function InitializeModules()
    -- Try to force load modules if they're not available
    if not Utils then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Utils module missing!")
    end
    
    if not CombatLogParser then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: CombatLogParser module missing!")
    end
    
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: CompetitionManager module missing!")
    end
    
    if not HealerTracker then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: HealerTracker module missing!")
    end
    
    if Utils and Utils.CreateDebugger then
        DebugMessage = Utils.CreateDebugger("CriTrack")
    else
        -- Fallback debug function
        DebugMessage = function(msg, enabled)
            if enabled then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff9900CriTrack DEBUG:|r " .. msg)
            end
        end
    end
    
    -- Count loaded modules
    local moduleCount = 0
    if Utils then moduleCount = moduleCount + 1 end
    if CombatLogParser then moduleCount = moduleCount + 1 end
    if CompetitionManager then moduleCount = moduleCount + 1 end
    if HealerTracker then moduleCount = moduleCount + 1 end
    
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: " .. moduleCount .. " out of 4 modules loaded")
    
    -- Set loading state
    modulesLoaded = true
end



-- Event handler compatible with 1.12
local function OnEvent()
    local event = event -- 1.12 uses global 'event' variable
    
    if event == "PLAYER_LOGIN" then
        -- Initialize modules first
        InitializeModules()
        
        -- Initialize saved variables (1.12 style)
        if not CriTrackDB then
            CriTrackDB = {}
        end
        
        highestCrit = CriTrackDB.highestCrit or 0
        highestCritSpell = CriTrackDB.highestCritSpell or "Unknown"
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        debugEnabled = CriTrackDB.debugEnabled or false
        debugMode = CriTrackDB.debugMode or "player"
        
        -- Initialize competition manager
        if CompetitionManager then
            CompetitionManager.Initialize(CriTrackDB.competitionData)
            CompetitionManager.SetMode(CriTrackDB.competitionMode or false)
        end
        
        -- Initialize healer tracker
        if HealerTracker then
            HealerTracker.Initialize(CriTrackDB.healerData)
            HealerTracker.SetEnabled(CriTrackDB.healerEnabled or false)
            HealerTracker.SetGroupMode(CriTrackDB.healerGroupMode or false)
        end
        
        local spellText = ""
        if highestCritSpell ~= "Unknown" then
            spellText = " (" .. highestCritSpell .. ")"
        end
        
        local debugText = ""
        if debugEnabled then
            if Utils and Utils.FormatMessage then
                debugText = " " .. Utils.FormatMessage("[Debug: " .. debugMode .. "]", "yellow")
            else
                debugText = " |cffff9900[Debug: " .. debugMode .. "]|r"
            end
        end
        
        local competitionText = ""
        if CompetitionManager and CompetitionManager.IsEnabled() then
            if Utils and Utils.FormatMessage then
                competitionText = " " .. Utils.FormatMessage("[Competition Mode]", "green")
            else
                competitionText = " |cff00ff00[Competition Mode]|r"
            end
        end
        
        local healerText = ""
        if HealerTracker and HealerTracker.IsEnabled() then
            if Utils and Utils.FormatMessage then
                healerText = " " .. Utils.FormatMessage("[Healer Mode]", "cyan")
            else
                healerText = " |cff00ffff[Healer Mode]|r"
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack v2.0 loaded! Current record: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")" .. debugText .. competitionText .. healerText)
        
        -- Final loading confirmation
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: All modules initialized successfully!")
        if HealerTracker then
            DEFAULT_CHAT_FRAME:AddMessage("  - Healer tracking available: Use /critheal to configure")
        end
        
    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        -- Parse combat log messages for critical hits
        local message = arg1 -- arg1 contains the combat message
        
        if debugEnabled then
            DebugMessage("Combat message (" .. event .. "): " .. tostring(message), debugEnabled)
        end
        
        local critData = nil
        if CombatLogParser then
            critData = CombatLogParser.ParseCriticalHit(message)
        end
        
        if critData then
            local critAmount = critData.amount
            local spellName = critData.spell
            local target = critData.target
            
            DebugMessage("Critical hit parsed! Amount=" .. tostring(critAmount) .. ", Spell=" .. tostring(spellName) .. ", Target=" .. tostring(target), debugEnabled)
            
            local playerName = UnitName("player")
            if Utils and Utils.GetPlayerName then
                playerName = Utils.GetPlayerName()
            end
            
            -- Handle personal record
            local personalRecord = false
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                highestCritSpell = spellName
                CriTrackDB.highestCrit = highestCrit
                CriTrackDB.highestCritSpell = highestCritSpell
                personalRecord = true
                DebugMessage("New personal record set!", debugEnabled)
            end
            
            -- Handle competition mode
            local competitionResult = {updated = false}
            if CompetitionManager then
                competitionResult = CompetitionManager.UpdateLeaderboard(playerName, critAmount, spellName)
                
                -- Additional debug for competition
                if debugEnabled then
                    DebugMessage("Self crit competition update: updated=" .. tostring(competitionResult.updated) .. ", isNewLeader=" .. tostring(competitionResult.isNewLeader), debugEnabled)
                end
                
                -- Save competition data
                if competitionResult.updated then
                    CriTrackDB.competitionData = CompetitionManager.GetData()
                end
            end
            
            -- Announce based on mode
            if personalRecord then
                -- Always announce personal records
                if CompetitionManager and CompetitionManager.IsEnabled() and competitionResult.updated and competitionResult.isNewLeader then
                    -- Personal record that also makes you group leader
                    SendChatMessage("New group crit record: " .. critAmount .. " (" .. spellName .. ") by " .. playerName .. "!", announcementChannel)
                else
                    -- Just a personal record
                    SendChatMessage("New crit record: " .. critAmount .. " (" .. spellName .. ")!", announcementChannel)
                end
            end
            
            if not personalRecord then
                DebugMessage("Crit not higher than current personal record (" .. highestCrit .. ")", debugEnabled)
            end
        end
        
    elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
        -- Parse healing messages for critical heals
        local message = arg1
        
        if debugEnabled then
            DebugMessage("Heal message (" .. event .. "): " .. tostring(message), debugEnabled)
        end
        
        -- Check for critical heals
        if HealerTracker and HealerTracker.IsEnabled() then
            DebugMessage("HealerTracker is enabled, attempting to parse heal message", debugEnabled)
            local healData = HealerTracker.ParseCriticalHeal(message)
            if healData then
                local critText = healData.isCritical and " (CRITICAL)" or " (regular)"
                DebugMessage("✓ Heal parsed! Amount=" .. tostring(healData.amount) .. ", Spell=" .. tostring(healData.spell) .. ", Target=" .. tostring(healData.target) .. critText, debugEnabled)
                
                -- Update personal heal record
                local personalHealRecord = HealerTracker.UpdatePersonalRecord(healData)
                
                -- Update group heal record if group mode is enabled
                local groupHealResult = {updated = false}
                if HealerTracker.IsGroupModeEnabled() then
                    groupHealResult = HealerTracker.UpdateGroupRecord(healData)
                end
                
                -- Save healer data
                if personalHealRecord or groupHealResult.updated then
                    CriTrackDB.healerData = HealerTracker.GetData()
                    
                    if debugEnabled then
                        DebugMessage("✓ Healer data saved. Personal record updated: " .. tostring(personalHealRecord), debugEnabled)
                    end
                end
                
                -- Announce heal records
                if personalHealRecord then
                    local critAnnounce = healData.isCritical and "New crit heal record" or "New heal record"
                    if HealerTracker.IsGroupModeEnabled() and groupHealResult.updated and groupHealResult.isNewLeader then
                        SendChatMessage("New group heal record: " .. healData.amount .. " (" .. healData.spell .. ") by " .. healData.caster .. " on " .. healData.target .. "!", announcementChannel)
                    else
                        SendChatMessage(critAnnounce .. ": " .. healData.amount .. " (" .. healData.spell .. ") on " .. healData.target .. "!", announcementChannel)
                    end
                end
            else
                if debugEnabled then
                    DebugMessage("✗ No heal data parsed from message: " .. tostring(message), debugEnabled)
                end
            end
        else
            if debugEnabled then
                local enabled = HealerTracker and HealerTracker.IsEnabled()
                DebugMessage("✗ HealerTracker not enabled or not loaded (enabled=" .. tostring(enabled) .. ")", debugEnabled)
            end
        end
        
    elseif event == "CHAT_MSG_COMBAT_FRIENDLY_BUFF" then
        -- Parse group member healing for group mode
        local message = arg1
        
        if debugEnabled then
            DebugMessage("Group heal message (" .. event .. "): " .. tostring(message), debugEnabled)
        end
        
        -- Check for group critical heals
        if HealerTracker and HealerTracker.IsEnabled() and HealerTracker.IsGroupModeEnabled() then
            local healData = HealerTracker.ParseGroupCriticalHeal(message)
            if healData then
                DebugMessage("Group critical heal parsed! Amount=" .. tostring(healData.amount) .. ", Spell=" .. tostring(healData.spell) .. ", Caster=" .. tostring(healData.caster), debugEnabled)
                
                -- Update group heal record
                local groupHealResult = HealerTracker.UpdateGroupRecord(healData)
                
                -- Save healer data
                if groupHealResult.updated then
                    CriTrackDB.healerData = HealerTracker.GetData()
                    
                    -- Announce group heal record
                    if groupHealResult.isNewLeader then
                        SendChatMessage("New group heal record: " .. healData.amount .. " (" .. healData.spell .. ") by " .. healData.caster .. " on " .. healData.target .. "!", announcementChannel)
                    end
                end
            end
        end
    elseif event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF" or event == "CHAT_MSG_SPELL_PARTY_BUFF" then
        -- Parse group member healing for group mode
        local message = arg1
        
        if debugEnabled then
            DebugMessage("Group heal message (" .. event .. "): " .. tostring(message), debugEnabled)
        end
        
        -- Check for group critical heals
        if HealerTracker and HealerTracker.IsEnabled() and HealerTracker.IsGroupModeEnabled() then
            local healData = HealerTracker.ParseGroupCriticalHeal(message)
            if healData then
                local critText = healData.isCritical and " (CRITICAL)" or " (regular)"
                DebugMessage("Group heal parsed! Amount=" .. tostring(healData.amount) .. ", Spell=" .. tostring(healData.spell) .. ", Caster=" .. tostring(healData.caster) .. critText, debugEnabled)
                
                -- Update group heal record
                local groupHealResult = HealerTracker.UpdateGroupRecord(healData)
                
                -- Save healer data
                if groupHealResult.updated then
                    CriTrackDB.healerData = HealerTracker.GetData()
                    
                    if debugEnabled then
                        DebugMessage("Group healer data saved. New leader: " .. tostring(groupHealResult.isNewLeader), debugEnabled)
                    end
                    
                    -- Announce group heal record
                    if groupHealResult.isNewLeader then
                        local critAnnounce = healData.isCritical and "New group crit heal record" or "New group heal record"
                        SendChatMessage(critAnnounce .. ": " .. healData.amount .. " (" .. healData.spell .. ") by " .. healData.caster .. " on " .. healData.target .. "!", announcementChannel)
                    end
                end
            else
                if debugEnabled then
                    DebugMessage("No group heal data parsed from message: " .. tostring(message), debugEnabled)
                end
            end
        else
            if debugEnabled then
                DebugMessage("Group healing not enabled or HealerTracker not loaded", debugEnabled)
            end
        end
    elseif event == "CHAT_MSG_COMBAT_PARTY_HITS" or event == "CHAT_MSG_SPELL_PARTY_DAMAGE" or 
           event == "CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS" or event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE" then
        -- Parse other players' critical hits for competition mode
        local message = arg1
        
        if debugEnabled then
            DebugMessage("Other player combat message (" .. event .. "): " .. tostring(message), debugEnabled)
        end
        
        -- Only process if competition mode is enabled
        if CompetitionManager and CompetitionManager.IsEnabled() then
            local otherCritData = nil
            if CombatLogParser then
                otherCritData = CombatLogParser.ParseOtherPlayerCrit(message)
            end
            
            if otherCritData then
                -- Double-check that the player is actually in our group
                if Utils and Utils.IsPlayerInGroup(otherCritData.playerName) then
                    DebugMessage("Other player crit parsed! Player=" .. tostring(otherCritData.playerName) .. ", Amount=" .. tostring(otherCritData.amount) .. ", Spell=" .. tostring(otherCritData.spell), debugEnabled)
                    
                    -- Additional debug info
                    if debugEnabled then
                        DebugMessage("Raw message was: " .. tostring(message), debugEnabled)
                        DebugMessage("Extracted player: '" .. tostring(otherCritData.playerName) .. "'", debugEnabled)
                        DebugMessage("Extracted spell: '" .. tostring(otherCritData.spell) .. "'", debugEnabled)
                        DebugMessage("Extracted amount: " .. tostring(otherCritData.amount), debugEnabled)
                    end
                    
                    -- Update competition leaderboard
                    local competitionResult = CompetitionManager.UpdateLeaderboard(otherCritData.playerName, otherCritData.amount, otherCritData.spell)
                    
                    -- Additional debug for competition
                    if debugEnabled then
                        DebugMessage("Competition update result: updated=" .. tostring(competitionResult.updated) .. ", isNewLeader=" .. tostring(competitionResult.isNewLeader), debugEnabled)
                        if CompetitionManager.DebugLeaderboard then
                            local leaderboardState = CompetitionManager.DebugLeaderboard()
                            DebugMessage("Current leaderboard: " .. leaderboardState, debugEnabled)
                        end
                    end
                    
                    -- Save competition data
                    if competitionResult.updated then
                        CriTrackDB.competitionData = CompetitionManager.GetData()
                        
                        -- Announce if there's a leadership change
                        if competitionResult.isNewLeader then
                            SendChatMessage("New group crit leader: " .. otherCritData.amount .. " (" .. otherCritData.spell .. ") by " .. otherCritData.playerName .. "!", announcementChannel)
                        end
                    end
                else
                    if debugEnabled then
                        DebugMessage("Player " .. tostring(otherCritData.playerName) .. " is not in our group - ignoring crit", debugEnabled)
                    end
                end
            else
                if debugEnabled then
                    DebugMessage("No crit data parsed from message: " .. tostring(message), debugEnabled)
                end
            end
        end
    end
end

-- Set up event handler (1.12 style)
CriTrack:SetScript("OnEvent", OnEvent)
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
CriTrack:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_BUFF")
CriTrack:RegisterEvent("CHAT_MSG_COMBAT_PARTY_HITS")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
CriTrack:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")

-- Slash commands (1.12 compatible)
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = nil
    if Utils and Utils.GetValidChannel then
        newChannel = Utils.GetValidChannel(msg)
    else
        -- Fallback channel validation
        local channels = {"SAY", "PARTY", "RAID", "GUILD", "YELL"}
        local upperMsg = string.upper(msg or "")
        for _, channel in channels do
            if upperMsg == channel then
                newChannel = channel
                break
            end
        end
    end
    
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
        local stats = {enabled = false, participantCount = 0}
        if CompetitionManager then
            stats = CompetitionManager.GetStats()
        end
        
        local healerStats = nil
        if HealerTracker then
            healerStats = HealerTracker.GetStats()
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Debug Info ===")
        DEFAULT_CHAT_FRAME:AddMessage("Frame: " .. CriTrack:GetName())
        DEFAULT_CHAT_FRAME:AddMessage("Highest Crit: " .. highestCrit)
        DEFAULT_CHAT_FRAME:AddMessage("Highest Crit Spell: " .. highestCritSpell)
        DEFAULT_CHAT_FRAME:AddMessage("Channel: " .. announcementChannel)
        DEFAULT_CHAT_FRAME:AddMessage("Debug Enabled: " .. tostring(debugEnabled))
        DEFAULT_CHAT_FRAME:AddMessage("Debug Mode: " .. debugMode)
        DEFAULT_CHAT_FRAME:AddMessage("Competition Mode: " .. tostring(stats.enabled))
        if stats.enabled then
            DEFAULT_CHAT_FRAME:AddMessage("Competition Entries: " .. stats.participantCount)
            DEFAULT_CHAT_FRAME:AddMessage("Auto-detecting other players' crits: YES")
        else
            DEFAULT_CHAT_FRAME:AddMessage("Auto-detecting other players' crits: NO (enable competition mode)")
        end
        DEFAULT_CHAT_FRAME:AddMessage("Modules Loaded:")
        DEFAULT_CHAT_FRAME:AddMessage("  Utils: " .. tostring(Utils ~= nil))
        DEFAULT_CHAT_FRAME:AddMessage("  CombatLogParser: " .. tostring(CombatLogParser ~= nil))
        DEFAULT_CHAT_FRAME:AddMessage("  CompetitionManager: " .. tostring(CompetitionManager ~= nil))
        DEFAULT_CHAT_FRAME:AddMessage("  HealerTracker: " .. tostring(HealerTracker ~= nil))
        if healerStats then
            DEFAULT_CHAT_FRAME:AddMessage("Healer Mode: " .. tostring(healerStats.enabled))
            DEFAULT_CHAT_FRAME:AddMessage("Healer Group Mode: " .. tostring(healerStats.groupMode))
            if healerStats.enabled then
                DEFAULT_CHAT_FRAME:AddMessage("Personal Heal Record: " .. healerStats.personalRecord.amount .. " (" .. healerStats.personalRecord.spell .. ")")
                if healerStats.groupMode then
                    DEFAULT_CHAT_FRAME:AddMessage("Group Heal Record: " .. healerStats.groupRecord.amount .. " (" .. healerStats.groupRecord.spell .. " by " .. healerStats.groupRecord.caster .. ")")
                end
            end
        end
        local playerName = "Unknown"
        if Utils and Utils.GetPlayerName then
            playerName = Utils.GetPlayerName()
        else
            playerName = UnitName("player") or "Unknown"
        end
        DEFAULT_CHAT_FRAME:AddMessage("Player Name: " .. playerName)
        DEFAULT_CHAT_FRAME:AddMessage("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
        if CriTrackDB then
            DEFAULT_CHAT_FRAME:AddMessage("Saved Crit: " .. tostring(CriTrackDB.highestCrit or 0))
            DEFAULT_CHAT_FRAME:AddMessage("Saved Spell: " .. tostring(CriTrackDB.highestCritSpell or "Unknown"))
        end
        DEFAULT_CHAT_FRAME:AddMessage("Events: PLAYER_LOGIN, CHAT_MSG_COMBAT_SELF_HITS, CHAT_MSG_SPELL_SELF_DAMAGE, CHAT_MSG_SPELL_SELF_BUFF, CHAT_MSG_COMBAT_FRIENDLY_BUFF, CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF, CHAT_MSG_SPELL_PARTY_BUFF, CHAT_MSG_COMBAT_PARTY_HITS, CHAT_MSG_SPELL_PARTY_DAMAGE, CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS, CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
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

-- Test command to manually set a heal (for debugging)
SLASH_CRITHEALTEST1 = "/crithealtest"
SlashCmdList["CRITHEALTEST"] = function(msg)
    if not HealerTracker then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Healer module not loaded!")
        return
    end
    
    if not HealerTracker.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Enable healer tracking first with /critheal on")
        return
    end
    
    local testAmount = tonumber(msg) or 100
    local playerName = "You"
    if Utils and Utils.GetPlayerName then
        playerName = Utils.GetPlayerName()
    else
        playerName = UnitName("player") or "You"
    end
    
    local testHealData = {
        amount = testAmount,
        spell = "Test Heal",
        target = "Test Target",
        caster = playerName,
        isCritical = true
    }
    
    local personalRecord = HealerTracker.UpdatePersonalRecord(testHealData)
    local groupResult = {updated = false}
    
    if HealerTracker.IsGroupModeEnabled() then
        groupResult = HealerTracker.UpdateGroupRecord(testHealData)
    end
    
    if personalRecord or groupResult.updated then
        CriTrackDB.healerData = HealerTracker.GetData()
        
        if personalRecord then
            SendChatMessage("New heal record: " .. testAmount .. " (Test Heal) on Test Target!", announcementChannel)
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test heal set to " .. testAmount)
        else
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test heal amount must be higher than current record")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test heal amount must be higher than current record")
    end
end

-- Test command for other player's crit parsing
SLASH_CRITTESTOTHER1 = "/crittestother"
SlashCmdList["CRITTESTOTHER"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Enable competition mode first with /critcomp on")
        return
    end
    
    -- Parse test message format: PlayerName Amount [SpellName]
    local words = {}
    if Utils and Utils.ParseWords then
        words = Utils.ParseWords(msg)
    else
        -- Fallback parsing for Lua 5.0 compatibility
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
    end
    
    if table.getn(words) < 2 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /crittestother PlayerName Amount [SpellName]")
        DEFAULT_CHAT_FRAME:AddMessage("Example: /crittestother Gandalf 450 Fireball")
        return
    end
    
    local testPlayer = words[1]
    local testAmount = tonumber(words[2])
    local testSpell = words[3] or "Test Spell"
    
    if not testAmount or testAmount <= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Invalid amount. Must be a positive number.")
        return
    end
    
    -- Simulate other player's crit
    local otherCritData = {
        playerName = testPlayer,
        amount = testAmount,
        spell = testSpell,
        isCritical = true
    }
    
    local competitionResult = CompetitionManager.UpdateLeaderboard(otherCritData.playerName, otherCritData.amount, otherCritData.spell)
    
    if competitionResult.updated then
        CriTrackDB.competitionData = CompetitionManager.GetData()
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test - " .. testPlayer .. " crit for " .. testAmount .. " (" .. testSpell .. ")")
        
        if competitionResult.isNewLeader then
            SendChatMessage("New group crit leader: " .. testAmount .. " (" .. testSpell .. ") by " .. testPlayer .. "!", announcementChannel)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Test crit was not higher than " .. testPlayer .. "'s current record")
    end
end

-- Test command for parsing combat messages
SLASH_CRITTESTPARSE1 = "/crittestparse"
SlashCmdList["CRITTESTPARSE"] = function(msg)
    if not CombatLogParser then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: CombatLogParser module not loaded!")
        return
    end
    
    if not msg or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /crittestparse <combat message>")
        DEFAULT_CHAT_FRAME:AddMessage("Examples:")
        DEFAULT_CHAT_FRAME:AddMessage("  /crittestparse Fred's Arcane Explosion crits Kobold for 245 damage")
        DEFAULT_CHAT_FRAME:AddMessage("  /crittestparse Gandalf's Fireball crits Orc for 456 damage")
        DEFAULT_CHAT_FRAME:AddMessage("  /crittestparse Alice crits Rat for 123 damage")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Testing message parsing...")
    DEFAULT_CHAT_FRAME:AddMessage("Input: " .. msg)
    
    local otherCritData = CombatLogParser.ParseOtherPlayerCrit(msg)
    
    if otherCritData then
        DEFAULT_CHAT_FRAME:AddMessage("✓ Successfully parsed:")
        DEFAULT_CHAT_FRAME:AddMessage("  Player: '" .. tostring(otherCritData.playerName) .. "'")
        DEFAULT_CHAT_FRAME:AddMessage("  Spell: '" .. tostring(otherCritData.spell) .. "'")
        DEFAULT_CHAT_FRAME:AddMessage("  Amount: " .. tostring(otherCritData.amount))
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ Failed to parse - no crit data found")
        DEFAULT_CHAT_FRAME:AddMessage("  Check if message contains 'crit' and expected format")
    end
end

-- Help command to show all available commands
SLASH_CRITHELP1 = "/crithelp"
SlashCmdList["CRITHELP"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== CriTrack Help ===|r")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Core Commands:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crithigh|r - Show your current highest crit")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critreset|r - Reset your personal crit record to 0")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critchannel <channel>|r - Set announcement channel")
    DEFAULT_CHAT_FRAME:AddMessage("    |cffccccccChannels: say, party, raid, guild, yell|r")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Competition Mode:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcomp|r - Show competition status")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcomp on|r - Enable group crit tracking")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcomp off|r - Disable competition mode")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcomp reset|r - Clear competition leaderboard")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critadd <player> <amount> [spell]|r - Add player's crit")
    DEFAULT_CHAT_FRAME:AddMessage("    |cffccccccExample: /critadd Gandalf 450 Fireball|r")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Leaderboard:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critboard|r - Show leaderboard in chat")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critboard announce|r - Share leaderboard publicly")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcheckdupes|r - Check for duplicate players")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcleandupes|r - Remove duplicate player entries")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Healer Tracking:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critheal|r - Show healer tracking status")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critheal on/off|r - Enable/disable heal tracking")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critheal group/groupoff|r - Enable/disable group heal tracking")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critheal reset|r - Reset all heal records")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Debug & Testing:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug|r - Show debug information")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug on/off|r - Enable/disable debug messages")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug player/party|r - Set debug scope")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittest <amount>|r - Set test crit for debugging")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crithealtest <amount>|r - Set test heal for debugging")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestother <player> <amount> [spell]|r - Test other player crit detection")
    DEFAULT_CHAT_FRAME:AddMessage("    |cffccccccExample: /crittestother Gandalf 450 Fireball|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestparse <message>|r - Test combat message parsing")
    DEFAULT_CHAT_FRAME:AddMessage("    |cffccccccExample: /crittestparse Fred's Arcane Explosion crits Kobold for 245 damage|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestall|r - Run comprehensive parsing tests")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestheal|r - Run healing message parsing tests")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critcheckhealing|r - Debug healing system thoroughly")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestdupes|r - Test duplicate player prevention")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittestparse <message>|r - Test parsing of combat messages")
    DEFAULT_CHAT_FRAME:AddMessage("    |cffccccccExample: /crittestparse 'Gandalf's Fireball crits Orc for 456 damage'|r")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffccccccFor detailed help on any command, try the command without arguments.|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00==================|r")
end

-- Add player crit to competition (manual entry)
SLASH_CRITADD1 = "/critadd"
SlashCmdList["CRITADD"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode is not enabled. Use /critcomp on to enable it.")
        return
    end
    
    -- Parse the command using Utils
    local parsed = nil
    if Utils and Utils.ParseCommand then
        parsed = Utils.ParseCommand(msg, "player_amount_spell")
    else
        -- Fallback parsing for Lua 5.0 compatibility
        local words = {}
        if Utils and Utils.ParseWords then
            words = Utils.ParseWords(msg)
        else
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
        end
        if table.getn(words) >= 2 then
            parsed = {
                playerName = words[1],
                amount = tonumber(words[2]),
                spellName = words[3] or "Unknown"
            }
        end
    end
    
    if not parsed or not parsed.playerName or not parsed.amount then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /critadd PlayerName Amount [SpellName]")
        DEFAULT_CHAT_FRAME:AddMessage("Example: /critadd Gandalf 450 Fireball")
        return
    end
    
    local critAmount = parsed.amount
    if critAmount <= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Invalid amount. Must be a positive number.")
        return
    end
    
    -- Update competition leaderboard
    local competitionResult = CompetitionManager.UpdateLeaderboard(parsed.playerName, critAmount, parsed.spellName)
    
    if competitionResult.updated then
        -- Save updated data
        CriTrackDB.competitionData = CompetitionManager.GetData()
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Added " .. parsed.playerName .. "'s crit: " .. critAmount .. " (" .. parsed.spellName .. ")")
        
        -- Announce if there's a leadership change
        if competitionResult.leadershipChanged then
            SendChatMessage("New group crit leader: " .. critAmount .. " (" .. parsed.spellName .. ") by " .. parsed.playerName .. "!", announcementChannel)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: " .. parsed.playerName .. "'s crit (" .. critAmount .. ") was not higher than their current record.")
    end
end

-- Competition mode command
SLASH_CRITCOMPETITION1 = "/critcompetition"
SLASH_CRITCOMPETITION2 = "/critcomp"
SlashCmdList["CRITCOMPETITION"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not msg or msg == "" then
        -- Show current competition status
        local stats = CompetitionManager.GetStats()
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Competition Mode ===")
        DEFAULT_CHAT_FRAME:AddMessage("Status: " .. (stats.enabled and "ENABLED" or "DISABLED"))
        if stats.enabled then
            if stats.leader then
                DEFAULT_CHAT_FRAME:AddMessage("Current Leader: " .. stats.leader.playerName .. " - " .. stats.leader.critAmount .. " (" .. stats.leader.spellName .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("No competition data yet")
            end
            DEFAULT_CHAT_FRAME:AddMessage("Participants: " .. stats.participantCount)
        end
        DEFAULT_CHAT_FRAME:AddMessage("===============================")
    elseif msg == "on" or msg == "enable" then
        CompetitionManager.SetMode(true)
        CriTrackDB.competitionMode = true
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode enabled! Now auto-detecting party/group crits.")
    elseif msg == "off" or msg == "disable" then
        CompetitionManager.SetMode(false)
        CriTrackDB.competitionMode = false
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode disabled.")
    elseif msg == "reset" or msg == "clear" then
        CompetitionManager.Reset()
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
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode is not enabled. Use /critcomp on to enable it.")
        return
    end
    
    local sortedData = CompetitionManager.GetSortedLeaderboard()
    if table.getn(sortedData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: No competition data available yet.")
        return
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
            if Utils and Utils.FormatMessage then
                if i == 1 then medal = Utils.FormatMessage("🥇", "yellow") .. " "
                elseif i == 2 then medal = Utils.FormatMessage("🥈", "gray") .. " "
                elseif i == 3 then medal = Utils.FormatMessage("🥉", "yellow") .. " "
                end
            else
                if i == 1 then medal = "|cffff9900[1st]|r "
                elseif i == 2 then medal = "|cffcccccc[2nd]|r "
                elseif i == 3 then medal = "|cffff9900[3rd]|r "
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(medal .. i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
        end
        DEFAULT_CHAT_FRAME:AddMessage("===========================")
        DEFAULT_CHAT_FRAME:AddMessage("Use '/critboard announce' to share in " .. string.lower(announcementChannel))
    end
end

-- Healer tracking commands
SLASH_CRITHEAL1 = "/critheal"
SLASH_CRITHEAL2 = "/healer"
SlashCmdList["CRITHEAL"] = function(msg)
    if not modulesLoaded then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon still loading, please wait...")
        return
    end
    
    if not HealerTracker then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Healer module not loaded!")
        DEFAULT_CHAT_FRAME:AddMessage("Try running '/critdebug' to see module loading status")
        return
    end
    
    if not msg or msg == "" then
        -- Show current healer status
        local stats = HealerTracker.GetStats()
        DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Healer Mode ===")
        DEFAULT_CHAT_FRAME:AddMessage("Status: " .. (stats.enabled and "ENABLED" or "DISABLED"))
        DEFAULT_CHAT_FRAME:AddMessage("Group Mode: " .. (stats.groupMode and "ENABLED" or "DISABLED"))
        if stats.enabled then
            DEFAULT_CHAT_FRAME:AddMessage("Personal Best: " .. HealerTracker.FormatPersonalRecord())
            if stats.groupMode then
                DEFAULT_CHAT_FRAME:AddMessage("Group Best: " .. HealerTracker.FormatGroupRecord())
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("===========================")
    elseif msg == "on" or msg == "enable" then
        HealerTracker.SetEnabled(true)
        CriTrackDB.healerEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Healer tracking enabled!")
    elseif msg == "off" or msg == "disable" then
        HealerTracker.SetEnabled(false)
        CriTrackDB.healerEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Healer tracking disabled.")
    elseif msg == "group" or msg == "groupon" then
        if not HealerTracker.IsEnabled() then
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Enable healer tracking first with /critheal on")
            return
        end
        HealerTracker.SetGroupMode(true)
        CriTrackDB.healerGroupMode = true
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Group healer tracking enabled!")
    elseif msg == "groupoff" then
        HealerTracker.SetGroupMode(false)
        CriTrackDB.healerGroupMode = false
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Group healer tracking disabled.")
    elseif msg == "reset" then
        HealerTracker.ResetAll()
        CriTrackDB.healerData = HealerTracker.GetData()
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: All heal records reset!")
    elseif msg == "resetpersonal" then
        HealerTracker.ResetPersonal()
        CriTrackDB.healerData = HealerTracker.GetData()
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Personal heal record reset!")
    elseif msg == "resetgroup" then
        HealerTracker.ResetGroup()
        CriTrackDB.healerData = HealerTracker.GetData()
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Group heal record reset!")
    else
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack Healer Usage:")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal - Show healer status")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal on - Enable healer tracking")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal off - Disable healer tracking")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal group - Enable group heal tracking")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal groupoff - Disable group heal tracking")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal reset - Reset all heal records")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal resetpersonal - Reset personal heal record")
        DEFAULT_CHAT_FRAME:AddMessage("  /critheal resetgroup - Reset group heal record")
    end
end

-- Comprehensive parsing test command
SLASH_CRITTESTALL1 = "/crittestall"
SlashCmdList["CRITTESTALL"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Comprehensive Parsing Test ===")
    
    -- Test 1: Self critical hit parsing
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Test 1: Self Critical Hit Parsing")
    local testMessages = {
        "Your Fireball crits Orc for 456 damage.",
        "Your Frostbolt crits Kobold for 234 damage.",
        "You crit Rat for 123 damage."
    }
    
    for i = 1, table.getn(testMessages) do
        local testMsg = testMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("  Testing: " .. testMsg)
        if CombatLogParser then
            local result = CombatLogParser.ParseCriticalHit(testMsg)
            if result then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ Parsed: " .. result.amount .. " (" .. result.spell .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ Failed to parse")
            end
        end
    end
    
    -- Test 2: Other player critical hit parsing
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Test 2: Other Player Critical Hit Parsing")
    local otherTestMessages = {
        "Fred's Arcane Explosion crits Kobold for 245 damage.",
        "Gandalf's Fireball crits Orc for 456 damage.",
        "Alice crits Rat for 123 damage."
    }
    
    for i = 1, table.getn(otherTestMessages) do
        local testMsg = otherTestMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("  Testing: " .. testMsg)
        if CombatLogParser then
            local result = CombatLogParser.ParseOtherPlayerCrit(testMsg)
            if result then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ Parsed: " .. result.playerName .. " - " .. result.amount .. " (" .. result.spell .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ Failed to parse")
            end
        end
    end
    
    -- Test 3: Self critical heal parsing
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Test 3: Self Critical Heal Parsing")
    local healTestMessages = {
        "Your Heal critically heals Alice for 456.",
        "Your Greater Heal heals Bob for 234. (Critical)",
        "You critically heal Charlie for 123."
    }
    
    for i = 1, table.getn(healTestMessages) do
        local testMsg = healTestMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("  Testing: " .. testMsg)
        if HealerTracker then
            local result = HealerTracker.ParseCriticalHeal(testMsg)
            if result then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ Parsed: " .. result.amount .. " (" .. result.spell .. " on " .. result.target .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ Failed to parse")
            end
        end
    end
    
    -- Test 4: Group critical heal parsing
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Test 4: Group Critical Heal Parsing")
    local groupHealTestMessages = {
        "Priest's Heal critically heals Alice for 456.",
        "Paladin's Greater Heal heals Bob for 234. (Critical)",
        "Druid critically heals Charlie for 123."
    }
    
    for i = 1, table.getn(groupHealTestMessages) do
        local testMsg = groupHealTestMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("  Testing: " .. testMsg)
        if HealerTracker then
            local result = HealerTracker.ParseGroupCriticalHeal(testMsg)
            if result then
                DEFAULT_CHAT_FRAME:AddMessage("    ✓ Parsed: " .. result.caster .. " - " .. result.amount .. " (" .. result.spell .. " on " .. result.target .. ")")
            else
                DEFAULT_CHAT_FRAME:AddMessage("    ✗ Failed to parse")
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Test completed. Check results above.")
    DEFAULT_CHAT_FRAME:AddMessage("================================")
end

-- Specific test command for Fred's Arcane Explosion issue
SLASH_CRITTESTFRED1 = "/crittestfred"
SlashCmdList["CRITTESTFRED"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== Testing Fred's Arcane Explosion Issue ===")
    
    local testMessage = "Fred's Arcane Explosion crits Kobold for 245 damage."
    DEFAULT_CHAT_FRAME:AddMessage("Testing message: " .. testMessage)
    
    if CombatLogParser then
        local result = CombatLogParser.ParseOtherPlayerCrit(testMessage)
        if result then
            DEFAULT_CHAT_FRAME:AddMessage("✓ SUCCESS:")
            DEFAULT_CHAT_FRAME:AddMessage("  Player Name: '" .. result.playerName .. "'")
            DEFAULT_CHAT_FRAME:AddMessage("  Spell Name: '" .. result.spell .. "'")
            DEFAULT_CHAT_FRAME:AddMessage("  Damage: " .. result.amount)
            
            if result.playerName == "Fred" and result.spell == "Arcane Explosion" then
                DEFAULT_CHAT_FRAME:AddMessage("✓ PERFECT: Names parsed correctly!")
            else
                DEFAULT_CHAT_FRAME:AddMessage("✗ ISSUE: Expected Fred/Arcane Explosion but got " .. result.playerName .. "/" .. result.spell)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("✗ FAILED: Could not parse the message")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ ERROR: CombatLogParser module not loaded")
    end
    
    -- Test variations
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Testing similar variations:")
    
    local variations = {
        "Fred's Fireball crits Orc for 456 damage.",
        "Gandalf's Shadow Bolt crits Skeleton for 321 damage.",
        "Alice's Ice Blast crits Rat for 123 damage."
    }
    
    for i = 1, table.getn(variations) do
        local testMsg = variations[i]
        DEFAULT_CHAT_FRAME:AddMessage("  " .. testMsg)
        
        if CombatLogParser then
            local result = CombatLogParser.ParseOtherPlayerCrit(testMsg)
            if result then
                DEFAULT_CHAT_FRAME:AddMessage("    → " .. result.playerName .. " cast " .. result.spell .. " for " .. result.amount)
            else
                DEFAULT_CHAT_FRAME:AddMessage("    → Failed to parse")
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=======================================")
end

-- Test command specifically for healing message parsing
SLASH_CRITTESTHEAL1 = "/crittestheal"
SlashCmdList["CRITTESTHEAL"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== Testing Healing Message Parsing ===")
    
    -- Test various WoW 1.12 healing message formats
    local healingMessages = {
        -- Self healing messages
        "Your Heal heals Alice for 234.",
        "Your Greater Heal heals Bob for 456.", 
        "Your Flash Heal heals Charlie for 123.",
        "Your Heal critically heals Alice for 468.",
        "Your Greater Heal critically heals Bob for 912.",
        "Your Flash Heal critically heals Charlie for 246.",
        
        -- Alternative formats
        "Your Heal heals Alice for 234 points.",
        "Your Greater Heal critically heals Bob for 912 points.",
        "You heal Alice for 234.",
        "You critically heal Alice for 468.",
        
        -- Group healing messages
        "Priest's Heal heals Alice for 234.",
        "Paladin's Greater Heal heals Bob for 456.",
        "Druid's Heal critically heals Charlie for 468.",
        "Shaman's Lesser Heal critically heals David for 234."
    }
    
    DEFAULT_CHAT_FRAME:AddMessage("Testing " .. table.getn(healingMessages) .. " healing message formats:")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    
    for i = 1, table.getn(healingMessages) do
        local testMsg = healingMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("Test " .. i .. ": " .. testMsg)
        
        if HealerTracker then
            -- Test self healing
            local selfResult = HealerTracker.ParseCriticalHeal(testMsg)
            if selfResult then
                DEFAULT_CHAT_FRAME:AddMessage("  ✓ Self Heal: " .. selfResult.amount .. " (" .. selfResult.spell .. " on " .. selfResult.target .. ")")
            else
                -- Test group healing
                local groupResult = HealerTracker.ParseGroupCriticalHeal(testMsg)
                if groupResult then
                    DEFAULT_CHAT_FRAME:AddMessage("  ✓ Group Heal: " .. groupResult.caster .. " - " .. groupResult.amount .. " (" .. groupResult.spell .. " on " .. groupResult.target .. ")")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("  ✗ Failed to parse")
                end
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ HealerTracker not loaded")
        end
        DEFAULT_CHAT_FRAME:AddMessage(" ")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== Test Complete ===")
end

-- Test command to check for duplicates and clean up leaderboard
SLASH_CRITCHECKDUPES1 = "/critcheckdupes"
SlashCmdList["CRITCHECKDUPES"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode not enabled")
        return
    end
    
    local competitionData = CompetitionManager.GetData()
    if not competitionData or table.getn(competitionData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: No competition data to check")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== Checking for Duplicate Players ===")
    DEFAULT_CHAT_FRAME:AddMessage("Current entries: " .. table.getn(competitionData))
    
    -- Show current leaderboard
    for i = 1, table.getn(competitionData) do
        local entry = competitionData[i]
        DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
    end
    
    -- Find duplicates
    local duplicates = {}
    local playerCounts = {}
    
    for i = 1, table.getn(competitionData) do
        local entry = competitionData[i]
        local playerName = entry.playerName
        
        if playerCounts[playerName] then
            playerCounts[playerName] = playerCounts[playerName] + 1
            if not duplicates[playerName] then
                duplicates[playerName] = {}
            end
            table.insert(duplicates[playerName], {index = i, amount = entry.critAmount, spell = entry.spellName})
        else
            playerCounts[playerName] = 1
        end
    end
    
    -- Report duplicates
    local foundDuplicates = false
    for playerName, count in pairs(playerCounts) do
        if count > 1 then
            foundDuplicates = true
            DEFAULT_CHAT_FRAME:AddMessage("DUPLICATE: " .. playerName .. " appears " .. count .. " times")
            if duplicates[playerName] then
                for i = 1, table.getn(duplicates[playerName]) do
                    local dup = duplicates[playerName][i]
                    DEFAULT_CHAT_FRAME:AddMessage("  Entry " .. dup.index .. ": " .. dup.amount .. " (" .. dup.spell .. ")")
                end
            end
        end
    end
    
    if not foundDuplicates then
        DEFAULT_CHAT_FRAME:AddMessage("✓ No duplicates found - leaderboard is clean!")
    else
        DEFAULT_CHAT_FRAME:AddMessage("✗ Duplicates found! Use '/critcleandupes' to fix")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("====================================")
end

-- Command to clean up duplicate entries
SLASH_CRITCLEANDUPES1 = "/critcleandupes"
SlashCmdList["CRITCLEANDUPES"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode not enabled")
        return
    end
    
    local competitionData = CompetitionManager.GetData()
    if not competitionData or table.getn(competitionData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: No competition data to clean")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== Cleaning Duplicate Players ===")
    
    -- Create a new clean leaderboard
    local cleanData = {}
    local playerHighest = {}
    
    -- Find the highest crit for each player
    for i = 1, table.getn(competitionData) do
        local entry = competitionData[i]
        local playerName = entry.playerName
        
        if not playerHighest[playerName] or entry.critAmount > playerHighest[playerName].critAmount then
            playerHighest[playerName] = {
                playerName = playerName,
                critAmount = entry.critAmount,
                spellName = entry.spellName
            }
        end
    end
    
    -- Convert back to array
    for playerName, entry in pairs(playerHighest) do
        table.insert(cleanData, entry)
    end
    
    local originalCount = table.getn(competitionData)
    local cleanCount = table.getn(cleanData)
    
    -- Update the competition data
    CompetitionManager.competitionData = cleanData
    CriTrackDB.competitionData = cleanData
    
    DEFAULT_CHAT_FRAME:AddMessage("Cleaned leaderboard:")
    DEFAULT_CHAT_FRAME:AddMessage("  Original entries: " .. originalCount)
    DEFAULT_CHAT_FRAME:AddMessage("  Clean entries: " .. cleanCount)
    DEFAULT_CHAT_FRAME:AddMessage("  Removed: " .. (originalCount - cleanCount) .. " duplicates")
    
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Updated leaderboard:")
    for i = 1, table.getn(cleanData) do
        local entry = cleanData[i]
        DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=================================")
end

-- Test command to simulate duplicate entries and verify prevention
SLASH_CRITTESTDUPES1 = "/crittestdupes"
SlashCmdList["CRITTESTDUPES"] = function(msg)
    if not CompetitionManager then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition module not loaded!")
        return
    end
    
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Enable competition mode first with /critcomp on")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== Testing Duplicate Prevention ===")
    
    -- Clear current data for clean test
    CompetitionManager.Reset()
    DEFAULT_CHAT_FRAME:AddMessage("Cleared leaderboard for test")
    
    -- Test adding same player multiple times with different spells/amounts
    local testData = {
        {player = "Fred", amount = 100, spell = "Auto Attack"},
        {player = "Fred", amount = 200, spell = "Fireball"},      -- Should replace auto attack
        {player = "Fred", amount = 150, spell = "Frostbolt"},     -- Should not replace fireball (lower)
        {player = "Alice", amount = 300, spell = "Lightning Bolt"},
        {player = "Alice", amount = 250, spell = "Auto Attack"},   -- Should not replace lightning bolt
        {player = "Bob", amount = 180, spell = "Arcane Explosion"},
        {player = "Fred", amount = 350, spell = "Pyroblast"}      -- Should replace fireball (higher)
    }
    
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Adding test entries:")
    
    for i = 1, table.getn(testData) do
        local test = testData[i]
        DEFAULT_CHAT_FRAME:AddMessage("Adding: " .. test.player .. " - " .. test.amount .. " (" .. test.spell .. ")")
        
        local result = CompetitionManager.UpdateLeaderboard(test.player, test.amount, test.spell)
        if result.updated then
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ Updated (New leader: " .. tostring(result.isNewLeader) .. ")")
        else
            DEFAULT_CHAT_FRAME:AddMessage("  ✗ Not updated (amount too low)")
        end
    end
    
    -- Show final leaderboard
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Final leaderboard:")
    
    local sortedData = CompetitionManager.GetSortedLeaderboard()
    for i = 1, table.getn(sortedData) do
        local entry = sortedData[i]
        DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Expected result:")
    DEFAULT_CHAT_FRAME:AddMessage("1. Fred: 350 (Pyroblast)")
    DEFAULT_CHAT_FRAME:AddMessage("2. Alice: 300 (Lightning Bolt)")
    DEFAULT_CHAT_FRAME:AddMessage("3. Bob: 180 (Arcane Explosion)")
    DEFAULT_CHAT_FRAME:AddMessage("=================================")
end

-- Test command to debug healing system thoroughly
SLASH_CRITCHECKHEALING1 = "/critcheckhealing"
SlashCmdList["CRITCHECKHEALING"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("=== CriTrack Healing System Debug ===")
    
    -- Check if HealerTracker is loaded
    if not HealerTracker then
        DEFAULT_CHAT_FRAME:AddMessage("✗ HealerTracker module not loaded!")
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("✓ HealerTracker module loaded")
    
    -- Check if healing is enabled
    local enabled = HealerTracker.IsEnabled()
    DEFAULT_CHAT_FRAME:AddMessage("Healing tracking enabled: " .. tostring(enabled))
    if not enabled then
        DEFAULT_CHAT_FRAME:AddMessage("→ Use '/critheal on' to enable healing tracking")
    end
    
    -- Check group mode
    local groupMode = HealerTracker.IsGroupModeEnabled()
    DEFAULT_CHAT_FRAME:AddMessage("Group healing tracking enabled: " .. tostring(groupMode))
    if not groupMode then
        DEFAULT_CHAT_FRAME:AddMessage("→ Use '/critheal group' to enable group healing tracking")
    end
    
    -- Show current records
    local stats = HealerTracker.GetStats()
    DEFAULT_CHAT_FRAME:AddMessage("Personal heal record: " .. HealerTracker.FormatPersonalRecord())
    DEFAULT_CHAT_FRAME:AddMessage("Group heal record: " .. HealerTracker.FormatGroupRecord())
    
    -- Test parsing with sample messages
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Testing healing message parsing:")
    
    local testMessages = {
        "Your Heal critically heals TestTarget for 500.",
        "Your Greater Heal heals TestTarget for 300.",
        "Player's Heal critically heals TestTarget for 600."
    }
    
    for i = 1, table.getn(testMessages) do
        local msg = testMessages[i]
        DEFAULT_CHAT_FRAME:AddMessage("Test " .. i .. ": " .. msg)
        
        -- Test self healing
        local selfResult = HealerTracker.ParseCriticalHeal(msg)
        if selfResult then
            local critText = selfResult.isCritical and " (CRITICAL)" or " (regular)"
            DEFAULT_CHAT_FRAME:AddMessage("  ✓ Self: " .. selfResult.amount .. " (" .. selfResult.spell .. ")" .. critText)
        else
            -- Test group healing
            local groupResult = HealerTracker.ParseGroupCriticalHeal(msg)
            if groupResult then
                local critText = groupResult.isCritical and " (CRITICAL)" or " (regular)"
                DEFAULT_CHAT_FRAME:AddMessage("  ✓ Group: " .. groupResult.caster .. " - " .. groupResult.amount .. " (" .. groupResult.spell .. ")" .. critText)
            else
                DEFAULT_CHAT_FRAME:AddMessage("  ✗ Failed to parse")
            end
        end
    end
    
    -- Show registered events
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("Healing events registered:")
    DEFAULT_CHAT_FRAME:AddMessage("  - CHAT_MSG_SPELL_SELF_BUFF (your heals)")
    DEFAULT_CHAT_FRAME:AddMessage("  - CHAT_MSG_SPELL_PARTY_BUFF (party heals)")
    DEFAULT_CHAT_FRAME:AddMessage("  - CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF (friendly heals)")
    DEFAULT_CHAT_FRAME:AddMessage("  - CHAT_MSG_COMBAT_FRIENDLY_BUFF (misc healing)")
    
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("If heals still don't work:")
    DEFAULT_CHAT_FRAME:AddMessage("1. Enable debug mode: /critdebug on")
    DEFAULT_CHAT_FRAME:AddMessage("2. Enable healer tracking: /critheal on")
    DEFAULT_CHAT_FRAME:AddMessage("3. Cast a heal and check debug output")
    DEFAULT_CHAT_FRAME:AddMessage("4. Use /crittestheal to test message parsing")
    
    DEFAULT_CHAT_FRAME:AddMessage("=== End Debug ===")
end

-- Test command to check group membership
SLASH_CRITTESTGROUP1 = "/crittestgroup"
SlashCmdList["CRITTESTGROUP"] = function(msg)
    if not msg or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Usage - /crittestgroup <playername>")
        DEFAULT_CHAT_FRAME:AddMessage("Example: /crittestgroup Gandalf")
        return
    end
    
    local playerName = msg
    DEFAULT_CHAT_FRAME:AddMessage("=== Testing Group Membership ===")
    DEFAULT_CHAT_FRAME:AddMessage("Player: " .. playerName)
    
    if Utils and Utils.IsPlayerInGroup then
        local isInGroup = Utils.IsPlayerInGroup(playerName)
        DEFAULT_CHAT_FRAME:AddMessage("Is in group: " .. tostring(isInGroup))
        
        -- Show party/raid info
        if GetNumPartyMembers then
            local numParty = GetNumPartyMembers()
            DEFAULT_CHAT_FRAME:AddMessage("Party members: " .. tostring(numParty))
            for i = 1, numParty do
                local partyMember = UnitName("party" .. i)
                DEFAULT_CHAT_FRAME:AddMessage("  Party " .. i .. ": " .. tostring(partyMember))
            end
        end
        
        if GetNumRaidMembers then
            local numRaid = GetNumRaidMembers()
            DEFAULT_CHAT_FRAME:AddMessage("Raid members: " .. tostring(numRaid))
            for i = 1, numRaid do
                local raidMember = UnitName("raid" .. i)
                DEFAULT_CHAT_FRAME:AddMessage("  Raid " .. i .. ": " .. tostring(raidMember))
            end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: Utils.IsPlayerInGroup not available")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("==============================")
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon loaded for 1.12 Vanilla!")
