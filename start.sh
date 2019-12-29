#!/bin/bash

TMP_FILE=".tmp.json"
TMP_OUTPUT_FILE="_tmp_output_video"
LIST_FILE="list.json"
BASE_FOLDER_VIDEOS="./videos"

BLUE="\033[0;34m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NORMAL="\033[0m"

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -t|--test)
      TEST='YES'
      shift 1
      ;;
    -u|--url)
      URL=$2
      shift 2
      ;;
    -s|--start)
      TIME1=$2
      shift 2
      ;;
    -e|--end)
      TIME2=$2
      shift 2
      ;;
    -o|--output)
      DEST_FILE=$2
      shift 2
      ;;
    -h|--help)
      HELP='YES'
      shift 1
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

# Help! I need somebody...
if [[ $HELP = "YES" ]]; then
  echo -e "Usage:\n\tWith options: ./start.sh YOUTUBE_LINK 05:02:15 06:04:18 dest.mp4"
  echo -e "\tAll optional: ./start.sh\n"
  exit 0
fi

# Init everything we need
if [[ ! -f $LIST_FILE ]]; then
  echo -e "${BLUE}Initializing file list...${NORMAL}"
  echo "{}" > $LIST_FILE
fi

if [[ ! -d $BASE_FOLDER_VIDEOS ]]; then
  echo -e "${BLUE}Initializing video folder...${NORMAL}"
  mkdir $BASE_FOLDER_VIDEOS
fi

if [[ -z $URL ]]; then
  echo -e "${GREEN}Insert youtube link:${NORMAL}"
  read URL
fi

# Download or retrieve file from cache
FILENAME=$(cat list.json | jq --raw-output ".\"${URL}\"")
if [[ $FILENAME = null ]]; then
  # Download it
  echo -e "${RED}File does not exist, downloading...${NORMAL}"
  youtube-dl --recode-video mp4 $URL -o $TMP_OUTPUT_FILE &&
  # Save the reference
  FILENAME=$(date +%s).mp4
  mv $TMP_OUTPUT_FILE*.mp4 $BASE_FOLDER_VIDEOS/$FILENAME
  cat list.json | jq ".\"${URL}\" = \"${FILENAME}\"" > $TMP_FILE &&
  mv $TMP_FILE list.json
  # Just to be sure
  rm -f $TMP_FILE
  # youtube-dl
else
  echo -e "${BLUE}File exists: ${FILENAME}${NORMAL}"
fi

SRC_FILE=$BASE_FOLDER_VIDEOS/$FILENAME

if [[ -z $TIME1 ]]; then
  echo -e "${GREEN} Insert start time (hh:mm:ss):${NORMAL}"
  read TIME1
fi

if [[ -z $TIME2 ]]; then
  echo -e "${GREEN}Insert end time (hh:mm:ss):${NORMAL}"
  read TIME2
fi

if [[ -z $DEST_FILE ]]; then
  echo -e "${GREEN}Insert destination filename (i.e. output.mp4):${NORMAL}"
  read DEST_FILE
fi

# Convert the times to seconds from the Epoch
SEC1=`gdate +%s -d ${TIME1}` &&
SEC2=`gdate +%s -d ${TIME2}` &&

# Use expr to do the math, let's say TIME1 was the start and TIME2 was the finish
DIFFSEC=`expr ${SEC2} - ${SEC1}` &&

# And use date to convert the seconds back to something more meaningful
TIME_DIFF=`gdate +%H:%M:%S -ud @${DIFFSEC}` &&
echo -e "${BLUE}You got time: ${TIME_DIFF}${NORMAL}" &&

echo -e "\n${BLUE}Launching:\n\tffmpeg -i ${SRC_FILE} -ss ${TIME1} -t ${TIME_DIFF} -async 1 -strict -2 ${DEST_FILE}${NORMAL}" &&
ffmpeg -i ${SRC_FILE} -ss ${TIME1} -t ${TIME_DIFF} -async 1 -strict -2 ${DEST_FILE} &&

exit 0