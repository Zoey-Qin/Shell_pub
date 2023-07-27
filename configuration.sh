#!/bin/bash

# check if /opt/sddc and /opt/sds directories exist
if [ ! -d "/opt/sddc" ] && [ ! -d "/opt/sds" ]; then
    #get current date
    date=$(date +%m-%d)

    #check if directory with current date exists
    if [ ! -d "$date" ]; then
	echo "The directory $date does not exist"
	exit 1   
    else
    	#enter directory with current date
    	cd "$date"

    	# copy bootstrap.conf.yaml to current date folder
    	cp -p  "/xhere/bootstrap.conf.yaml" "./bootstrap.conf.yaml"

	# Output prompt information after copying
	echo "Modify configuration successfully"
    fi

else
    echo "The sddc or sds directory exists, please make sure that the cluster environment is cleaned thoroughly first"
    exit 1
fi
