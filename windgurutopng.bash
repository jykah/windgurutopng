#!/bin/bash
# Larukiten windguru-overlay. v20251101_01 / Jyrki Tikka
# adds windguru anemometer readings to transparent png file what is used as a webcam picture at https://larukite.fi/webcam

STATIONID=47
PASSWORD=salattu
BASEIMAGE=larukite_kelikamera_overlay.png
WORKDIR=/home/jyka/local/bin/dev
DESTIMG=/home/jyka/local/bin/dev/larukitepng.png
#/home/users/jyka/larukite


# end of variables

cd $WORKDIR

# create a tmp datafile
curl -q "https://www.windguru.cz/int/wgsapi.php?q=station_data_current&id_station=$STATIONID&date_format=Y-m-d+H%3Ai%3As+T&&password=$PASSWORD" > $WORKDIR/tmpdata.txt

# date and time to the pic
cut -d ':' -f9,10 $WORKDIR/tmpdata.txt |cut -c2- > $WORKDIR/larukitepng.txt

# get and reshape wind data. Change knots to m/s.
cat $WORKDIR/tmpdata.txt |tr ',' '\n' |grep wind|awk -F ',' '{print $1}'|cut -d ':' -f2|xargs -i echo "scale=1; {}/1.94384449"|bc|sed '1 s/^/avg /'|sed '2 s/^/max /' |sed '3 s/^/min /'|sed '4d'|sed '1 s#$# m/s#' |sed '2 s#$# m/s#' |sed '3 s#$# m/s#' >> $WORKDIR/larukitepng.txt 

# wind direction
cat $WORKDIR/tmpdata.txt |tr ',' '\n' |grep wind|awk -F ',' '{print $1}'|cut -d ':' -f2|tail -1|cut -d '.' -f1|xargs -i echo "direction {}" >> $WORKDIR/larukitepng.txt

# työnnetään data pohjakuvaan
# -gravity South jos otetaan täyden ruudun overlay käyttöön
# ekana leveyssuunta, sitten korkeus. + gravity vielä vaikuttaa
TEXT=$(cat $WORKDIR/larukitepng.txt)


# tarkastetaan rivimäärä, jos lopputulos onkin jotain ihan paskaa niin se ei ilmesty kameraan
lines=$(cat $WORKDIR/larukitepng.txt |wc -l)

if [ $lines -eq 5 ]; then
	convert -font Helvetica-Bold -fill white -pointsize 42 -stroke black -strokewidth 2 -draw "text 245,125 '$TEXT'" -gravity South $WORKDIR/$BASEIMAGE $DESTIMG
        exit 0
fi
