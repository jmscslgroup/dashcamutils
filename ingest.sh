
# # TODO convert to snakemake

mkdir -p _ingest _processing _output _concatenated

for f in `ls _ingest/*.MP4`; do
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

echo "All files processed; moving concatenated files to cyverse local folders now."

IRODSDIR=/Users/sprinkle/work/data/cyverse/rahulbhadani/JmscslgroupData/PandaData/
echo "IRODSDIR=${IRODSDIR}"

for f in `ls _output/*.MP4`; do
    FILEDATE_S=$(date -j -f "%Y_%m%d_%H%M%S" $(echo $(basename $f) | cut -c 1-16) +%s)
    # echo "FILEDATE_S=${FILEDATE_S}"
    FILEDATE=$(date -r "${FILEDATE_S}" )
    PANDADATADIR=$(date -j -f "%Y_%m%d_%H%M%S" $(echo $(basename $f) | cut -c 1-16) +"%Y_%m_%d")
    
    echo "File $f (date estimate=${FILEDATE}) should go in folder "
    echo "   ${IRODSDIR}${PANDADATADIR}"
    
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
            NEWVIDEOFILENAME="$(echo $(basename "${canfile}") | rev | cut -d'_' -f3- | rev)"_dashcam.mp4
            echo "NEWVIDEOFILENAME=${NEWVIDEOFILENAME}"
        elif [[ ${DIFF} -lt 180 ]]; then
            echo " Possible wider match includes ${canfile} (date=${CANFILEDATE})"
            echo " DIFF=${DIFF}"
            NEWVIDEOFILENAME="$(echo $(basename "${canfile}") | rev | cut -d'_' -f3- | rev)"_dashcam.mp4
            echo "NEWVIDEOFILENAME=${NEWVIDEOFILENAME}"
        fi
        
        if [[ ! "x${NEWVIDEOFILENAME}" == "x" ]]; then
            echo "Moving file to matching directory, with matching name:"
            mv $f ${IRODSDIR}${PANDADATADIR}/${NEWVIDEOFILENAME}
        fi
        
    done

done
