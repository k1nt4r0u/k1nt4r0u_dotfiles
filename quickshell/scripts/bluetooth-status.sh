#!/bin/bash
# Check if Bluetooth is powered on
POWERED=$(busctl get-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 Powered 2>/dev/null)

if [[ "$POWERED" != "b true" ]]; then
    echo "off"
    exit 0
fi

# Check if any device is connected
# Extract device paths and check Connected property
CONNECTED=$(busctl tree org.bluez 2>/dev/null | grep -o '/org/bluez/hci0/dev_[^ ]*' | sort -u | while read -r dev; do
    if [[ $(busctl get-property org.bluez "$dev" org.bluez.Device1 Connected 2>/dev/null) == "b true" ]]; then
        echo "yes"
        break
    fi
done)

if [[ "$CONNECTED" == "yes" ]]; then
    echo "connected"
else
    echo "on"
fi
