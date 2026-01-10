#!/bin/bash
# RMPC Wrapped - End of Year Auto-Reminder
# This script checks if it's near year-end and shows your wrapped

WRAPPED_SCRIPT="$HOME/.config/rmpc/rmpc-wrapped.py"
HISTORY_FILE="$HOME/.config/rmpc/listening_history.jsonl"
REMINDER_FILE="$HOME/.config/rmpc/.wrapped_shown_$(date +%Y)"

# Check if history file exists and has data
if [ ! -f "$HISTORY_FILE" ]; then
    exit 0
fi

# Only show between Dec 20 - Jan 10
MONTH=$(date +%m)
DAY=$(date +%d)

# December 20-31 OR January 1-10
if ([ "$MONTH" == "12" ] && [ "$DAY" -ge 20 ]) || ([ "$MONTH" == "01" ] && [ "$DAY" -le 10 ]); then
    
    # Check if we already showed it this year
    if [ -f "$REMINDER_FILE" ]; then
        exit 0
    fi
    
    # Show the wrapped!
    YEAR=$(date +%Y)
    if [ "$MONTH" == "12" ]; then
        YEAR=$YEAR
    else
        YEAR=$((YEAR - 1))
    fi
    
    # Create a nice notification terminal
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           🎉 YOUR $YEAR RMPC WRAPPED IS READY! 🎉          ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Press ENTER to view your year in music..."
    read -r
    
    python3 "$WRAPPED_SCRIPT" "$YEAR"
    
    # Mark as shown
    touch "$REMINDER_FILE"
    
    echo ""
    echo "Press ENTER to continue..."
    read -r
fi
