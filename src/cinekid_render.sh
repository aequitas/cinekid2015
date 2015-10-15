#!/usr/bin/env bash

base=$2
in_file=$4

# generate logfile name and output before redirecting
now=$(date +%s)
logfile=${base}/logs/${in_file//[^0-9a-zA-Z]/_}.${now}.log
echo "logging to: ${logfile}" 1>&2

# redirect output log logfile
exec > ${logfile} 2>&1

# fail on first error, print executing command and interpretation of command
set -vex

# get renderer name from first arg, and strip it from args list
renderer=$1
shift

# get filenames from remaining args
base=$1
lock=$2
in_file=$3
tmp=$4
out=$5

jpg=$(echo ${out}|sed -E 's/\.....?$/'.jpg/)

echo "starting conversion"

# start specified renderer with remaining args
${base}/renderers/cinekid_render_${renderer}.sh "$1" "$2" "$3" "$4" "$5"

# check if tmp output file has been created
test -f "${tmp}"

echo "finished conversion"

# test if in file is video, and generate jpg thumbnail
if /usr/bin/avprobe "${in_file}";then
    echo "starting generating jpg at 10 seconds"
    /usr/bin/avconv -i "${in_file}" -ss 00:00:10.0 -vcodec mjpeg -vframes 1 -f image2 "${jpg}";
    if test -f "${jpg}";then 
        echo "finished generating jpg at 10 second"
    else
        echo "failed generating jpg at 10 seconds (video to short?)"
        echo "starting generating jpg at 0 seconds"
        /usr/bin/avconv -i "${in_file}" -ss 00:00:00.0 -vcodec mjpeg -vframes 1 -f image2 "${jpg}"
        if test -f "${jpg}";then 
            echo "finished generating jpg at 0 second"
        else
            echo "failed to generate jpg at 1 second or 10 seconds"
        fi
    fi
else
    echo "no video file, skipping thumbnail"
fi

# make file 'done'
mv "${tmp}" "${out}"

# remove lock status
rm "${lock}"
