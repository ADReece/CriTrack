# CriTrack

A World of Warcraft addon that tracks your highest critical hit damage and announces new records in chat.

## Overview

CriTrack is a lightweight addon specifically designed for **Turtle WoW** (1.17.2) using the original 1.12 Vanilla client. It monitors your combat damage and automatically tracks your highest critical hit, announcing new records to your chosen chat channel.

## Features

- 🎯 **Automatic Critical Hit Tracking** - Monitors all your damage for critical hits
- 📢 **Customizable Announcements** - Choose which chat channel to announce records in
- 💾 **Persistent Storage** - Your highest crit is saved between game sessions
- 🔧 **Simple Commands** - Easy-to-use slash commands for all functions
- 🐢 **Turtle WoW Compatible** - Built specifically for the 1.12 Vanilla client

## Installation

1. Download or clone this repository
2. Copy the `CriTrack` folder to your `World of Warcraft/Interface/AddOns/` directory
3. Ensure the folder contains `CriTrack.lua` and `CriTrack.toc`
4. Launch Turtle WoW and enable the addon at the character select screen

## Commands

| Command | Description |
|---------|-------------|
| `/critchannel <channel>` | Set announcement channel (say, party, raid, guild, yell) |
| `/crithigh` | Display your current highest critical hit |
| `/critreset` | Reset your highest crit record to 0 |
| `/critdebug` | Show debug information about the addon |

## Usage Examples

```
/critchannel say     # Announce new records in Say chat
/critchannel party   # Announce new records in Party chat
/critchannel guild   # Announce new records in Guild chat
/crithigh           # Check your current record
/critreset          # Reset your record to start over
```

## Compatibility

- **Client Version**: 1.12 Vanilla (Original 2006 WoW)
- **Server**: Turtle WoW 1.17.2
- **Interface**: 11200
- **Language**: English

## How It Works

CriTrack uses the `UNIT_COMBAT` event available in the 1.12 client to monitor combat damage. When you deal a critical hit that exceeds your current record, it:

1. Updates your highest crit value
2. Saves the new record to your SavedVariables
3. Announces the new record in your chosen chat channel

## File Structure

```
CriTrack/
├── CriTrack.lua        # Main addon code
├── CriTrack.toc        # Addon metadata
├── CriTrack_OLD.lua    # Backup of previous version
├── CriTrack_OLD.toc    # Backup of previous metadata
└── README.md           # This file
```

## Development

### Version History

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
    highestCrit = 1250,           -- Your highest crit damage
    announcementChannel = "SAY"   -- Current announcement channel
}
```

## Troubleshooting

### Addon Not Loading
1. Check that files are in the correct directory
2. Verify addon is enabled at character select
3. Ensure file permissions are correct
4. Try the ultra-simple test version first

### No Critical Hits Detected
1. Make sure you're dealing damage to enemies
2. Check that you're actually getting critical hits
3. Use `/critdebug` to verify event registration
4. Ensure you're not in a party/raid if testing solo

### Commands Not Working
1. Verify slash commands are typed correctly
2. Check for conflicts with other addons
3. Try `/critdebug` to see if the addon loaded properly

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
