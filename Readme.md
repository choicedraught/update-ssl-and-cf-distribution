# Update SSL and Cloudfront Distrution
Upload LetsEncrypt Certificates generated locally to AWS Certificate Manager and update a Cloudfront Distribution to use the new Certificate.

## Usage
./update-ssl-and-cf-distribution.sh [Wildcard Name eg etse.me] [Cloudfront Distribtion ID]

## Requirements
Code uses the AWS CLI (v1) so ensure your `~/.aws/credentials` has an Access Key and Secret that are authorised to your ACM and CF.