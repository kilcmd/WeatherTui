# WeatherTui
A TUI Version Of A Weather App using WTTR
#!/bin/bash
# Interactive Weather Monitor - Enhanced Edition
# Updates every hour, press 'r' to refresh manually

# ═══════════════════════════════════════════════════════════
# 📍 LOCATION SETTINGS - EASY TO CUSTOMIZE!
# ═══════════════════════════════════════════════════════════
# Just change these values to your location:

CITY="Atlanta"                    # Main city name
STATE="Georgia"                   # Your state (optional, for display)
LOCATION="Stockbridge,Georgia"    # Full location for detailed weather

# Examples of how to set different locations:
# CITY="NewYork"
# CITY="LosAngeles" 
# CITY="Chicago"
# LOCATION="Brooklyn,NewYork"
# LOCATION="SantaMonica,California"

# ═══════════════════════════════════════════════════════════
# ⚙️  SETTINGS - CUSTOMIZE YOUR DISPLAY
# ═══════════════════════════════════════════════════════════

UPDATE_INTERVAL=3600    # Time between auto-updates (in seconds)
                        # 3600 = 1 hour
                        # 1800 = 30 minutes
                        # 7200 = 2 hours

# ═══════════════════════════════════════════════════════════
# 🎨 MAIN PROGRAM - NO NEED TO EDIT BELOW THIS LINE
# ═══════════════════════════════════════════════════════════
