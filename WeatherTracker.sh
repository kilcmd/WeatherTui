#!/bin/bash
# Interactive Weather Monitor - Spacious Edition
# Updates every hour, press 'r' to refresh manually

# ═══════════════════════════════════════════════════════════
# 📍 LOCATION SETTINGS - EASY TO CUSTOMIZE!
# ═══════════════════════════════════════════════════════════
# Just change these values to your location:

CITY="NewYork"                    # Main city name
#STATE="New York"                   # Your state (optional, for display)
#LOCATION="New York,New York"    # Full location for detailed weather

# ═══════════════════════════════════════════════════════════
# ⚙️  SETTINGS - CUSTOMIZE YOUR DISPLAY
# ═══════════════════════════════════════════════════════════

UPDATE_INTERVAL=3600    # Time between auto-updates (in seconds)

# ═══════════════════════════════════════════════════════════
# 🎨 MAIN PROGRAM
# ═══════════════════════════════════════════════════════════

# Function to display weather
show_weather() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║                                                ║"
    echo "║         Weather Monitor - tmux                 ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
    echo ""
    
    # Display location
 #   echo "  📍  Location:  $CITY, $STATE"
    echo ""
    echo ""
    
    # Get current time
    echo "  🕐  Last updated:  $(date '+%I:%M %p')"
    echo ""
    echo ""
    
    # Show main weather
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  $(curl -s "wttr.in/$CITY?format=3")"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo ""
    
    # Show additional details (now on separate lines)
    echo "  Feels like:  $(curl -s "wttr.in/$CITY?format=%f")"
    echo ""
    echo "  Wind:        $(curl -s "wttr.in/$CITY?format=%w")"
    echo ""
    echo "  Humidity:    $(curl -s "wttr.in/$CITY?format=%h")"
    echo ""
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Show next update time
    NEXT_UPDATE=$(date -d "+$UPDATE_INTERVAL seconds" '+%I:%M %p' 2>/dev/null || date -v+1H '+%I:%M %p' 2>/dev/null)
    if [ -n "$NEXT_UPDATE" ]; then
        echo "  ⏰  Next auto-update:  $NEXT_UPDATE"
    fi
    echo ""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Press  'r'  to refresh now  |  Ctrl+C  to quit"
    echo ""
}

# Main loop
while true; do
    show_weather
    
    # Wait for user input or timeout
    read -t $UPDATE_INTERVAL -n 1 key
    
    # If user pressed 'r', refresh immediately
    if [ "$key" = "r" ]; then
        echo ""
        echo "  ♻️   Refreshing..."
        sleep 1
    fi
done
