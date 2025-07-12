-- CriTrack Isolation Test - Run this to check for addon conflicts

-- Test 1: Check if other addons are using our slash commands
print("=== CriTrack Isolation Test ===")

local function TestSlashCommands()
    print("Testing slash command conflicts...")
    
    local commands = {"CRITCHANNEL", "CRITHIGH", "CRITRESET", "CRITDEBUG"}
    local conflicts = {}
    
    for _, cmd in ipairs(commands) do
        if SlashCmdList[cmd] then
            table.insert(conflicts, cmd)
        end
    end
    
    if #conflicts > 0 then
        print("WARNING: These commands are already registered:")
        for _, cmd in ipairs(conflicts) do
            print("  - " .. cmd)
        end
    else
        print("No slash command conflicts detected")
    end
end

-- Test 2: Check global variable conflicts
local function TestGlobalConflicts()
    print("Testing global variable conflicts...")
    
    if _G["CriTrackDB"] and type(_G["CriTrackDB"]) ~= "table" then
        print("WARNING: CriTrackDB exists but is not a table!")
    elseif _G["CriTrackDB"] then
        print("CriTrackDB exists and is a table - OK")
    else
        print("CriTrackDB does not exist yet - OK")
    end
end

-- Test 3: Check frame conflicts
local function TestFrameConflicts()
    print("Testing frame conflicts...")
    
    local frameName = "CriTrack_MainFrame"
    if _G[frameName] then
        print("WARNING: Frame " .. frameName .. " already exists!")
    else
        print("No frame conflicts detected")
    end
end

-- Test 4: List all loaded addons
local function ListLoadedAddons()
    print("Currently loaded addons:")
    for i = 1, GetNumAddOns() do
        local name, title, _, enabled, loadable = GetAddOnInfo(i)
        if enabled then
            print("  - " .. name .. " (" .. title .. ")")
        end
    end
end

-- Run tests
TestSlashCommands()
TestGlobalConflicts()
TestFrameConflicts()
ListLoadedAddons()

print("=== End Isolation Test ===")
print("Run /script dofile('Interface/AddOns/CriTrack/CriTrack_IsolationTest.lua') to run this test")
