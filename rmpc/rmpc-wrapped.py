#!/usr/bin/env python3
"""
🎉 RMPC WRAPPED 🎉
Your personalized music listening year in review!

Usage: python3 rmpc-wrapped.py [year]
"""

import json
import sys
from datetime import datetime
from pathlib import Path
from collections import defaultdict, Counter
from typing import List, Dict, Any

LOG_FILE = Path.home() / '.config' / 'rmpc' / 'listening_history.jsonl'

class RMPCWrapped:
    def __init__(self, year=None):
        self.year = year or datetime.now().year
        self.listens = []
        self.load_data()
    
    def load_data(self):
        """Load listening history for the specified year"""
        if not LOG_FILE.exists():
            print(f"❌ No listening history found at {LOG_FILE}")
            print("💡 Start the logger first: python3 rmpc-logger.py")
            sys.exit(1)
        
        with open(LOG_FILE, 'r') as f:
            for line in f:
                if line.strip():
                    entry = json.loads(line)
                    timestamp = datetime.fromisoformat(entry['timestamp'])
                    if timestamp.year == self.year:
                        self.listens.append(entry)
        
        if not self.listens:
            print(f"❌ No listening data found for {self.year}")
            sys.exit(1)
    
    def total_minutes(self) -> float:
        """Calculate total listening time in minutes"""
        return sum(entry['listen_duration'] for entry in self.listens) / 60
    
    def top_artists(self, n=5) -> List[tuple]:
        """Get top N artists by listen count"""
        artists = defaultdict(lambda: {'count': 0, 'time': 0})
        for entry in self.listens:
            artist = entry['albumartist']
            artists[artist]['count'] += 1
            artists[artist]['time'] += entry['listen_duration']
        
        return sorted(artists.items(), key=lambda x: x[1]['count'], reverse=True)[:n]
    
    def top_songs(self, n=5) -> List[tuple]:
        """Get top N songs by listen count"""
        songs = defaultdict(lambda: {'artist': '', 'count': 0, 'time': 0})
        for entry in self.listens:
            key = (entry['title'], entry['artist'])
            songs[key]['artist'] = entry['artist']
            songs[key]['count'] += 1
            songs[key]['time'] += entry['listen_duration']
        
        return sorted(songs.items(), key=lambda x: x[1]['count'], reverse=True)[:n]
    
    def top_albums(self, n=5) -> List[tuple]:
        """Get top N albums by listen count"""
        albums = defaultdict(lambda: {'artist': '', 'count': 0, 'time': 0})
        for entry in self.listens:
            key = (entry['album'], entry['albumartist'])
            albums[key]['artist'] = entry['albumartist']
            albums[key]['count'] += 1
            albums[key]['time'] += entry['listen_duration']
        
        return sorted(albums.items(), key=lambda x: x[1]['count'], reverse=True)[:n]
    
    def top_genres(self, n=5) -> List[tuple]:
        """Get top N genres"""
        genres = Counter(entry['genre'] for entry in self.listens if entry['genre'] != 'Unknown')
        return genres.most_common(n)
    
    def listening_by_month(self) -> Dict[str, int]:
        """Breakdown listening by month"""
        months = defaultdict(int)
        for entry in self.listens:
            month = datetime.fromisoformat(entry['timestamp']).strftime('%B')
            months[month] += 1
        return dict(months)
    
    def listening_by_hour(self) -> Dict[int, int]:
        """Breakdown listening by hour of day"""
        hours = defaultdict(int)
        for entry in self.listens:
            hour = datetime.fromisoformat(entry['timestamp']).hour
            hours[hour] += 1
        return dict(sorted(hours.items()))
    
    def avg_song_length(self) -> float:
        """Average song length in minutes"""
        total = sum(entry['duration'] for entry in self.listens)
        return (total / len(self.listens)) / 60 if self.listens else 0
    
    def unique_artists(self) -> int:
        """Count of unique artists"""
        return len(set(entry['albumartist'] for entry in self.listens))
    
    def unique_songs(self) -> int:
        """Count of unique songs"""
        return len(set((entry['title'], entry['artist']) for entry in self.listens))
    
    def unique_albums(self) -> int:
        """Count of unique albums"""
        return len(set(entry['album'] for entry in self.listens if entry['album'] != 'Unknown'))
    
    def determine_vibe(self) -> str:
        """Determine listening vibe based on patterns"""
        top_genre = self.top_genres(1)
        total_mins = self.total_minutes()
        unique_arts = self.unique_artists()
        
        # Vibe determination logic
        if total_mins > 50000:
            intensity = "Hardcore"
        elif total_mins > 30000:
            intensity = "Dedicated"
        elif total_mins > 15000:
            intensity = "Passionate"
        else:
            intensity = "Casual"
        
        if unique_arts > 100:
            diversity = "Explorer"
        elif unique_arts > 50:
            diversity = "Adventurer"
        else:
            diversity = "Loyalist"
        
        genre_vibe = top_genre[0][0] if top_genre else "Music"
        
        vibes = [
            f"{intensity} {genre_vibe} {diversity}",
            f"{genre_vibe} Enthusiast",
            f"The {intensity} Listener",
            f"{diversity} of {genre_vibe}"
        ]
        
        # Time-based vibes
        hours = self.listening_by_hour()
        if hours:
            peak_hour = max(hours.items(), key=lambda x: x[1])[0]
            if 0 <= peak_hour < 6:
                vibes.append("Night Owl")
            elif 6 <= peak_hour < 12:
                vibes.append("Early Bird")
            elif 12 <= peak_hour < 18:
                vibes.append("Afternoon Viber")
            else:
                vibes.append("Evening Listener")
        
        return vibes[0]
    
    def most_active_day(self) -> str:
        """Find the day with most listens"""
        days = defaultdict(int)
        for entry in self.listens:
            day = datetime.fromisoformat(entry['timestamp']).strftime('%Y-%m-%d')
            days[day] += 1
        
        if not days:
            return "N/A"
        
        best_day = max(days.items(), key=lambda x: x[1])
        return f"{best_day[0]} ({best_day[1]} songs)"
    
    def longest_session(self) -> str:
        """Find longest listening session"""
        sessions = []
        current_session = []
        
        sorted_listens = sorted(self.listens, key=lambda x: x['timestamp'])
        
        for i, entry in enumerate(sorted_listens):
            if not current_session:
                current_session.append(entry)
            else:
                prev_time = datetime.fromisoformat(current_session[-1]['timestamp'])
                curr_time = datetime.fromisoformat(entry['timestamp'])
                
                # If less than 5 minutes between songs, same session
                if (curr_time - prev_time).seconds < 300:
                    current_session.append(entry)
                else:
                    sessions.append(current_session)
                    current_session = [entry]
        
        if current_session:
            sessions.append(current_session)
        
        if not sessions:
            return "N/A"
        
        longest = max(sessions, key=len)
        return f"{len(longest)} songs"
    
    def generate_report(self):
        """Generate the full wrapped report"""
        
        # Header
        print("\n" + "="*60)
        print(f"🎵  YOUR {self.year} RMPC WRAPPED  🎵".center(60))
        print("="*60 + "\n")
        
        # Overview
        print("📊 OVERVIEW")
        print("-" * 60)
        print(f"  Total Listening Time:  {self.total_minutes():,.0f} minutes ({self.total_minutes()/60:,.0f} hours)")
        print(f"  Total Tracks Played:   {len(self.listens):,}")
        print(f"  Unique Artists:        {self.unique_artists():,}")
        print(f"  Unique Albums:         {self.unique_albums():,}")
        print(f"  Unique Songs:          {self.unique_songs():,}")
        print(f"  Average Song Length:   {self.avg_song_length():.1f} minutes")
        print()
        
        # Your Vibe
        print("✨ YOUR VIBE")
        print("-" * 60)
        print(f"  {self.determine_vibe()}")
        print()
        
        # Top Artists
        print("🎤 TOP 5 ARTISTS")
        print("-" * 60)
        for i, (artist, data) in enumerate(self.top_artists(5), 1):
            mins = data['time'] / 60
            print(f"  {i}. {artist}")
            print(f"     {data['count']} plays • {mins:,.0f} minutes")
        print()
        
        # Top Songs
        print("🎵 TOP 5 SONGS")
        print("-" * 60)
        for i, ((title, artist), data) in enumerate(self.top_songs(5), 1):
            mins = data['time'] / 60
            print(f"  {i}. {title}")
            print(f"     {artist} • {data['count']} plays • {mins:.0f} minutes")
        print()
        
        # Top Albums
        print("💿 TOP 5 ALBUMS")
        print("-" * 60)
        for i, ((album, artist), data) in enumerate(self.top_albums(5), 1):
            mins = data['time'] / 60
            print(f"  {i}. {album}")
            print(f"     {artist} • {data['count']} plays • {mins:.0f} minutes")
        print()
        
        # Top Genres
        print("🎸 TOP GENRES")
        print("-" * 60)
        top_genres = self.top_genres(5)
        if top_genres:
            for i, (genre, count) in enumerate(top_genres, 1):
                pct = (count / len(self.listens)) * 100
                print(f"  {i}. {genre} - {count} plays ({pct:.1f}%)")
        else:
            print("  No genre data available")
        print()
        
        # Listening Patterns
        print("📅 LISTENING PATTERNS")
        print("-" * 60)
        print(f"  Most Active Day:       {self.most_active_day()}")
        print(f"  Longest Session:       {self.longest_session()}")
        
        hours = self.listening_by_hour()
        if hours:
            peak_hour = max(hours.items(), key=lambda x: x[1])[0]
            print(f"  Peak Listening Hour:   {peak_hour:02d}:00 ({hours[peak_hour]} songs)")
        print()
        
        # Monthly breakdown
        print("📆 MONTHLY BREAKDOWN")
        print("-" * 60)
        months = self.listening_by_month()
        if months:
            for month, count in sorted(months.items(), key=lambda x: x[1], reverse=True):
                bar = "█" * (count // 10) + "▒" * ((count % 10) // 5)
                print(f"  {month:10s} {bar:20s} {count:4d} songs")
        print()
        
        # Fun Facts
        print("🎊 FUN FACTS")
        print("-" * 60)
        
        if self.listens:
            # First song of the year
            first = sorted(self.listens, key=lambda x: x['timestamp'])[0]
            print(f"  First song of {self.year}:  {first['artist']} - {first['title']}")
            
            # Most recent
            last = sorted(self.listens, key=lambda x: x['timestamp'])[-1]
            print(f"  Most recent play:       {last['artist']} - {last['title']}")
            
            # If you played everything back-to-back
            days = self.total_minutes() / 60 / 24
            print(f"  Total days of music:    {days:.1f} days")
        
        print()
        print("="*60)
        print(f"Thank you for using RMPC in {self.year}! 🎉".center(60))
        print("="*60 + "\n")
    
    def export_json(self, filename=None):
        """Export wrapped data to JSON"""
        if not filename:
            filename = f"rmpc_wrapped_{self.year}.json"
        
        data = {
            'year': self.year,
            'total_minutes': self.total_minutes(),
            'total_listens': len(self.listens),
            'unique_artists': self.unique_artists(),
            'unique_albums': self.unique_albums(),
            'unique_songs': self.unique_songs(),
            'vibe': self.determine_vibe(),
            'top_artists': [
                {'name': artist, 'plays': data['count'], 'minutes': data['time']/60}
                for artist, data in self.top_artists(10)
            ],
            'top_songs': [
                {'title': title, 'artist': artist, 'plays': data['count'], 'minutes': data['time']/60}
                for (title, artist), data in self.top_songs(10)
            ],
            'top_albums': [
                {'album': album, 'artist': artist, 'plays': data['count'], 'minutes': data['time']/60}
                for (album, artist), data in self.top_albums(10)
            ],
            'top_genres': [
                {'genre': genre, 'plays': count}
                for genre, count in self.top_genres(10)
            ],
            'listening_by_month': self.listening_by_month(),
            'listening_by_hour': self.listening_by_hour()
        }
        
        output_path = Path.home() / '.config' / 'rmpc' / filename
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)
        
        print(f"✓ Exported to {output_path}")

if __name__ == '__main__':
    year = int(sys.argv[1]) if len(sys.argv) > 1 else None
    wrapped = RMPCWrapped(year)
    wrapped.generate_report()
    
    # Ask to export
    print("\n💾 Export to JSON? [y/N]: ", end='')
    try:
        if input().lower() == 'y':
            wrapped.export_json()
    except:
        pass
