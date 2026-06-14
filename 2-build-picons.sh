#!/bin/bash

#####################
## Setup locations ##
#####################
location=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
temp=$(mktemp -d --suffix=.picons)
logfile=$(mktemp --suffix=.picons.log)

echo "$(date +'%H:%M:%S') - INFO: Log file located at: $logfile"

###########################
## Check path for spaces ##
###########################
if [[ $location == *" "* ]]; then
    echo "$(date +'%H:%M:%S') - ERROR: The path contains spaces, please move the repository to a path without spaces!"
    exit 1
fi

########################################################
## Search for required commands and exit if not found ##
########################################################
commands=( sed grep tr cat sort find mkdir rm cp mv readlink )
for i in ${commands[@]}; do
    if ! which $i &> /dev/null; then
        missingcommands="$i $missingcommands"
    fi
done
if [[ -z $missingcommands ]]; then
    echo "$(date +'%H:%M:%S') - INFO: All required commands are found!"
else
    echo "$(date +'%H:%M:%S') - ERROR: The following commands are not found: $missingcommands"
    exit 1
fi


if which pngquant &> /dev/null; then
    pngquant="pngquant"
    echo "$(date +'%H:%M:%S') - INFO: Image compression enabled!"
else
    pngquant="cat"
    echo "$(date +'%H:%M:%S') - WARNING: Image compression disabled! Try installing: pngquant"
fi

if which convert &> /dev/null; then
    echo "$(date +'%H:%M:%S') - INFO: ImageMagick was found!"
else
    echo "$(date +'%H:%M:%S') - ERROR: ImageMagick was not found! Try installing: imagemagick"
    exit 1
fi

if which rsvg-convert &> /dev/null; then
    svgconverter="rsvg-convert -w 1000 --keep-aspect-ratio --output "
    echo "$(date +'%H:%M:%S') - INFO: Using rsvg-convert as svg converter!"
else
    echo "$(date +'%H:%M:%S') - ERROR: rsvg-convert was not found! Try installing: librsvg2-bin"
    exit 1
fi

##############################################
## Parameters:                             ##
##   $1  resolution (e.g. 220x132)         ##
##   $2  resize     (e.g. 190x102)         ##
##   $3  type       (e.g. light)           ##
##   $4  background (e.g. transparent)     ##
##############################################

style=utf8snp


##############################
## Prepare output folder    ##
##############################
pngs=$location/pngs
info=$location/info
mkdir -p $pngs $info

#############################################
## Some basic checking of the source files ##
#############################################
if [[ $- == *i* ]]; then
    echo "$(date +'%H:%M:%S') - EXECUTING: Checking index"
    $location/resources/tools/check-index.sh $location/build-source utf8snp

    echo "$(date +'%H:%M:%S') - EXECUTING: Checking logos"
    $location/resources/tools/check-logos.sh $location/build-source/logos
fi

##########################################
## Build logo list from index file      ##
##########################################
logocollection=$(grep -v -e '^#' -e '^$' "$location/build-source/$style.index" | cut -d= -f2 | sort -u)
logocount=$(echo "$logocollection" | wc -l)
mkdir -p $temp/cache

resolution=$1
resize=$2
type=$3
background=$4

echo "$logocollection" | while read logoname ; do
        ((currentlogo++))
        if [[ $- == *i* ]]; then
            echo -ne "           Converting logo: $currentlogo/$logocount"\\r
        fi

        # Determine the logo type with fallbacks
        if [[ $type == "white" ]]; then
            if [[ -f $location/build-source/logos/$logoname.white.png ]] || [[ -f $location/build-source/logos/$logoname.white.svg ]]; then
                logotype=white
            elif [[ -f $location/build-source/logos/$logoname.light.png ]] || [[ -f $location/build-source/logos/$logoname.light.svg ]]; then
                logotype=light
            else
                logotype=default
            fi
        elif [[ $type == "light" ]]; then
            if [[ -f $location/build-source/logos/$logoname.light.png ]] || [[ -f $location/build-source/logos/$logoname.light.svg ]]; then
                logotype=light
            else
                logotype=default
            fi
	    elif [[ $type == "dark" ]]; then
            if [[ -f $location/build-source/logos/$logoname.dark.png ]] || [[ -f $location/build-source/logos/$logoname.dark.svg ]]; then
                logotype=dark
            else
                logotype=default
            fi
        else
            logotype=default
        fi

        [[ -f $pngs/$logoname.png ]] && continue

        echo $logoname.$logotype >> $logfile

        if [[ -f $location/build-source/logos/$logoname.$logotype.svg ]]; then
            logo=$temp/cache/$logoname.$logotype.png
            if [[ ! -f $logo ]]; then
                $svgconverter$logo $location/build-source/logos/$logoname.$logotype.svg 2>> $logfile >> $logfile
            fi
        else
            logo=$location/build-source/logos/$logoname.$logotype.png
        fi

        convert $location/build-source/backgrounds/$resolution/$background.png \( $logo -background none -bordercolor none -border 100 -trim -border 1% -resize $resize -gravity center -extent $resolution +repage \) -layers merge - 2>> $logfile | $pngquant - 2>> $logfile > $pngs/$logoname.png
    done

######################################
## Generate mapping file            ##
######################################
echo "$(date +'%H:%M:%S') - EXECUTING: Generating mapping file"
grep -v -e '^#' -e '^$' "$location/build-source/$style.index" | awk -F= '$1 != $2' > "$info/files.map"

######################################
## Generate MD5 hash file           ##
######################################
echo "$(date +'%H:%M:%S') - EXECUTING: Generating MD5 hashes"
find "$pngs" -maxdepth 1 -name "*.png" | sort | xargs md5sum > "$info/files.md5"

######################################
## Cleanup temporary files and exit ##
######################################
if [[ -d $temp ]]; then rm -rf $temp; fi

echo "$(date +'%H:%M:%S') - INFO: Finished building $style!"
exit 0
