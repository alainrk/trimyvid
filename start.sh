#!/bin/bash

TMP_FILE=".tmp.json"
TMP_OUTPUT_FILE="output.mp4"
LIST_FILE="list.json"
BASE_FOLDER_VIDEOS="./videos"

# Help! I need somebody...
if [[ $1 = '-h' -o $1 = '---help' ]]; then
  echo -e "Usage:\n\tWith options: ./start.sh YOUTUBE_LINK 05:02:15 06:04:18 dest.mp4"
  echo -e "\tAll optional: ./start.sh\n"
  exit 0
fi

# Init everything we need
if [[ ! -f $LIST_FILE ]]; then
  echo "{}" > $LIST_FILE
fi

if [[ ! -d $BASE_FOLDER_VIDEOS ]]; then
  mkdir $BASE_FOLDER_VIDEOS
fi

if [[ -z $1 ]]; then
  echo "File origin:"
  read LINK
else
  LINK=$1
fi

# Download or retrieve file from cache
FILENAME=$(cat list.json | jq ".\"${LINK}\"")
if [[ $FILENAME = null ]]; then
  # Download it
  echo "File does not exists, downloading..."
  youtube-dl --recode-video mp4 $LINK -o $TMP_OUTPUT_FILE &&
  # Save the reference
  FILENAME=$(date +%s).mp4
  mv $TMP_OUTPUT_FILE $BASE_FOLDER_VIDEOS/$FILENAME
  echo filename = $FILENAME
  cat list.json | jq ".\"${LINK}\" = \"${FILENAME}\"" > $TMP_FILE &&
  mv $TMP_FILE list.json
  # Just to be sure
  rm -f $TMP_FILE
  # youtube-dl
else
  echo "File exists: $SRC_FILE"
fi

SRC_FILE=$TMP_OUTPUT_FILE $BASE_FOLDER_VIDEOS/$FILENAME

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

exit 0