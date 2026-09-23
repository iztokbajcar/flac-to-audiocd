#!/bin/bash

source common.sh

command_exists_guard cdrdao

INPUT_DIR=${1:-$PWD}
DEVICE=${2:-"/dev/sr0"}

# also swaps the byte order of the samples because cdrdao
# expects raw (.bin) files to bi big-endian, but cdemu wants them as little-endian;
# this allows playing the cd image normally with cdemu as well as writing it 
# correctly to the cd using cdrdao
PARAMS="--swap --device $DEVICE --speed 4 album.cue"
CMD_SIMULATE="cdrdao write --simulate $PARAMS"
CMD_WRITE="cdrdao write $PARAMS"

(
    cd "$INPUT_DIR";
    echo "Simulating write to $DEVICE";
    $CMD_SIMULATE;

    read -p "Press ENTER to write to $DEVICE or ctrl+C to cancel...";
    $CMD_WRITE;
)
