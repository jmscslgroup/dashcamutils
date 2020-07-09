#/bin/bash


function usage {
    echo "./concatMovies.sh [-vn] -f MOVIE.MP4 [-d _output] [-c _concatenated]"
    echo " Pass in what you think is the first movie, it adds a second"
    echo " (trimmed) movie to the end, if the timelines match up, and renames"
    echo " the new movie to have both numerical identifiers, but keeps the initial"
    echo " start time of the recorded movie in the filename."
    echo " -n: run in test mode only to see what movies should be concatenated"
    echo " -v: turn on verbose mode"
    echo " -f directory/YYYY-MMD-...-dashcame-filename.MP4: input filename"
    echo " -d _output: destination of output (finalized) files"
    echo " -c _concatenated: directory in which to store concatenated videos"
}

verbose=0
test=0
FILENAME=
DESTDIR=_output
CONCATLEFTOVERS=_concatenated
while getopts "h?vnf:d:c:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    v)  verbose=1
        ;;
    n)  test=1
        ;;
    f)  FILENAME=${OPTARG}
        ;;
    d)  DESTDIR=${OPTARG}
        ;;
    c)  CONCATLEFTOVERS=${OPTARG}
        ;;
    esac
done

echo "verbose=${verbose}"
echo "test=${test}"

# exit 0


# if [[ $# -ge 1 ]]; then
#     FILENAME=${OPTIND}
#     echo "FILENAME=${FILENAME}"
# fi
#
# if [[ $# -ge 2 ]]; then
#     DESTDIR=$2
# else
#     DESTDIR=_output
# fi
#
# if [[ $# -ge 3 ]]; then
#     CONCATLEFTOVERS=$3
# else
#     CONCATLEFTOVERS=_concatenated
# fi

if [[ ! -f ${FILENAME} ]]; then
    echo "Error, unable to access ${FILENAME}"
    exit 1
fi

# exit 0

# create directories if they do not yet exist
if [[ ! -d ${DESTDIR} ]]; then
    mkdir ${DESTDIR}
fi
if [[ ! -d ${CONCATLEFTOVERS} ]]; then
    mkdir ${CONCATLEFTOVERS}
fi



if [[ ! "x${FILENAME}" == "x" ]]; then
    BASEFILENAME=$(basename ${FILENAME})
    DIRNAME=$(dirname ${FILENAME})
    
    if [ ! -d ${DIRNAME} ]; then
        echo "Unable to proceed, DIRNAME not found (DIRNAME=${DIRNAME})"
        exit
    fi
    
    FILENAMEDATE=$(echo ${BASEFILENAME} | cut -c 1-16)
    CREATEDATE=$(date -j -f %Y_%m%d_%H%M%S $(echo $FILENAMEDATE) )
    
    # what is the sequence #?
    SEQ=$(echo $(basename ${BASEFILENAME} [.MP4][.mp4]) | cut -d'_' -f4-)
    echo "SEQ=${SEQ}"
    
    # check to see if we are an A or B file
    EXTENSION=.MP4
    if [[ $(basename ${BASEFILENAME} A.MP4)A.MP4 == ${BASEFILENAME} ]]; then
        EXTENSION=A.MP4
    elif [[ $(basename ${BASEFILENAME} A_tr.MP4)A_tr.MP4 == ${BASEFILENAME} ]]; then
        EXTENSION=A.MP4
    elif [[ $(basename ${BASEFILENAME} B.MP4)B.MP4 == ${BASEFILENAME} ]]; then
        EXTENSION=B.MP4
    elif [[ $(basename ${BASEFILENAME} B_tr.MP4)B_tr.MP4 == ${BASEFILENAME} ]]; then
        EXTENSION=B.MP4
    fi
    
    echo "EXTENSION=${EXTENSION}"
    
    # echo "${FILENAME}"
    # echo " created approximately at ${CREATEDATE}"
    DURATION=$(ffprobe ${FILENAME} 2>&1 | grep "Duration" | cut -d ' ' -f4 | cut -d',' -f1)
    echo " duration is: ${DURATION}"
    LASTWRITE=$(ffprobe ${FILENAME} 2>&1 | grep creation_time | head -n 1  | cut -d":" -f2- | cut -d' '  -f2)
    WRITEDATE=$(date -j -f "%Y-%m-%dT%H:%M:%S.000000Z" ${LASTWRITE})
    echo " last write was at: ${WRITEDATE}"
    
    HOURS=$(echo ${DURATION} | cut -d':' -f1 | bc)
    echo " hours of video were ${HOURS}"
    MINUTES=$(echo ${DURATION} | cut -d':' -f2 | bc)
    echo " minutes of video were ${MINUTES}"
    
    if [[ ${HOURS} > 0 ]]; then
        MINUTES=$(( $(($HOURS*60)) + $MINUTES))
    fi
    SECONDS=$(echo ${DURATION} | cut -d':' -f3 | cut -d'.' -f1 | bc)
    if [ "${SECONDS}" = "0" ]; then
        SECONDS="00"
    fi
    echo " seconds of video were ${SECONDS}"
    
    echo "Will add ${MINUTES} minutes and ${SECONDS} seconds to expected start time of video"
    
    # exit
    
    
    # if seconds are equal to 1, then we are very likely looking at needing the next video
    if [[ ${SECONDS} == "2" || ${SECONDS} == "1" || ${SECONDS} == "0" ]]; then
        # using VAR#0 to remove the leading 0 in the case of 08 and 09 which are octal #s
        NEXTDATE=$(date -j -f "%Y_%m%d_%H%M%S" -v+${MINUTES#0}M "${FILENAMEDATE}" +%Y_%m%d_%H%M)
        echo "NEXTDATE=${NEXTDATE}"
        NEXTDATE_SECONDS=$(date -j -f "%Y_%m%d_%H%M%S" -v+${SECONDS#0}S "${NEXTDATE}" +%Y_%m%d_%H%M)
        echo "NEXTDATE_SECONDS=${NEXTDATE_SECONDS}"
        
        # update the nextdate if adding seconds worked out
        if [ ! "x${NEXTDATE_SECONDS}" = "x" ]; then
            NEXTDATE=${NEXTDATE_SECONDS}
        fi
        
        NEXTDATE1=$(date -j -f "%Y_%m%d_%H%M%S" -v+$((${MINUTES#0}+1))M "${FILENAMEDATE}" +%Y_%m%d_%H%M)
        # look into the future for related filenames
        echo " next file would be at ${NEXTDATE}" or ${NEXTDATE1}
        
        if [ "x${NEXTDATE}" = "x" ]; then
            echo "Yikes, something went wrong setting the date NEXTDATE, aborting"
            exit 1
        fi
        if [ "x${NEXTDATE1}" = "x" ]; then
            echo "Yikes, something went wrong setting the date NEXTDATE1, aborting"
            exit 1
        fi

        f=`find ${DIRNAME} -name ${NEXTDATE}*${EXTENSION}`
        f1=`find ${DIRNAME} -name ${NEXTDATE1}*${EXTENSION}`

        BASENAME=""
        NEXTFILE=""
        if [ ! "x${f}" = "x" ]; then
            BASENAME=$(basename ${f} .MP4)
            NEXTFILE=${f}
            echo "Found potential following video at ${f} (basename = ${BASENAME})"
        elif [ ! "x${f1}" = "x" ]; then
            BASENAME=$(basename ${f1} .MP4)
            NEXTFILE=${f1}
            echo "Found potential following video at ${f1}"
        else
            echo "Did not find anything , BASENAME=${BASENAME}"
        fi
        
        if [ ! "x${BASENAME}" = "x" ]; then
            echo "need to concatenate: "
            echo "   ${FILENAME} (dur=${DURATION}) should add "
            echo "   ${NEXTFILE}_tr to its end"
            TRIMFILE=${BASENAME}_tr.MP4
            SEQ2=$(echo $(basename $(echo $(basename ${TRIMFILE} [.MP4][.mp4]) | cut -d'_' -f4-) .MP4))
            CONCATOUTFILE=$(basename ${FILENAME} .MP4)_${SEQ2}.MP4
            if [ ! -f ${CONCATLEFTOVERS}/${TRIMFILE} ]; then
                if [[ "${test}" == "1" ]]; then
                    echo "test mode enabled: would run:"
                    echo " ffmpeg -i ${NEXTFILE} -ss 00:00:01  ${CONCATLEFTOVERS}/${TRIMFILE}"
                else
                    ffmpeg -i ${NEXTFILE} -ss 00:00:01  ${CONCATLEFTOVERS}/${TRIMFILE}
                    echo "moving ${NEXTFILE} to ${CONCATLEFTOVERS}"
                    mv ${NEXTFILE} ${CONCATLEFTOVERS}
                fi
            else
                echo "No need to process, found file ${CONCATLEFTOVERS}/${TRIMFILE}"
                echo " moving nextfile=${NEXTFILE} to ${CONCATLEFTOVERS}"
                mv ${NEXTFILE} ${CONCATLEFTOVERS}
            fi

                    # echo " mv ${NEXTFILE} ${CONCATLEFTOVERS}"
                    # echo " # concatenate the two movies:"
                    # echo " echo """file ${FILENAME}""" > concatList.txt"
                    # echo " echo """file ${CONCATLEFTOVERS}/${TRIMFILE}""" >> concatList.txt"
                    # echo " cat concatList.txt"
                    # echo " ffmpeg -f concat -safe 0 -i concatList.txt -c copy -map_metadata 0 ${CONCATLEFTOVERS}/${CONCATOUTFILE}"
                    # ffmpeg -f concat -safe 0 -i concatList.txt -c copy -map_metadata 0 ${CONCATLEFTOVERS}/${CONCATOUTFILE}
                    # echo " # Moving old files into ${CONCATLEFTOVERS}"
                    # echo " mv ${FILENAME} ${CONCATLEFTOVERS}"
                    # # echo " mv ${TRIMFILE} ${CONCATLEFTOVERS}"
                    # echo " rm concatList.txt"

            # now time to concatenate
                    echo "Now concatenating the two movies:"
                    echo "file ${FILENAME}" > concatList.txt
                    echo "file ${CONCATLEFTOVERS}/${TRIMFILE}" >> concatList.txt
                    cat concatList.txt
                    echo "ffmpeg -f concat -safe 0 -i concatList.txt -c copy -map_metadata 0 ${DIRNAME}/${CONCATOUTFILE}"
                    ffmpeg -f concat -safe 0 -i concatList.txt -c copy -map_metadata 0 ${DIRNAME}/${CONCATOUTFILE}
                    echo "Moving old files into ${CONCATLEFTOVERS}"
                    mv ${FILENAME} ${CONCATLEFTOVERS}
                    # mv ${TRIMFILE} ${CONCATLEFTOVERS}
                    rm concatList.txt
            
        else
            echo "A rare event: movie ends with :01 but is not extended. Move it along"
            echo "${FILENAME} (dur=${DURATION}) does not need to be concatenated with any following movies."
            echo "moving ${FILENAME} to ${DESTDIR}"
            if [[ "${test}" == "1" ]]; then
                echo "mv ${FILENAME} ${DESTDIR}"
            else
                mv ${FILENAME} ${DESTDIR}
            fi
        fi
    else
        echo "${FILENAME} (dur=${DURATION}) does not need to be concatenated with any following movies."
        echo "moving ${FILENAME} to ${DESTDIR}"
        if [[ "${test}" == "1" ]]; then
            echo "mv ${FILENAME} ${DESTDIR}"
        else
            mv ${FILENAME} ${DESTDIR}
        fi
    fi
else
    usage
fi


# # FILENAME="2020_0512_143153_050.MP4"
# # FILENAME="2020_0512_152248_052.MP4"
# FILENAME="2020_0512_132342_047.MP4"
# # FILENAME="2020_0512_140411_049.MP4"
