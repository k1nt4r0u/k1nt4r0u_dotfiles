# RMPC Wrapped

🎉 **Your personalized music year in review for RMPC/MPD!**

## What You Get

- 📊 **Total listening time** - Minutes and hours listened
- 🎤 **Top 5 Artists** - Your most played artists with play counts and time
- 🎵 **Top 5 Songs** - Your anthem tracks of the year
- 💿 **Top 5 Albums** - Your favorite albums
- 🎸 **Genre Analysis** - What genres dominated your year
- ✨ **Your Vibe** - AI-generated vibe based on your listening patterns
- 📅 **Listening Patterns** - Peak hours, most active days, monthly breakdowns
- 🎊 **Fun Facts** - First song of the year, longest session, and more
- 📈 **Statistics** - Unique artists, albums, songs, average song length
- 💾 **JSON Export** - Export all data for further analysis

## Quick Setup (Set It and Forget It!) 🚀

**Run this ONE command and you're done forever:**

```bash
~/.config/rmpc/setup-wrapped.sh
```

This will:
- ✅ Install dependencies automatically
- ✅ Start the logger in the background
- ✅ Auto-start on every login
- ✅ Show your Wrapped between Dec 20 - Jan 10 each year
- ✅ Test everything works

**That's it!** Just listen to music and at the end of the year, your Wrapped will pop up! 🎉

## Manual Installation (Advanced)

The scripts are already installed in `~/.config/rmpc/`:
- `rmpc-logger.py` - Background daemon that tracks your listening
- `rmpc-wrapped.py` - Generates your wrapped report
- `rmpc-wrapped.sh` - Convenient wrapper script
- `setup-wrapped.sh` - One-time setup script
- `wrapped-reminder.sh` - Auto year-end reminder

### Install Python Dependency

**Arch Linux:**
```bash
sudo pacman -S python-mpd2
```

**Debian/Ubuntu:**
```bash
sudo apt install python3-mpd2
```

**Other distros:**
```bash
pip install --user python-mpd2
```

## Usage

### 1. Start Logging (Required First!)

The logger needs to run to track your listening activity. Choose one:

**Foreground (see live logs):**
```bash
~/.config/rmpc/rmpc-wrapped.sh start
# or directly:
python3 ~/.config/rmpc/rmpc-logger.py
```

**Background daemon (recommended):**
```bash
~/.config/rmpc/rmpc-wrapped.sh daemon
```

**Check status:**
```bash
~/.config/rmpc/rmpc-wrapped.sh status
```

**Stop daemon:**
```bash
~/.config/rmpc/rmpc-wrapped.sh stop
```

### 2. View Your Wrapped

After collecting some listening data:

```bash
# Current year
~/.config/rmpc/rmpc-wrapped.sh wrapped

# Specific year
~/.config/rmpc/rmpc-wrapped.sh wrapped 2025

# Direct Python
python3 ~/.config/rmpc/rmpc-wrapped.py
python3 ~/.config/rmpc/rmpc-wrapped.py 2025
```

## How It Works

1. **Logger Daemon** (`rmpc-logger.py`):
   - Connects to your MPD server
   - Monitors currently playing songs
   - Logs each song after you've listened for 30+ seconds
   - Saves to `~/.config/rmpc/listening_history.jsonl`

2. **Wrapped Report** (`rmpc-wrapped.py`):
   - Reads your listening history
   - Analyzes patterns and statistics
   - Generates beautiful terminal report
   - Can export to JSON for custom analysis

## Features

### Smart Tracking
- Only counts songs listened to for 30+ seconds
- Handles pause/stop/skip gracefully
- Tracks exact listen duration per song
- Records: title, artist, album, genre, timestamp

### Comprehensive Stats
- Total listening time (minutes/hours)
- Play counts for artists, songs, albums
- Genre distribution
- Temporal patterns (hourly, daily, monthly)
- Session analysis
- Unique counts (artists, albums, songs)

### Vibe Detection
Your vibe is calculated based on:
- Total listening time (intensity)
- Artist diversity (explorer vs loyalist)
- Top genre
- Peak listening hours

### JSON Export
Export your data for:
- Custom visualizations
- Sharing stats
- Further analysis
- Integration with other tools

## How Auto-Start Works

The setup script creates a systemd user service that:
- Runs automatically on login
- Restarts if it crashes
- Logs to `~/.config/rmpc/logger.log`

### Manual systemd commands:

```bash
# Check if running
systemctl --user status rmpc-logger.service

# View live logs
journalctl --user -u rmpc-logger.service -f

# Stop/start manually
systemctl --user stop rmpc-logger.service
systemctl --user start rmpc-logger.service

# Disable auto-start
systemctl --user disable rmpc-logger.service
```

## Tips

- 🚀 Start the logger daemon and forget about it
- 📅 Check your wrapped at the end of each year
- 💾 Export JSON to track trends across years
- 🔄 The longer you run it, the better the stats!
- 🎵 Minimum 30 seconds listen time prevents skips from inflating stats

## Troubleshooting

**"No listening history found"**
- Start the logger first and listen to some music

**"Failed to connect to MPD"**
- Check MPD is running: `mpc status`
- Verify connection in config: defaults to `localhost:6600`

**Logger stops unexpectedly**
- Check logs: `~/.config/rmpc/logger.log`
- Use daemon mode for auto-restart

## Example Output

```
============================================================
            🎵  YOUR 2026 RMPC WRAPPED  🎵
============================================================

📊 OVERVIEW
------------------------------------------------------------
  Total Listening Time:  45,234 minutes (754 hours)
  Total Tracks Played:   5,432
  Unique Artists:        247
  Unique Albums:         412
  Unique Songs:          1,834
  Average Song Length:   3.8 minutes

✨ YOUR VIBE
------------------------------------------------------------
  Hardcore Rock Explorer

🎤 TOP 5 ARTISTS
------------------------------------------------------------
  1. The Beatles
     234 plays • 892 minutes
  2. Pink Floyd
     187 plays • 743 minutes
  ...
```

Enjoy your RMPC Wrapped! 🎉
