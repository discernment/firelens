#!/bin/bash

#This script:
#1. Pulls the webcam images from the USB drive to this computer.
#2. Converts each day's image directory into a video.
#
#_Assumed Structure of $source_
#The script assumes that $source has several subdirectories (eg motion, timer, etc).
#The script will iterate thru each subdirectory and find all the dates that have folders within the subdirectory.
#For each date, it will create a video from the jpgs in the directory.
#The script also assumes that most recent jpgs are not yet placed in a date subdirectory.
#These recent jpgs are cleared out at the beginning of each run as they should eventually be moved by the source to an appropriate date directory.
#A video for the recent jpgs will be created as well.
#
#_Structure Created on $target_
#The $target directory will have two man subdirectories, images and videos.
#The images subdirectory will have the rsync'd copy of $source.
#The videos subdirectory will have a subdirectory for each subdirectory in $source
#The videos subdirectories will each contain a set of videos, one per day.

##############
#Settings
##############
#The source directory (rsync style user@server:/the/path)
source=root@openwrt:/mnt/usb/webcam/

#The directory to sync this data.
target=/acquire/webcam/pull

##############
#Execution
##############
#Create the videos directory if not exist.
if [ ! -e "$target/videos" ]
then
	mkdir "$target/videos"
fi

#Clean out the files not associated with a date.  The recent jpgs.
find $target/images/ -mindepth 2 -maxdepth 2 -type f -name "*.jpg" -exec rm {} \;

#Copy the new images to this computer.
rsync -av -e ssh $source $target/images

#Iterate thru the sub directories (eg motion, timer, etc)
for dir in $(find $target/images -mindepth 1 -maxdepth 1 -type d)
do
	basename=$(basename $dir)

	#Iterate thru the date directories
	for date_dir in $(find $dir -mindepth 1 -maxdepth 1 -type d)
	do
		#Get the short name of this directory.
		datename=$(basename $date_dir)

		#Get the HHMMSS of the last image of this directory.
		last_image=$(ls -r $date_dir|head -n 1|sed 's/[^0-9]*[0-9]\{8\}\(.*\)\.jpg/\1/')

		#See if the latest video already exists.
		if [ ! -e "$target/videos/$basename/${datename}_${last_image}.mpg" ]
		then
			#Remove any old videos
			find "$target/videos/$basename" -name "${datename}_*.mpg" -delete

			#Create the directory if necessary
			if [ ! -e "$target/videos/$basename" ]
			then
				mkdir "$target/videos/$basename"
			fi

			#Create the video from all of the jpgs in that directory.
			/usr/bin/mencoder mf://$date_dir/*.jpg -mf fps=9:type=jpg -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o "$target/videos/$basename/${datename}_${last_image}.mpg"
		fi
	done
done
