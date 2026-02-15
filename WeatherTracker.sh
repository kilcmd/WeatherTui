#!/bin/bash
# Version 6.0
# Interactive Weather Monitor - Storm Edition (weather.gov)
# Compact, colorized, fixed-height for tmux
# Now with WEATHER ALERTS for storm monitoring!

# ═══════════════════════════════════════════════════════════
# 📍 LOCATION SETTINGS - EASY TO CUSTOMIZE!
# ═══════════════════════════════════════════════════════════
# For weather.gov, we need latitude and longitude
# You can find yours at: https://www.latlong.net/

LATITUDE="40.7128"      # New york, NY latitude
LONGITUDE="-74.0060"    # New york, NY longitude
CITY="New York"        # Display name
STATE="New York"         # Display name

# ═══════════════════════════════════════════════════════════
# ⚙️  SETTINGS - CUSTOMIZE YOUR DISPLAY
# ═══════════════════════════════════════════════════════════

UPDATE_INTERVAL=3600    # Time between auto-updates (in seconds)
                        # weather.gov recommends NO MORE than once per hour
                        # Their data only updates every ~10 minutes anyway

CACHE_FILE="/tmp/weather_cache_newyork_$USER.txt"
CACHE_MAX_AGE=900       # Cache is valid for 15 minutes (900 seconds)
                        # This prevents hammering if you press 'r' repeatedly

# User agent (weather.gov REQUIRES this - it's polite!)
USER_AGENT="(WeatherMonitor-Personal, your-email)"

# ═══════════════════════════════════════════════════════════
# 🎨 COLORS
# ═══════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════
# 🎨 MAIN PROGRAM
# ═══════════════════════════════════════════════════════════

# Function to get cached weather or fetch new
get_weather_data() {
    local current_time=$(date +%s)
    
    # Check if cache exists and is still fresh
    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
        local cache_age=$((current_time - cache_time))
        
        if [ $cache_age -lt $CACHE_MAX_AGE ]; then
            # Cache is fresh, use it
            cat "$CACHE_FILE"
            return 0
        fi
    fi
    
    # Cache is stale or doesn't exist, fetch new data
    # Step 1: Get the forecast URLs for our coordinates
    local points_url="https://api.weather.gov/points/$LATITUDE,$LONGITUDE"
    local points_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$points_url" 2>/dev/null)
    
    if [ -z "$points_data" ]; then
        echo "ERROR: Cannot reach weather.gov"
        return 1
    fi
    
    # Extract URLs
    local forecast_url=$(echo "$points_data" | grep -o '"forecast":[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    local forecast_hourly_url=$(echo "$points_data" | grep -o '"forecastHourly":[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    local county=$(echo "$points_data" | grep -o '"county":[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | sed 's/.*\/\([^\/]*\)$/\1/')
    
    if [ -z "$forecast_url" ]; then
        echo "ERROR: Cannot parse weather data"
        return 1
    fi
    
    # Step 2: Get observation stations for actual current temp
    local stations_url=$(echo "$points_data" | grep -o '"observationStations":[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    local stations_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$stations_url" 2>/dev/null)
    local station_id=$(echo "$stations_data" | grep -o '"stationIdentifier":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    
    # Step 3: Get actual current observation from nearest station
    local current_temp="--"
    if [ -n "$station_id" ]; then
        local obs_url="https://api.weather.gov/stations/$station_id/observations/latest"
        local obs_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$obs_url" 2>/dev/null)
        if [ -n "$obs_data" ]; then
            # Temperature in Celsius, need to extract and convert
            # Value is on its own line in the JSON, so use grep after finding temperature block
            local temp_c=$(echo "$obs_data" | grep -A3 '"temperature"' | head -4 | grep '"value"' | head -1 | grep -o '[0-9.-]*'| head -1)
            if [ -n "$temp_c" ] && [ "$temp_c" != "null" ]; then
                # Convert C to F: (C * 9/5) + 32
                current_temp=$(echo "scale=0; ($temp_c * 9 / 5) + 32" | bc 2>/dev/null || echo "--")
            fi
        fi
    fi
    
    # Step 4: Get the forecast for high/condition
    local forecast_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$forecast_url" 2>/dev/null)
    
    if [ -z "$forecast_data" ]; then
        echo "ERROR: Cannot fetch forecast"
        return 1
    fi
    
    # Step 5: Get hourly forecast for precipitation chance
    local hourly_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$forecast_hourly_url" 2>/dev/null)
    
    # Step 6: Get active weather alerts for your county
    local alerts_url="https://api.weather.gov/alerts/active/zone/$county"
    local alerts_data=$(curl -s -A "$USER_AGENT" --max-time 10 "$alerts_url" 2>/dev/null)
    
    # Parse forecast data (for high temp and conditions)
    local forecast_high=$(echo "$forecast_data" | grep -o '"temperature":[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
    local temp_unit="F"
    local condition=$(echo "$forecast_data" | grep -o '"shortForecast":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    local wind=$(echo "$forecast_data" | grep -o '"windSpeed":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    local wind_dir=$(echo "$forecast_data" | grep -o '"windDirection":[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    
    # Parse precipitation chance from hourly
    local precip_chance="0"
    if [ -n "$hourly_data" ]; then
        precip_chance=$(echo "$hourly_data" | grep -o '"probabilityOfPrecipitation":[[:space:]]*{[^}]*"value":[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*$')
        [ -z "$precip_chance" ] && precip_chance="0"
    fi
    
    # Parse alerts - extract event types (limit to 2 most important)
    local alert_list=""
    if [ -n "$alerts_data" ]; then
        alert_list=$(echo "$alerts_data" | grep -o '"event":[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/' | head -2)
    fi
    
    # Format alerts for storage (use ~ as separator to avoid conflicts)
    local alerts_formatted=""
    if [ -n "$alert_list" ]; then
        alerts_formatted=$(echo "$alert_list" | tr '\n' '~')
    else
        alerts_formatted="NONE"
    fi
    
    # Format the output with multiple delimiters: | for main fields, ~ for alerts
    local weather_output="$current_temp°$temp_unit|$forecast_high°$temp_unit|$condition|$wind $wind_dir|$precip_chance%|$alerts_formatted"
    
    # Save to cache
    echo "$weather_output" > "$CACHE_FILE"
    
    echo "$weather_output"
}

# Function to display weather
show_weather() {
    clear
    local MAX=36  # Max chars per line (fits 40 wide pane with padding)
    
    # Compact header
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  Weather Monitor - Storm Edition     ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════╝${NC}"
    
    # Get weather data (cached or fresh)
    WEATHER_DATA=$(get_weather_data)
    
    if [[ "$WEATHER_DATA" == ERROR:* ]]; then
        echo -e "${RED}⚠ $WEATHER_DATA${NC}"
        echo "Check your connection."
    else
        # Split the data
        IFS='|' read -r CURRENT_TEMP HIGH_TEMP CONDITION WIND PRECIP ALERTS <<< "$WEATHER_DATA"

        # Truncate condition to fit pane (account for temp prefix ~16 chars)
        local COND_TRIM=$(echo "$CONDITION" | cut -c1-20)
        [ ${#CONDITION} -gt 20 ] && COND_TRIM="${COND_TRIM}.."
        
        # Location and time on same line
        echo -e "${BLUE}📍${NC} $CITY, $STATE | ${BLUE}🕐${NC} $(date '+%I:%M %p')"
        echo ""
        
        # FIXED-HEIGHT ALERT SECTION (always 3 lines - never changes height!)
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        if [ "$ALERTS" != "NONE" ] && [ -n "$ALERTS" ]; then
            local alert_count=0
            echo "$ALERTS" | tr '~' '\n' | while read -r alert; do
                if [ -n "$alert" ] && [ $alert_count -lt 2 ]; then
                    # Truncate alert to MAX chars
                    local atrim=$(echo "$alert" | cut -c1-$((MAX - 2)))
                    [ ${#alert} -gt $((MAX - 2)) ] && atrim="${atrim}.."
                    echo -e "${RED}${BOLD}⚠${NC} ${RED}${atrim}${NC}"
                    alert_count=$((alert_count + 1))
                fi
            done
            local alerts_shown=$(echo "$ALERTS" | tr '~' '\n' | grep -c .)
            for ((i=alerts_shown; i<2; i++)); do
                echo ""
            done
        else
            echo -e "${GREEN}✓ No active weather alerts${NC}"
            echo ""
        fi
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Current conditions - compact and truncated
        echo -e "${BOLD}${YELLOW}$CURRENT_TEMP${NC} (Hi:${YELLOW}$HIGH_TEMP${NC}) $COND_TRIM"
        echo -e "${CYAN}Wind:${NC} $WIND ${CYAN}|${NC} ${CYAN}Precip:${NC} $PRECIP"
        echo ""
        
        # Footer info - compact
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Cache status
        if [ -f "$CACHE_FILE" ]; then
            local current_time=$(date +%s)
            local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
            local cache_age=$((current_time - cache_time))
            local cache_remaining=$((CACHE_MAX_AGE - cache_age))
            
            if [ $cache_remaining -gt 0 ]; then
                local cache_mins=$((cache_remaining / 60))
                echo -e "${CYAN}💾${NC} Cached (${cache_mins}m) | ${CYAN}⏰${NC} Next: $(date -d "+$UPDATE_INTERVAL seconds" '+%I:%M %p' 2>/dev/null || date -v+${UPDATE_INTERVAL}S '+%I:%M %p' 2>/dev/null)"
            else
                echo -e "${YELLOW}🔄 Fetching fresh data...${NC}"
            fi
        fi
        
        echo -e "${GREEN}'r'${NC} refresh | ${RED}Ctrl+C${NC} quit"
    fi
}

# Main loop
while true; do
    show_weather
    
    # Wait for user input or timeout
    read -t $UPDATE_INTERVAL -n 1 key
    
    # If user pressed 'r', refresh immediately (but cache still applies)
    if [ "$key" = "r" ]; then
        continue
    fi
done
