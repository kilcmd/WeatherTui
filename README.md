Please Read In Full. 

When you create the script please make sure to make the script executable. 
chmod +x nameofscript.sh

To adjust the location of the app, you need to edit the lat and long here. 

# ═══════════════════════════════════════════════════════════
# 📍 LOCATION SETTINGS - EASY TO CUSTOMIZE!
# ═══════════════════════════════════════════════════════════
# For weather.gov, we need latitude and longitude
# You can find yours at: https://www.latlong.net/

LATITUDE="40.7128"      # New york, NY latitude
LONGITUDE="-74.0060"    # New york, NY longitude
CITY="New York"        # Display name
STATE="New York"         # Display name


When the file runs it creates a cache file.  
This file is located in your /tmp/ 
It's going to look something like this. 
tmpt/WeatherApp-ny.sh <- confirm.  

^ If you mod the app and try to run it again, make sure to delete the cache file!

If you plan to run multiple instances of the app, edit line 25 in the app. 
CACHE_FILE="/tmp/weather_cache_newyork_$USER.txt" <- Change the city name.  

