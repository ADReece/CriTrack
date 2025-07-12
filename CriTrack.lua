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

-- Module references will be available after .toc loads them
local DebugMessage

-- Initialize modules when addon loads
local function InitializeModules()
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
        
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack v2.0 loaded! Current record: " .. highestCrit .. spellText .. " (Channel: " .. announcementChannel .. ")" .. debugText .. competitionText)
        
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
    end
end

-- Set up event handler (1.12 style)
CriTrack:SetScript("OnEvent", OnEvent)
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
CriTrack:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

-- Slash commands (1.12 compatible)
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = Utils.GetValidChannel(msg)
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
        local stats = CompetitionManager.GetStats()
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
        end
        DEFAULT_CHAT_FRAME:AddMessage("Player Name: " .. Utils.GetPlayerName())
        DEFAULT_CHAT_FRAME:AddMessage("CriTrackDB exists: " .. tostring(CriTrackDB ~= nil))
        if CriTrackDB then
            DEFAULT_CHAT_FRAME:AddMessage("Saved Crit: " .. tostring(CriTrackDB.highestCrit or 0))
            DEFAULT_CHAT_FRAME:AddMessage("Saved Spell: " .. tostring(CriTrackDB.highestCritSpell or "Unknown"))
        end
        DEFAULT_CHAT_FRAME:AddMessage("Events: PLAYER_LOGIN, CHAT_MSG_COMBAT_SELF_HITS, CHAT_MSG_SPELL_SELF_DAMAGE")
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
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Debug & Testing:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug|r - Show debug information")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug on/off|r - Enable/disable debug messages")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/critdebug player/party|r - Set debug scope")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/crittest <amount>|r - Set test crit for debugging")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|cffccccccFor detailed help on any command, try the command without arguments.|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00==================|r")
end

-- Add player crit to competition (manual entry)
SLASH_CRITADD1 = "/critadd"
SlashCmdList["CRITADD"] = function(msg)
    if not CompetitionManager.IsEnabled() then
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode is not enabled. Use /critcomp on to enable it.")
        return
    end
    
    -- Parse the command using Utils
    local parsed = Utils.ParseCommand(msg, "player_amount_spell")
    
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
        DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Competition mode enabled! Group crit tracking active.")
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
            if i == 1 then medal = Utils.FormatMessage("🥇", "yellow") .. " "
            elseif i == 2 then medal = Utils.FormatMessage("🥈", "gray") .. " "
            elseif i == 3 then medal = Utils.FormatMessage("🥉", "yellow") .. " "
            end
            DEFAULT_CHAT_FRAME:AddMessage(medal .. i .. ". " .. entry.playerName .. ": " .. entry.critAmount .. " (" .. entry.spellName .. ")")
        end
        DEFAULT_CHAT_FRAME:AddMessage("===========================")
        DEFAULT_CHAT_FRAME:AddMessage("Use '/critboard announce' to share in " .. string.lower(announcementChannel))
    end
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Addon loaded for 1.12 Vanilla!")
