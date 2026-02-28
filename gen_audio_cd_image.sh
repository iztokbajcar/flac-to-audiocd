#!/bin/bash

function command_exists_guard() {
    if [ -z $(command -v "$1") ]; then
        echo "ERROR: Command '$1' not installed!" >&2
        exit 1
    fi
}

function convert_to_cd_quality() {
    local -n FILES_=$1
    local TMP_DIR=$2

    for F in "${FILES_[@]}"; do
        echo "Converting $(basename "$F")"
        sox "$F" -b 16 -r 44100 -c 2 "${TMP_DIR}/$(basename "$F")"
    done
}

function generate_cue() {
    local -n FILES_=$1
    local OUTPUT_NAME=$2

    # get album info from the first file
    local FIRST="${FILES_[0]}"
    local ALBUM=$(metaflac --show-tag=ALBUM "$FIRST" | sed 's/ALBUM=//')
    local ALBUMARTIST=$(metaflac --show-tag=ALBUMARTIST "$FIRST" | sed 's/ALBUMARTIST=//')

    echo "PERFORMER \"$ALBUMARTIST\""
    echo "TITLE \"$ALBUM\""
    echo "FILE \"${OUTPUT_NAME}.bin\" BINARY"

    local CUMUL_SAMPLES=0

    for F in "${FILES_[@]}"; do
        # read metadata
        local TITLE=$(metaflac --show-tag=TITLE "$F" | sed 's/TITLE=//')
        local ARTIST=$(metaflac --show-tag=ARTIST "$F" | sed 's/ARTIST=//')
        local TRACK=$(metaflac --show-tag=TRACKNUMBER "$F" | sed 's/TRACKNUMBER=//')

        local TRACK_SAMPLES=$(metaflac --show-total-samples "$F")
        local CUMUL_FRAMES=$(( CUMUL_SAMPLES / 588 ))

        # calculate offset from the beginning of CD
        local MINUTE=$(( CUMUL_FRAMES / 75 / 60 ))
        local SECOND=$(( (CUMUL_FRAMES / 75) % 60 ))
        local FRAME=$(( CUMUL_FRAMES % 75 ))

        # print track info
        printf "  TRACK %02d AUDIO\n" $TRACK
        echo "    TITLE \"${TITLE}\""
        echo "    PERFORMER \"${ARTIST}\""
        printf "    INDEX 01 %02d:%02d:%02d\n" $MINUTE $SECOND $FRAME

        CUMUL_SAMPLES=$(( CUMUL_SAMPLES + TRACK_SAMPLES ))
    done
}

function join_tracks() {
    local -n FILES_=$1
    local OUTPUT_DIR=$2
    local TMP_DIR=$3

    echo "Joining these tracks:"
    echo "${FILES_[@]}"

    shntool join -d "$TMP_DIR" "${FILES_[@]}"
    sox "$TMP_DIR/joined.wav" -t raw -r 44100 -e signed -b 16 -c 2 "$OUTPUT_DIR/album.bin"

    rm "$TMP_DIR/joined.wav"
}

# fail if the required commands don't exist
command_exists_guard metaflac
command_exists_guard printf
command_exists_guard sed
command_exists_guard shntool
command_exists_guard sox

INPUT_DIR=${1:-$PWD}
OUTPUT_DIR=${2:-$INPUT_DIR}

# get file listing
FILES=("$INPUT_DIR"/*.flac)

# create a temporary directory
TMP_DIR=$(mktemp -d)

convert_to_cd_quality FILES "$TMP_DIR"
CONVERTED_FILES=("$TMP_DIR"/*.flac)
generate_cue CONVERTED_FILES "album" > "$OUTPUT_DIR"/album.cue

join_tracks CONVERTED_FILES "$OUTPUT_DIR" "$TMP_DIR"

echo "$CUE_CONTENTS"

# remove the temporary directory
if [ -n "$TMP_DIR" ]; then
    rm "$TMP_DIR"/*.flac
    rmdir $TMP_DIR
fi
