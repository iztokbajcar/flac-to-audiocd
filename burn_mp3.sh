#!/bin/bash

source common.sh

command_exists_guard xorriso

INPUT_DIR=${1:-$PWD}
DEVICE=${2:-"/dev/sr1"}

PARAMS="-v dev=$DEVICE speed=4 -data album.iso"
CMD_SIMULATE="xorriso -as cdrecord -dummy $PARAMS"
CMD_WRITE="xorriso -as cdrecord $PARAMS"

(
    cd "$INPUT_DIR";
    echo "Simulating write to $DEVICE";
    $CMD_SIMULATE;

    read -p "Press ENTER to write to $DEVICE or ctrl+C to cancel...";
    $CMD_WRITE;
)
