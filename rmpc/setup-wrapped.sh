#!/bin/bash
# RMPC Wrapped - One-Time Setup Script
# Run this once to set everything up automatically!

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         🎵 RMPC WRAPPED - ONE-TIME SETUP 🎵                ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$HOME/.config/rmpc"
SYSTEMD_DIR="$HOME/.config/systemd/user"

# Step 1: Check Python dependency
echo "📦 Step 1: Checking dependencies..."
if python3 -c "import mpd" 2>/dev/null; then
    echo "   ✓ python-mpd2 installed"
else
    echo "   📥 Installing python-mpd2..."
    
    # Detect package manager
    if command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        echo "   Detected Arch Linux - using pacman"
        sudo pacman -S --needed --noconfirm python-mpd2
    elif command -v apt >/dev/null 2>&1; then
        # Debian/Ubuntu
        sudo apt install -y python3-mpd2
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        sudo dnf install -y python3-mpd2
    else
        # Fallback to pip
        pip install --user python-mpd2
    fi
    
    if python3 -c "import mpd" 2>/dev/null; then
        echo "   ✓ python-mpd2 installed successfully"
    else
        echo "   ❌ Failed to install python-mpd2"
        echo "   Please run manually:"
        echo "     Arch:   sudo pacman -S python-mpd2"
        echo "     Debian: sudo apt install python3-mpd2"
        echo "     Other:  pip install --user python-mpd2"
        exit 1
    fi
fi
echo ""

# Step 2: Enable systemd service
echo "⚙️  Step 2: Setting up auto-start logger..."
mkdir -p "$SYSTEMD_DIR"

if systemctl --user enable rmpc-logger.service 2>/dev/null; then
    echo "   ✓ Service enabled"
else
    echo "   ❌ Failed to enable service"
    exit 1
fi

if systemctl --user start rmpc-logger.service 2>/dev/null; then
    echo "   ✓ Service started"
else
    echo "   ⚠️  Service start failed - may already be running"
fi

sleep 2

if systemctl --user is-active --quiet rmpc-logger.service; then
    echo "   ✓ Logger is now running!"
else
    echo "   ❌ Service not running - check: systemctl --user status rmpc-logger.service"
fi
echo ""

# Step 3: Setup shell integration
echo "🐚 Step 3: Setting up end-of-year reminder..."

SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Check if already added
    if grep -q "wrapped-reminder.sh" "$SHELL_RC" 2>/dev/null; then
        echo "   ✓ Reminder already configured in $SHELL_RC"
    else
        echo "" >> "$SHELL_RC"
        echo "# RMPC Wrapped - Auto year-end reminder" >> "$SHELL_RC"
        echo "$SCRIPT_DIR/wrapped-reminder.sh" >> "$SHELL_RC"
        echo "   ✓ Added to $SHELL_RC"
    fi
else
    echo "   ⚠️  Could not detect shell - add this to your shell RC file:"
    echo "   $SCRIPT_DIR/wrapped-reminder.sh"
fi
echo ""

# Step 4: Test connection
echo "🔌 Step 4: Testing MPD connection..."
if mpc status >/dev/null 2>&1; then
    echo "   ✓ MPD is running and reachable"
else
    echo "   ⚠️  MPD not responding - make sure it's running"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    ✅ SETUP COMPLETE! ✅                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "What happens now:"
echo ""
echo "  🎧 The logger is now running in the background"
echo "  📊 It's tracking every song you listen to"
echo "  🔄 It will auto-start on every login"
echo "  🎉 Between Dec 20 - Jan 10, you'll see your Wrapped!"
echo ""
echo "Useful commands:"
echo ""
echo "  Check status:    systemctl --user status rmpc-logger.service"
echo "  View logs:       journalctl --user -u rmpc-logger.service -f"
echo "  Stop logger:     systemctl --user stop rmpc-logger.service"
echo "  See wrapped now: $SCRIPT_DIR/rmpc-wrapped.sh wrapped"
echo ""
echo "🎵 Enjoy your music! Your data is being collected... 🎵"
echo ""
