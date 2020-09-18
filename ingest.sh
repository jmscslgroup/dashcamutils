
# # TODO convert to snakemake

function usage {
    echo "./ingest.sh [-nk] -i rawmoviesfolder [-d irods_directory] [-c _concatenated]"
    echo " Processes the _ingest folder to produce uploadable webcam videos"
    echo " -n: run in test mode only to see what movies should be concatenated"
    # echo " -v: turn on verbose mode"
    echo " -k: keep a local copy of final versions, do not send to IRODS folder"
    echo " -i _ingest: name of ingest folder"
    echo " -d _output: destination of output (finalized) files"
    echo " -c _concatenated: directory in which to store concatenated videos"
}

verbose=0
test=0
FILENAME=
IRODSDIR=
INGEST=_ingest
CONCATLEFTOVERS=_concatenated
COPYTOIRODS=1
while getopts "h?nkf:d:c:i:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    v)  verbose=1
        ;;
    n)  test=1
        ;;
    k)  COPYTOIRODS=0
        ;;
    i)  INGEST=${OPTARG}
        ;;
    d)  IRODSDIR=${OPTARG}
        ;;
    c)  CONCATLEFTOVERS=${OPTARG}
        ;;
    esac
done

IRODSDIR_DEFAULT=/Users/sprinkle/work/data/cyverse/rahulbhadani/JmscslgroupData/PandaData/
if [[ "x${IRODSDIR}" = "x" ]]; then
    read -p "Would you like to copy webcams to ${IRODSDIR_DEFAULT}?" yn
    case $yn in 
        [Yy]* ) IRODSDIR=${IRODSDIR_DEFAULT}; 
        ;;
        [Nn]* ) IRODSDIR=""; 
        ;;
        * ) echo "Please answer y/n or Y/N";;
    esac
fi

mkdir -p _processing _output _concatenated

if [ ! -d ${INGEST} ]; then
    echo "Error! Ingest directory (${INGEST}) does not exist. Aborting."
    exit -1
fi

for f in `ls ${INGEST}/*.MP4`; do
    if [[ ! -f _processing/$(basename $f) &&
          ! -f _output/$(basename $f) &&
          ! -f _concatenated/$(basename $f) ]]; then
        ./resample.sh $f _processing/$(basename $f)
    else
        echo "File $(basename $f) already found...skipping."
    fi
done

# for now, just process
# exit 0

#
# # make all the processed files write only, to avoid errors in scripting
chmod u-w _processing/*
#
PROCESSINGFILES=$(ls _processing/*.MP4)

echo ${PROCESSINGFILES}

while [[ ${PROCESSINGFILES[0]} ]]; do
    # echo "Excecuting from _processing folder..."
    # get the first file
    FILEMP4=$(echo ${PROCESSINGFILES} | cut -d' ' -f1 )
    echo "available file is: " ${FILEMP4}
    # echo "Moving ${FILEMP4} to _proctest/"
    # mv ${FILEMP4} _proctest/
    echo "./concatMovies.sh ${FILEMP4}"
    ./concatMovies.sh -f ${FILEMP4} 
    
    if [[ -f ${FILEMP4} ]]; then
        echo "Error! ${FILEMP4} was not processed correctly...aborting."
        exit
    fi
    
    PROCESSINGFILES=$(ls _processing/*.MP4)
    echo ${PROCESSINGFILES}[0]
done

# IRODSDIR=/Users/sprinkle/work/data/cyverse/rahulbhadani/JmscslgroupData/PandaData/
echo "IRODSDIR=${IRODSDIR}"

if [[ $COPYTOIRODS = 1 ]]; then
    if [[ ! "x${IRODSDIR}" = "x" ]]; then

        echo "All files processed; moving concatenated files to cyverse local folders now."
        for f in `ls _output/*.MP4`; do
            FILEDATE_S=$(date -j -f "%Y_%m%d_%H%M%S" $(echo $(basename $f) | cut -c 1-16) +%s)
            # echo "FILEDATE_S=${FILEDATE_S}"
            FILEDATE=$(date -r "${FILEDATE_S}" )
            PANDADATADIR=$(date -j -f "%Y_%m%d_%H%M%S" $(echo $(basename $f) | cut -c 1-16) +"%Y_%m_%d")
    
            echo "File $f (date estimate=${FILEDATE}) should go in folder "
            echo "   ${IRODSDIR}${PANDADATADIR}"
            
            # find out the extension
            BASEFILENAME=$(basename ${f})
            EXTENSION=
            if [[ $(basename ${BASEFILENAME} A.MP4)A.MP4 == ${BASEFILENAME} ]]; then
                EXTENSION=A
            elif [[ $(basename ${BASEFILENAME} A_tr.MP4)A_tr.MP4 == ${BASEFILENAME} ]]; then
                EXTENSION=A
            elif [[ $(basename ${BASEFILENAME} B.MP4)B.MP4 == ${BASEFILENAME} ]]; then
                EXTENSION=B
            elif [[ $(basename ${BASEFILENAME} B_tr.MP4)B_tr.MP4 == ${BASEFILENAME} ]]; then
                EXTENSION=B
            fi            
    
            # what CAN files exist in those folders?
            for canfile in `ls ${IRODSDIR}${PANDADATADIR}/*CAN*.csv`; do
        
                # 2020-05-13-19-05-07
                CANFILEDATE_S=$(date -j -f "%Y-%m-%d-%H-%M-%S" $(echo $(basename $canfile) | cut -d"_" -f1) +%s)
                CANFILEDATE=$(date -r ${CANFILEDATE_S} )
                # echo " CANFILEDATE_S=${CANFILEDATE_S}"
                # echo " Possible match includes ${canfile} (date=${CANFILEDATE})"
                DIFF1=$(( ${FILEDATE_S} - ${CANFILEDATE_S} ))
                DIFF=${DIFF1#-}
                # echo " DIFF=${DIFF}"
        
                NEWVIDEOFILENAME=
                if [[ ${DIFF} -lt 90 ]]; then
                    echo " Possible match includes ${canfile} (date=${CANFILEDATE})"
                    echo " DIFF=${DIFF}"
                    NEWVIDEOFILENAME="$(echo $(basename "${canfile}") | rev | cut -d'_' -f3- | rev)"_dashcam${EXTENSION}.mp4
                    echo "NEWVIDEOFILENAME=${NEWVIDEOFILENAME}"
                elif [[ ${DIFF} -lt 180 ]]; then
                    echo " Possible wider match includes ${canfile} (date=${CANFILEDATE})"
                    echo " DIFF=${DIFF}"
                    NEWVIDEOFILENAME="$(echo $(basename "${canfile}") | rev | cut -d'_' -f3- | rev)"_dashcam${EXTENSION}.mp4
                    echo "NEWVIDEOFILENAME=${NEWVIDEOFILENAME}"
                fi
        
                if [[ ! "x${NEWVIDEOFILENAME}" == "x" ]]; then
                    echo "Moving file to matching directory, with matching name:"
                    if [ $test == "0" ]; then
                        mv $f ${IRODSDIR}${PANDADATADIR}/${NEWVIDEOFILENAME}
                        FOLDER_TMP=$(dirname $f)
                        if [[ "x$FOLDER_TMP" == "x" ]]; then
                            FOLDER_TMP="."
                        fi
                        BASE_TMP=$(basename $f)
                        LOGNAME=${FOLDER_TMP}/mv_${BASE_TMP}.txt
                        touch ${LOGNAME}
                        echo "Moved $f to ${IRODSDIR}${PANDADATADIR}/${NEWVIDEOFILENAME}" >> ${LOGNAME}
                    fi
                fi
        
            done

        done
    else
        echo "No IRODSDIR available, quitting."
    fi
else
    echo "Not copying videos to IRODS folder, quitting."
fi
