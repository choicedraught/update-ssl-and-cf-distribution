#!/bin/bash

# Check that freenas2.mgmt.etse.me/mnt/milpool/Storage/Certificates is available
export AWS_PAGER="" # Fixes the cli output issue
WILDCARD=$1
CF_DISTRIBUTION=$2
PATH="/Volumes/Storage/Certificates"
REGION='us-east-1'
USAGE=$0' [Domain Name] [Cloudfront Distribution ID]' 

if [ ! -d $PATH ] 
then
    echo "Certificate Share not mounted: $PATH"
    exit 1
fi

if [ -z "$WILDCARD" ] || [ -z "$CF_DISTRIBUTION" ]
then
    echo "Error: No domain supplied for Wildcard Certificate or no Cloudflare Distribution ID specified"
    echo $USAGE
    exit 1
fi

/usr/bin/openssl x509 -in $PATH/$WILDCARD/$WILDCARD.cer -out /tmp/$WILDCARD.pem
/usr/bin/openssl x509 -in $PATH/$WILDCARD/fullchain.cer -out /tmp/fullchain.pem
/usr/bin/openssl rsa -in $PATH/$WILDCARD/$WILDCARD.key -out /tmp/privatekey.pem 2>/dev/null

/opt/homebrew/bin/aws acm import-certificate --certificate  fileb:///tmp/$WILDCARD.pem --certificate-chain fileb:///tmp/fullchain.pem --private-key fileb:///tmp/privatekey.pem --region $REGION --output json 1>/tmp/cert-arn.txt

CERTIFICATE_ARN=`/bin/cat /tmp/cert-arn.txt | /opt/homebrew/bin/jq '.CertificateArn'`

echo "Configuring $CF_DISTRIBUTION with SSL Certificate $CERTIFICATE_ARN"

# Cleanup Cert conversion
/bin/rm /tmp/$WILDCARD.pem
/bin/rm /tmp/fullchain.pem
/bin/rm /tmp/privatekey.pem

# Now implement : https://dev.to/csaltos/update-an-aws-cloudfront-custom-ssl-tls-certificate-using-aws-cli-4n1o

# Here the trick: load the current configuration to patch it on the fly (AWS has no other option currently)
/opt/homebrew/bin/aws cloudfront get-distribution-config --id $CF_DISTRIBUTION --query DistributionConfig > /tmp/config.json

# echo ${CERTIFICATE_ARN//\//\\/} # this magic escaptes the "/" in the Arn

/usr/bin/sed -i.bak "s/.*\"ACMCertificateArn\".*/\"ACMCertificateArn\": \"${CERTIFICATE_ARN//\//\\/}\",/g" /tmp/config.json
/usr/bin/sed -i.bak "s/.*\"Certificate\".*/\"Certificate\": \"${CERTIFICATE_ARN//\//\\/}\",/g" /tmp/config.json

/opt/homebrew/bin/aws cloudfront update-distribution --id $CF_DISTRIBUTION --dist

# Cleanup
/bin/rm /tmp/cert-arn.txt
/bin/rm /tmp/config.json
