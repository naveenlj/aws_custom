#!/bin/bash
# Script will install aws cli tools and prompt for aws keys
# For Redhat distribution only

set -x

if [ "$(id -u)" != "0" ]; then
 echo "This script must be run as root" 1>&2
 exit 1
fi

which curl >/dev/null 2>&1
if  [ $? != 0 ]; then
  yum install curl >/dev/null 2>&1
fi

which unzip >/dev/null 2>&1
if  [ $? != 0 ]; then
  yum install uzip >/dev/null 2>&1
fi

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"

unzip awscli-bundle.zip

sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

echo " Add AWS access key and secret key"

aws configure

echo " Finished installing aws cli "
