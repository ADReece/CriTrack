DEFAULT_CHAT_FRAME:AddMessage("CriTrack is being loaded...")

local CriTrack = CreateFrame("Frame")

CriTrackDB = CriTrackDB or {}
local highestCrit = 0
local announcementChannel = "SAY"

-- Normalize user input to valid chat channels
local function NormalizeChannel(input)
    local map = {
        say = "SAY",
        party = "PARTY",
        raid = "RAID",
        emote = "EMOTE",
        yell = "YELL",
        guild = "GUILD"
    }
    return map[string.lower(input or "")] or nil
end

-- Slash command to change the announcement channel
SLASH_CRITCHANNEL1 = "/critchannel"
SlashCmdList["CRITCHANNEL"] = function(msg)
    local newChannel = NormalizeChannel(msg)
    if newChannel then
        announcementChannel = newChannel
        CriTrackDB.announcementChannel = announcementChannel
        print("|cff33ff99CriTrack|r: Channel set to", announcementChannel)
    else
        print("|cff33ff99CriTrack|r usage: /critchannel say|party|raid|guild|yell|emote")
    end
end

-- Event handler
CriTrack:SetScript("OnEvent", function(self, event, ...)
    if event == "VARIABLES_LOADED" then
        highestCrit = CriTrackDB.highestCrit or 0
        announcementChannel = CriTrackDB.announcementChannel or "SAY"
        print("|cff33ff99CriTrack loaded!|r Current high score: " .. highestCrit .. ". Announcing in: " .. announcementChannel)
    elseif event == "UNIT_COMBAT" then
        local unit, action, damage, _, isCrit = ...
        if unit == "player" and isCrit == 1 then
            local critAmount = tonumber(damage)
            if critAmount and critAmount > highestCrit then
                highestCrit = critAmount
                CriTrackDB.highestCrit = highestCrit
                SendChatMessage("New crit highscore: " .. critAmount .. "!", announcementChannel)
            end
        end
    end
end)

-- Register events
CriTrack:RegisterEvent("VARIABLES_LOADED")
CriTrack:RegisterEvent("UNIT_COMBAT")
