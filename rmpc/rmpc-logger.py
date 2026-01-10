#!/usr/bin/env python3
"""
RMPC Logger - Tracks your listening history
Run this in the background to log all songs you listen to
"""

import os
import json
import time
from datetime import datetime
from pathlib import Path
from mpd import MPDClient

# Configuration
MPD_HOST = os.environ.get('MPD_HOST', 'localhost')
MPD_PORT = int(os.environ.get('MPD_PORT', 6600))
LOG_FILE = Path.home() / '.config' / 'rmpc' / 'listening_history.jsonl'
MIN_LISTEN_TIME = 30  # Minimum seconds to count as a listen

class ListeningLogger:
    def __init__(self):
        self.client = MPDClient()
        self.current_song = None
        self.song_start_time = None
        LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    def connect(self):
        try:
            self.client.connect(MPD_HOST, MPD_PORT)
            print(f"✓ Connected to MPD at {MPD_HOST}:{MPD_PORT}")
        except Exception as e:
            print(f"✗ Failed to connect to MPD: {e}")
            raise
    
    def log_song(self, song, duration):
        """Log a song listen to the history file"""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'title': song.get('title', 'Unknown'),
            'artist': song.get('artist', 'Unknown'),
            'album': song.get('album', 'Unknown'),
            'albumartist': song.get('albumartist', song.get('artist', 'Unknown')),
            'genre': song.get('genre', 'Unknown'),
            'date': song.get('date', 'Unknown'),
            'duration': float(song.get('duration', 0)),
            'listen_duration': duration,
            'file': song.get('file', '')
        }
        
        with open(LOG_FILE, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
        
        print(f"♫ Logged: {log_entry['artist']} - {log_entry['title']} ({duration:.0f}s)")
    
    def run(self):
        """Main monitoring loop"""
        self.connect()
        print(f"📊 Logging to: {LOG_FILE}")
        print("🎵 Monitoring your listening activity...\n")
        
        try:
            while True:
                status = self.client.status()
                state = status.get('state')
                
                if state == 'play':
                    current = self.client.currentsong()
                    
                    if current:
                        song_id = current.get('id')
                        
                        # New song started
                        if song_id != self.current_song:
                            # Log previous song if it was played long enough
                            if self.current_song and self.song_start_time:
                                elapsed = time.time() - self.song_start_time
                                if elapsed >= MIN_LISTEN_TIME:
                                    prev_song = self.client.playlistid(self.current_song)
                                    if prev_song:
                                        self.log_song(prev_song[0], elapsed)
                            
                            # Start tracking new song
                            self.current_song = song_id
                            self.song_start_time = time.time()
                            print(f"▶ Now playing: {current.get('artist', 'Unknown')} - {current.get('title', 'Unknown')}")
                
                elif state in ['stop', 'pause']:
                    # Log current song if paused/stopped and played long enough
                    if self.current_song and self.song_start_time:
                        elapsed = time.time() - self.song_start_time
                        if elapsed >= MIN_LISTEN_TIME:
                            try:
                                prev_song = self.client.playlistid(self.current_song)
                                if prev_song:
                                    self.log_song(prev_song[0], elapsed)
                            except:
                                pass
                    
                    self.current_song = None
                    self.song_start_time = None
                
                time.sleep(2)
                
        except KeyboardInterrupt:
            print("\n\n👋 Stopped logging. Your data is saved!")
            self.client.close()
            self.client.disconnect()

if __name__ == '__main__':
    logger = ListeningLogger()
    logger.run()
