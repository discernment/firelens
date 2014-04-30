#!/bin/ash

#This is a CGI script for handling images produced by the webcam.
#It belongs in /www/cgi-bin
#It expects a parameter, q which is the filename of the image to be stored.
#It will store the file in the $target location, but will add a folder for the date portion of the filename.
#It can NOT be run under uhttpd (the default OpenWRT server) because PUT is not valid and the size of the request is too large.

#Define the root of all incoming webcam files.
root_folder=/mnt/usb/webcam

#Read the q parameter.
q=`echo "$QUERY_STRING" | sed -n 's/^.*q=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`

#Read the folder name.
parent_folder=$(dirname $q)

#Read the filename.
filename=$(basename $q)

#Derive folder name for the date.
date_folder=$(echo $filename|sed 's/\([^0-9]*[0-9]\{8\}\).*/\1/')

#Now create the final folder name
folder="$root_folder/$parent_folder/$date_folder"

#Be sure the date folder exists.
if [ ! -d "$folder" ]
then
	mkdir "$folder"
fi

#Write the contents of the file.
cat > "$folder/$filename"

#Return a 200
echo "HTTP/1.0 200 Ok"
echo ""
