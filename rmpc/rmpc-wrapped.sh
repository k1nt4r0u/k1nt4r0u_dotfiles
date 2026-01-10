#!/bin/bash
# RMPC Wrapped - Quick launch script

SCRIPT_DIR="$HOME/.config/rmpc"

case "$1" in
    "start"|"logger")
        echo "🎵 Starting RMPC Logger..."
        echo "This will track all your listening activity."
        echo "Press Ctrl+C to stop."
        echo ""
        python3 "$SCRIPT_DIR/rmpc-logger.py"
        ;;
    "wrapped"|"report"|"")
        if [ -n "$2" ]; then
            python3 "$SCRIPT_DIR/rmpc-wrapped.py" "$2"
        else
            python3 "$SCRIPT_DIR/rmpc-wrapped.py"
        fi
        ;;
    "daemon")
        echo "🚀 Starting RMPC Logger as background daemon..."
        nohup python3 "$SCRIPT_DIR/rmpc-logger.py" >> "$SCRIPT_DIR/logger.log" 2>&1 &
        echo $! > "$SCRIPT_DIR/logger.pid"
        echo "✓ Logger started! PID: $(cat $SCRIPT_DIR/logger.pid)"
        echo "📝 Logs: $SCRIPT_DIR/logger.log"
        ;;
    "stop")
        if [ -f "$SCRIPT_DIR/logger.pid" ]; then
            PID=$(cat "$SCRIPT_DIR/logger.pid")
            kill $PID 2>/dev/null
            rm "$SCRIPT_DIR/logger.pid"
            echo "✓ Logger stopped"
        else
            echo "❌ No logger running"
        fi
        ;;
    "status")
        if [ -f "$SCRIPT_DIR/logger.pid" ]; then
            PID=$(cat "$SCRIPT_DIR/logger.pid")
            if ps -p $PID > /dev/null; then
                echo "✓ Logger is running (PID: $PID)"
            else
                echo "❌ Logger not running (stale PID file)"
                rm "$SCRIPT_DIR/logger.pid"
            fi
        else
            echo "❌ Logger not running"
        fi
        
        if [ -f "$SCRIPT_DIR/listening_history.jsonl" ]; then
            LINES=$(wc -l < "$SCRIPT_DIR/listening_history.jsonl")
            echo "📊 Logged listens: $LINES"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "RMPC Wrapped - Your music year in review!"
        echo ""
        echo "Usage: rmpc-wrapped.sh [command] [year]"
        echo ""
        echo "Commands:"
        echo "  start, logger      Start the listening logger (foreground)"
        echo "  daemon             Start the logger as background daemon"
        echo "  stop               Stop the background logger daemon"
        echo "  status             Check if logger is running"
        echo "  wrapped [year]     Show your wrapped report (default: current year)"
        echo "  help               Show this help message"
        echo ""
        echo "Examples:"
        echo "  rmpc-wrapped.sh daemon        # Start logging in background"
        echo "  rmpc-wrapped.sh wrapped       # Show this year's wrapped"
        echo "  rmpc-wrapped.sh wrapped 2025  # Show 2025's wrapped"
        echo ""
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'rmpc-wrapped.sh help' for usage"
        exit 1
        ;;
esac
