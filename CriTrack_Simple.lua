-- CriTrack - Simple version for Turtle WoW debugging
DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Starting to load...")

-- Test if we can create a frame
local frame = CreateFrame("Frame")
DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Frame created")

-- Test slash command
SLASH_TESTCRIT1 = "/testcrit"
SlashCmdList["TESTCRIT"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Test command works!")
end

DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Slash command registered")

-- Test event
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: PLAYER_LOGIN event fired!")
end)

DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Event registered")
DEFAULT_CHAT_FRAME:AddMessage("CriTrack_Simple: Addon loaded completely")
