#!/bin/bash
# Syncthing recent sync events fetcher
API_KEY=$(grep -oP '<apikey>\K[^<]+' ~/.local/state/syncthing/config.xml 2>/dev/null || grep -oP '<apikey>\K[^<]+' ~/.config/syncthing/config.xml 2>/dev/null)
BASE="http://localhost:8384"

if [ -z "$API_KEY" ]; then
    echo "status:offline"
    exit 0
fi

# Check if syncthing is reachable
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: $API_KEY" "$BASE/rest/system/status" 2>/dev/null)
if [ "$STATUS" != "200" ]; then
    echo "status:offline"
    exit 0
fi

echo "status:online"

# Get folder info
curl -s -H "X-API-Key: $API_KEY" "$BASE/rest/config/folders" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for f in data:
    print(f'folder:{f[\"id\"]}|{f[\"label\"]}|{f[\"path\"]}')
" 2>/dev/null

# Get connected devices
curl -s -H "X-API-Key: $API_KEY" "$BASE/rest/system/connections" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
conns = data.get('connections', {})
for dev_id, info in conns.items():
    if info.get('connected', False):
        name = info.get('clientVersion', 'unknown')
        print(f'device:{dev_id[:8]}|connected|{name}')
" 2>/dev/null

# Get device names
curl -s -H "X-API-Key: $API_KEY" "$BASE/rest/config/devices" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for d in data:
    print(f'devname:{d[\"deviceID\"][:8]}|{d[\"name\"]}')
" 2>/dev/null

# Get recent sync events
curl -s -H "X-API-Key: $API_KEY" "$BASE/rest/events?limit=15&events=ItemFinished" --max-time 3 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for e in reversed(data):
    d = e.get('data', {})
    item = d.get('item', '')
    action = d.get('action', '')
    folder = d.get('folder', '')
    err = d.get('error', '')
    t = e.get('time', '')[:19].replace('T', ' ')
    status = 'error' if err else 'ok'
    print(f'sync:{folder}|{item}|{action}|{status}|{t}')
" 2>/dev/null
