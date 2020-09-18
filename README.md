# dashcamutils


```
git clone https://github.com/jmscslgroup/dashcamutils
cd dashcamutils
./ingest.sh -i path_to_raw_videos_folder
```

It will work for a folder that holds videos, but not a folder that holds a folder of videos.

You may want to change the irods path in---it works best if you have a folder w/ the panda-recorded data 
on your machine in a certain path. With the IRODS data path, a video that has a time stamp that is close 
enough to vehicle data will be automatically renamed to have the same prefix as those data files.

```
./ingest.sh -i path_to_raw_videos_folder -d path_to_irods_data
```
