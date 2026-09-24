#!/bin/bash

source common.sh

function convert_to_mp3() {
    local -n FILES_=$1
    local TMP_DIR=$2

    for F in "${FILES_[@]}"; do
        # extract cover art
        metaflac --export-picture-to="${TMP_DIR}"/cover.jpg "$F"

        local ALBUM_ARTIST=$(metaflac --show-tag=ALBUMARTIST "$F" | sed 's/ALBUMARTIST=//')
        local ARTIST=$(metaflac --show-tag=ARTIST "$F" | sed 's/ARTIST=//')
        local ALBUM=$(metaflac --show-tag=ALBUM "$F" | sed 's/ALBUM=//')
        local TITLE=$(metaflac --show-tag=TITLE "$F" | sed 's/TITLE=//')
        local TRACK=$(metaflac --show-tag=TRACKNUMBER "$F" | sed 's/TRACKNUMBER=//')
        local YEAR=$(metaflac --show-tag=DATE "$F" | sed 's/DATE=//')

        local DEST="${TMP_DIR}/$(basename "${F%.*}.mp3")"
        echo "Converting $(basename "$F")"
        sox "$F" -C 320 "$DEST"

        # delete all existing MP3 tags before writing track metadata as ID3v2
        eyeD3 --remove-all "$DEST"
        eyeD3 --v2 \
            --encoding utf16 \
            --album-artist "$ALBUM_ARTIST" \
            --artist "$ARTIST" \
            --album "$ALBUM" \
            --title "$TITLE" \
            --track "$TRACK" \
            --release-year "$YEAR" \
            --add-image="${TMP_DIR}"/cover.jpg:FRONT_COVER \
            "$DEST"

        rm "${TMP_DIR}"/cover.jpg
    done
    
}

function create_iso() {
    echo "Creating the ISO file..."
    xorriso -as mkisofs -o "${OUTPUT_DIR}/album.iso" -J -R -V "$ALBUM_ARTIST - $ALBUM" "$TMP_DIR"
}

# fail if the required commands don't exist
command_exists_guard eyeD3
command_exists_guard metaflac
command_exists_guard sed
command_exists_guard sox
command_exists_guard xorriso

INPUT_DIR=${1:-$PWD}
OUTPUT_DIR=${2:-$INPUT_DIR}

# get the file listing
FILES=("$INPUT_DIR"/*.flac)
ALBUM_ARTIST=$(metaflac --show-tag=ALBUMARTIST "${FILES[0]}" | sed 's/ALBUMARTIST=//')
ALBUM=$(metaflac --show-tag=ALBUM "${FILES[0]}" | sed 's/ALBUM=//')

# create a temporary directory
TMP_DIR=$(mktemp -d)

# convert files to MP3
convert_to_mp3 FILES "$TMP_DIR"
CONVERTED_FILES=("$TMP_DIR"/*.mp3)

# create the ISO file
create_iso 
