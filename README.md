# flac-to-audiocd

This script creates a BIN/CUE image of an audio CD from FLAC files (useful for e.g. albums downloaded from Bandcamp).

## Usage

Run `./gen_audio_cd_image.sh <flac_files_directory>`. This will generate the CD image in the form of the `album.bin` and `album.cue` files in the specified directory.
You can them burn them to a CD or use `cdemu` to mount the image with `cdemu load 0 album.cue`.

## Dependencies

- metaflac
- sed
- shntool
- sox
