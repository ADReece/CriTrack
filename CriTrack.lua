

-- Debug: Try both DEFAULT_CHAT_FRAME and print for load message
if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack: Lua loaded (DEFAULT_CHAT_FRAME)")
else
    print("CriTrack: Lua loaded (print fallback)")
end



local CriTrack = CreateFrame("Frame")



-- Debug: Confirm global scope
_G["CriTrackDB"] = _G["CriTrackDB"] or {}
CriTrackDB = _G["CriTrackDB"]
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
SlashCmdList = SlashCmdList or {}
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
    if event == "PLAYER_LOGIN" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("CriTrack: PLAYER_LOGIN event fired!")
        else
            print("CriTrack: PLAYER_LOGIN event fired!")
        end
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
CriTrack:RegisterEvent("PLAYER_LOGIN")
CriTrack:RegisterEvent("UNIT_COMBAT")
