#!/bin/bash

###################
# Author: Olatayo Adewuyi
# Date: 25th Dec, 2025
#
# Version: v1
#
# AWS Resource Inventory Script
###################

#Set Safe Environment
set -euo pipefail

#Define Absolute Paths (cron does not inherit PATH)
AWS=/usr/bin/aws
DATE=/bin/date
JQ=/usr/bin/jq
COLUMN=/usr/bin/column

# Directory where EC2 reports will be stored
OUTPUT_DIR=/var/log/ec2-reports

# AWS region to query resources from
REGION="eu-north-1"

mkdir -p "$OUTPUT_DIR"

# Timestamp to ensure reports are not overwritten
TIMESTAMP=$($DATE +"%Y-%m-%d_%H-%M-%S")

#EC2 report output file
OUTPUT_FILE="$OUTPUT_DIR/ec2_instances_$TIMESTAMP.txt"

echo "Print list of S3 buckets"
$AWS s3 ls --region "$REGION"

echo "Print list of EC2 instances"
$AWS ec2 describe-instances --region "$REGION" \
| $JQ -r '
  ["InstanceId","State","InstanceType","PrivateIP"],
  (.Reservations[].Instances[] |
    [.InstanceId, .State.Name, .InstanceType, .PrivateIpAddress]
  )
  | @tsv
' | $COLUMN -t > "$OUTPUT_FILE"

echo "Print list of Lambda functions"
$AWS lambda list-functions --region "$REGION"

echo "Print list of IAM users"
$AWS iam list-users

echo "EC2 Instance report generated at $OUTPUT_FILE"

cat $OUTPUT_FILE
