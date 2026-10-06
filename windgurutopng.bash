#!/bin/bash
# Larukiten windguru-overlay. v04102026_01 / Jyrki Tikka
#

set -euo pipefail

##############################################################################
# CONFIG
##############################################################################

# työskentelyhakemisto
BASE="/home/users/jyka/larukite"

# väliaikaistiedostot
TMP="$BASE/tmpdata.txt"
TXT="$BASE/larukitepng.txt"

# peruskuva minkä päälle lisätään tietoa:
OVERLAY="$BASE/larukite_kelikamera_overlay.png"

# tänne kirjoitetaan lopputulos tuuli- ja lämpötiladatoineen kameran noudettavaksi:
OUTPUT="/home/users/jyka/AA_KUVAT.JYKA.FI-JAKO/larukitepng.png"

# tuulidatan noutourl
WG_URL="https://www.windguru.cz/int/wgsapi.php?q=station_data_current&id_station=47&date_format=Y-m-d+H%3Ai%3As+T&&password=HIDDEN"

# lämpötilan noutopaikka
FMI_URL="https://opendata.fmi.fi/wfs?request=getFeature&storedquery_id=fmi::observations::weather::simple&place=Harmaja"

# vedenlämmön noutopaikka
BEACH_URL="https://api.hel.fi/servicemap/v2/unit/40098/?include=observations"

##############################################################################
# HARMAJA AIR TEMPERATURE
##############################################################################
HARMAJA_TEMP=$(
    curl -s "$FMI_URL" |
    grep -A1 '<BsWfs:ParameterName>t2m' |
    grep 'ParameterValue' |
    grep -v NaN |
    sed 's/.*<BsWfs:ParameterValue>//;s/<\/BsWfs:ParameterValue>.*//' |
    tail -1
)

##############################################################################
# SEA TEMPERATURE FROM LAUTTASAARI BEACH SENSOR
##############################################################################

BEACH_JSON=$(curl -s "$BEACH_URL")

WATER_TEMP=$(
    echo "$BEACH_JSON" |
    jq -r '.observations[]
    | select(.property=="measured_swimming_water_temperature")
    | .value'
)

WATER_TIME=$(
    echo "$BEACH_JSON" |
    jq -r '.observations[]
    | select(.property=="measured_swimming_water_temperature")
    | .time'
)


#vedenlämmön mittauksen ikä:
WATER_AGE=$(( ($(date +%s) - $(date -d "$WATER_TIME" +%s)) / 3600 ))

##############################################################################
# WINDGURU
##############################################################################

curl -s "$WG_URL" > "$TMP"

DATESTAMP=$(cut -d ':' -f9,10 "$TMP" | cut -c2-)

eadarray -t WIND_VALUES < <(
    tr ',' '\n' < "$TMP" |
    grep wind |
    cut -d ':' -f2 |
    while read -r v
    do
        echo "scale=1; $v/1.94384449" | bc
    done
)

AVG_WIND="${WIND_VALUES[0]}"
MAX_WIND="${WIND_VALUES[1]}"
MIN_WIND="${WIND_VALUES[2]}"

WIND_DIR=$(
    tr ',' '\n' < "$TMP" |
    grep wind |
    cut -d ':' -f2 |
    tail -1 |
    cut -d '.' -f1
)

##############################################################################
# WIND COLUMN
##############################################################################

cat > "$TXT" <<EOF
$DATESTAMP
avg $AVG_WIND m/s
max $MAX_WIND m/s
min $MIN_WIND m/s
direction $WIND_DIR
EOF

WIND_TEXT=$(cat "$TXT")



##############################################################################
# TEMP COLUMN
##############################################################################
EMP_TEXT="air ${HARMAJA_TEMP} C
sea ${WATER_TEMP} C (${WATER_AGE}h)"


##############################################################################
# RENDER
##############################################################################

if [ -s "$TXT" ]; then

# sivuttaissijainti:
WIND_X=630
TEMP_X=240

# korkeus pohjalta:
WIND_Y=20
TEMP_Y=150


convert "$OVERLAY" \
\
-font Helvetica-Bold \
-fill white \
-pointsize 40 \
-stroke black \
-strokewidth 2 \
-gravity SouthWest \
-annotate +${TEMP_X}+${TEMP_Y} "$TEMP_TEXT" \
\
-font Helvetica-Bold \
-fill white \
-pointsize 55 \
-stroke black \
-strokewidth 3 \
-gravity SouthWest \
-annotate +${WIND_X}+${WIND_Y} "$WIND_TEXT" \
\
"$OUTPUT"


fi
exit 0
