#/bin/bash
# Takes an input file and rescales it, keeping the metadata as possible

function usage {
    echo "resample MOVIE.MP4 [output]"
    echo " Resamples the movie to 360p"
}

FILENAME=
BASEFILENAME=
OUTPUT=

if [[ $# -ge 1 ]]; then
    FILENAME=$1
    BASEFILENAME=$(basename ${FILENAME} [.MP4][.mp4][.mov])
fi

if [[ $# -eq 2 ]]; then
    OUTPUT=$2
fi

if [[ -f ${OUTPUT} ]]; then
    echo "File ${OUTPUT} already exists...aborting."
    exit
fi

if [[ "x${OUTPUT}" == "x" ]]; then
    OUTPUT=${BASEFILENAME}_resampled.mp4
fi

if [[ ! "x${BASEFILENAME}" == "x" ]]; then
    echo "ffmpeg -i ${FILENAME} -vf scale=iw/2:ih/2 -map_metadata 0 ${OUTPUT}"
    ffmpeg -i ${FILENAME} -vf scale=iw/2:ih/2 -map_metadata 0 ${OUTPUT}
else
    usage
fi

# for f in `ls *.MP4`; do
# ; done
