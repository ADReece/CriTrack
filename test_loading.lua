-- Simple test to verify module loading
print("Testing module loading order...")

-- Simulate the .toc loading order
dofile("Utils.lua")
dofile("CombatLogParser.lua")
dofile("CompetitionManager.lua")
dofile("HealerTracker.lua")

print("Utils loaded:", Utils ~= nil)
print("CombatLogParser loaded:", CombatLogParser ~= nil)
print("CompetitionManager loaded:", CompetitionManager ~= nil)
print("HealerTracker loaded:", HealerTracker ~= nil)

-- Test basic functionality
if HealerTracker then
    print("HealerTracker.Initialize function exists:", HealerTracker.Initialize ~= nil)
    print("HealerTracker.SetEnabled function exists:", HealerTracker.SetEnabled ~= nil)
    print("HealerTracker.IsEnabled function exists:", HealerTracker.IsEnabled ~= nil)
end
