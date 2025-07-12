# CriTrack

A World of Warcraft addon that tracks your highest critical hit damage and critical heals, with competition mode and comprehensive chat announcements.

## Overview

CriTrack is a feature-rich addon specifically designed for **Turtle WoW** (1.17.2) using the original 1.12 Vanilla client. It monitors your combat damage and healing, automatically tracking your highest critical hits and heals, with optional group competition features and customizable announcements.

## Features

- 🎯 **Critical Hit Tracking** - Monitors all your damage for critical hits
- 💚 **Critical Heal Tracking** - Tracks your biggest critical heals  
- 🏆 **Competition Mode** - Group leaderboards for friendly competition
- ⚔️ **Spell/Attack Tracking** - Records which spell or attack achieved records
- 📢 **Customizable Announcements** - Choose which chat channel to announce records in
- 💾 **Persistent Storage** - All records saved between game sessions
- 🔧 **Modular Design** - Clean, maintainable code structure
- 🐢 **Turtle WoW Compatible** - Built specifically for the 1.12 Vanilla client

## Installation

1. Download or clone this repository
2. Copy the `CriTrack` folder to your `World of Warcraft/Interface/AddOns/` directory
3. Ensure the folder contains all `.lua` files and `CriTrack.toc`
4. Launch Turtle WoW and enable the addon at the character select screen

## Commands

### Core Commands
| Command | Description |
|---------|-------------|
| `/critchannel <channel>` | Set announcement channel (say, party, raid, guild, yell) |
| `/crithigh` | Display your current highest critical hit and the spell/attack that caused it |
| `/critreset` | Reset your highest crit record and spell to 0 |
| `/crithelp` | Show all available commands with descriptions |

### Competition Mode
| Command | Description |
|---------|-------------|
| `/critcomp` | Show competition status and leaderboard |
| `/critcomp on` | Enable group critical hit competition |
| `/critcomp off` | Disable competition mode |
| `/critcomp reset` | Clear competition leaderboard |
| `/critadd <player> <amount> [spell]` | Manually add a player's crit to leaderboard |
| `/critboard` | Show leaderboard in chat |
| `/critboard announce` | Share leaderboard publicly |

### Healer Tracking
| Command | Description |
|---------|-------------|
| `/critheal` | Show healer tracking status and records |
| `/critheal on` | Enable critical heal tracking |
| `/critheal off` | Disable heal tracking |
| `/critheal group` | Enable group heal tracking |
| `/critheal groupoff` | Disable group heal tracking |
| `/critheal reset` | Reset all heal records |
| `/critheal resetpersonal` | Reset personal heal record |
| `/critheal resetgroup` | Reset group heal record |

### Debug Commands
| Command | Description |
|---------|-------------|
| `/critdebug` | Show current debug status and addon information |
| `/critdebug on/off` | Enable/disable debug messages |
| `/critdebug player/party` | Set debug scope to player or party |
| `/crittest <number>` | Manually set a test crit for debugging |
| `/crithealtest <number>` | Manually set a test heal for debugging |

## Usage Examples

```
# Basic setup
/critchannel say     # Announce new records in Say chat
/critchannel party   # Announce new records in Party chat
/critchannel guild   # Announce new records in Guild chat
/crithigh           # Check your current record
/critreset          # Reset your record to start over

# Competition mode
/critcomp on        # Enable group competition
/critadd Gandalf 450 Fireball  # Add Gandalf's 450 Fireball crit
/critboard          # Show leaderboard
/critboard announce # Share leaderboard publicly

# Healer tracking
/critheal on        # Enable heal tracking
/critheal group     # Enable group heal tracking
/critheal           # Check heal records

# Debug commands
/critdebug on       # Enable debug messages
/critdebug player   # Debug only your combat events
/critdebug party    # Debug all party members' combat events
/critdebug off      # Disable debug messages
/crittest 500       # Set a test crit of 500 for testing
/crithealtest 300   # Set a test heal of 300 for testing
```

## Compatibility

- **Client Version**: 1.12 Vanilla (Original 2006 WoW)
- **Server**: Turtle WoW 1.17.2
- **Interface**: 11200
- **Language**: English
- **Lua Version**: 5.0 (WoW 1.12 compatible)

## How It Works

CriTrack uses combat log events available in the 1.12 client to monitor combat damage and healing. The addon listens for:

- `CHAT_MSG_COMBAT_SELF_HITS` - Your melee/ranged critical hits
- `CHAT_MSG_SPELL_SELF_DAMAGE` - Your spell critical hits  
- `CHAT_MSG_SPELL_SELF_BUFF` - Your critical heals
- `CHAT_MSG_COMBAT_FRIENDLY_BUFF` - Group member critical heals

When you deal a critical hit or heal that exceeds your current record, it:

1. Updates your highest crit/heal value
2. Records the spell or attack that caused the crit/heal
3. Saves the new record to your SavedVariables
4. Announces the new record with the spell/attack name in your chosen chat channel

## File Structure

```
CriTrack/
├── Utils.lua              # Utility functions and helpers
├── CombatLogParser.lua    # Combat log message parsing
├── CompetitionManager.lua # Competition mode and leaderboards
├── HealerTracker.lua      # Critical heal tracking
├── CriTrack.lua           # Main addon code and event handling
├── CriTrack.toc           # Addon metadata and file loading
└── README.md              # This file
```

## Development

### Version History

- **v2.0** - Complete modular rewrite with healer tracking, competition mode, and improved architecture
- **v1.5** - Added configurable debug system with player/party filtering
- **v1.4** - Added spell/attack tracking for highest crits
- **v1.3** - 1.12 Vanilla compatibility update
- **v1.2** - Enhanced debugging and conflict detection
- **v1.1** - Improved error handling and additional features
- **v1.0** - Initial release

### Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly on Turtle WoW
4. Submit a pull request

## Technical Details

### Event Handling
The addon uses the classic 1.12 event system:
- Global `event` variable for event type
- Global `arg1`, `arg3`, `arg5` for event parameters
- `DEFAULT_CHAT_FRAME:AddMessage()` for output

### SavedVariables
Data is stored in `CriTrackDB` with the following structure:
```lua
CriTrackDB = {
    -- Personal critical hit records
    highestCrit = 1250,                    -- Your highest crit damage
    highestCritSpell = "Fireball",         -- The spell/attack that caused it
    
    -- Settings
    announcementChannel = "SAY",           -- Current announcement channel
    debugEnabled = false,                  -- Debug mode on/off
    debugMode = "player",                  -- Debug scope: "player" or "party"
    
    -- Competition mode
    competitionMode = false,               -- Competition enabled/disabled
    competitionData = {                    -- Competition leaderboard data
        playerName = {
            critAmount = 1500,
            spellName = "Frostbolt",
            timestamp = 1234567890
        }
    },
    
    -- Healer tracking
    healerEnabled = false,                 -- Healer tracking enabled/disabled
    healerGroupMode = false,               -- Group heal tracking enabled/disabled
    healerData = {
        personalHighest = {
            amount = 800,
            spell = "Greater Heal",
            target = "Friendly"
        },
        groupHighest = {
            amount = 1200,
            spell = "Prayer of Healing",
            caster = "Priest",
            target = "Tank"
        }
    }
}
```

## Troubleshooting

### Addon Not Loading
1. Check that all files are in the correct directory
2. Verify addon is enabled at character select
3. Ensure file permissions are correct
4. Check that .toc file loads all modules in the right order

### No Critical Hits/Heals Detected
1. Enable debug mode with `/critdebug on`
2. Attack enemies or heal allies and watch for debug messages
3. Check if combat log events are firing properly
4. Verify the event parameters match expected values
5. Try `/crittest 100` or `/crithealtest 100` to test the recording system
6. Use `/critdebug player` to focus on your events only

### Healer Tracking Not Working
1. Enable healer tracking with `/critheal on`
2. Make sure you're actually landing critical heals
3. Check debug messages for heal parsing
4. Verify the combat log events are being captured
5. Use `/crithealtest` to test the heal recording system

### Competition Mode Issues
1. Enable competition mode with `/critcomp on`
2. Check if other players are in your group/party
3. Verify group members are generating combat events
4. Try manually adding entries with `/critadd`

### Commands Not Working
1. Verify slash commands are typed correctly
2. Check for conflicts with other addons
3. Try `/critdebug` to see if the addon loaded properly
4. Use `/crithelp` to see all available commands

### Module Loading Issues
1. Check that all .lua files are present
2. Verify .toc file lists all modules
3. Look for Lua errors in the chat frame
4. Try disabling other addons to check for conflicts

## Support

For issues specific to Turtle WoW:
- Check the Turtle WoW Discord
- Visit the Turtle WoW forums
- Ensure you're using the correct client version

For addon-specific issues:
- Check the GitHub Issues page
- Provide `/critdebug` output when reporting problems
- Include your Turtle WoW version and any error messages

## License

This project is open source. Feel free to modify and distribute according to your needs.

## Acknowledgments

- Built for the amazing Turtle WoW community
- Compatible with the original 2006 World of Warcraft client
- Thanks to all testers and contributors

---

**Happy critting!** 🎯
