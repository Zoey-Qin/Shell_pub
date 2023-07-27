#!/bin/bash

# create folder with current date
folder=$(date +%m-%d)

# check if folder already exists
if [ -d "$folder" ]; then
    echo "$folder folder already exists"
    echo "Script completed successfully"
    exit 0
fi

mkdir "$folder" || { echo "Failed to create folder"; exit 1; }

# enter the folder
cd "$folder" || { echo "Failed to enter folder"; exit 1; }

# download package with current date
package_url="http://release.xsky.com/NeutonOS/dev/NeutonOS_3.0.000.0.$(date +%y%m%d)/NeutonOS-installer-NeutonOS_3.0.000.0.$(date +%y%m%d)-x86_64-neutonos8.6.tar"
wget "$package_url" || { echo "Failed to download package"; exit 1; }

# download sha256sum.txt
sha256sum_url="http://release.xsky.com/NeutonOS/dev/NeutonOS_3.0.000.0.$(date +%y%m%d)/sha256sum.txt"
wget "$sha256sum_url" || { echo "Failed to download sha256sum.txt"; exit 1; }

# extract package
tar -xvf "NeutonOS-installer-NeutonOS_3.0.000.0.$(date +%y%m%d)-x86_64-neutonos8.6.tar" || { echo "Failed to extract package"; exit 1; }

# verify package sha value
package="NeutonOS-installer-NeutonOS_3.0.000.0.$(date +%y%m%d)-x86_64-neutonos8.6.tar"
sha_value=$(sha256sum "$package" | awk '{print $1}')
matching_line=$(grep "$sha_value" sha256sum.txt | grep "$package")
if [ -n "$matching_line" ]; then
    echo "校验通过: $matching_line"
else
    echo "校验失败"
    exit 1
fi

# exit folder
cd .. || { echo "Failed to exit folder"; exit 1; }

echo "Script completed successfully"