#!/bin/bash

TMP_FILE=".tmp.json"
LIST_FILE="list.json"
LINK="https://youtube.com/test"

cat list.json | jq ".\"${LINK}\" = null" > $TMP_FILE &&
mv $TMP_FILE list.json
# Just to be sure
rm -f $TMP_FILE

exit 0

echo -e "Usage:\n\tWith options: ./start.sh source.mp4 05:02:15 06:04:18 dest.mp4"
echo -e "\tAll optional: ./start.sh\n"

if [[ -z $1 ]]; then
  echo "File origin:"
  read SRC_FILE
else
  SRC_FILE=$1
fi

if [[ -z $2 ]]; then
  echo "Time start hh:mm:ss"
  read TIME1
else
  TIME1=$2
fi

if [[ -z $3 ]]; then
  echo "Time end hh:mm:ss"
  read TIME2
else
  TIME2=$3
fi

if [[ -z $4 ]]; then
  echo "Time end hh:mm:ss"
  read DEST_FILE
else
  DEST_FILE=$4
fi

# Convert the times to seconds from the Epoch
SEC1=`gdate +%s -d ${TIME1}`
SEC2=`gdate +%s -d ${TIME2}`

# Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
DIFFSEC=`expr ${SEC2} - ${SEC1}`

# And use date to convert the seconds back to something more meaningful
TIME_DIFF=`gdate +%H:%M:%S -ud @${DIFFSEC}`
echo Took $TIME_DIFF

echo "Launching:\n\tffmpeg -i $SRC_FILE -ss $TIME1 -t $TIME_DIFF -async 1 -strict -2 $DEST_FILE"
ffmpeg -i $SRC_FILE -ss $TIME1 -t $TIME_DIFF -async 1 -strict -2 $DEST_FILE
