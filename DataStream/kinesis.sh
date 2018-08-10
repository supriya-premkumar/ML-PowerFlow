#!/usr/bin/env bash
set -x
if [ "$#" -ne 2 ]; then
    echo "Script to injest EV Data from a s3 bucket into influx DB"
    echo "Usage: $0 <s3 bucket name> <aws region>"
    echo "Also please run aws configure prior to running this script"
    exit 1
fi
S3_BUCKET_NAME=$1
AWS_REGION=$2
STREAM_NAME="ML-PowerFlow-stream"

# Make sure to restart influx DB prior to start
function initialize()
{
  # Bring up influxDB
  sudo service influxdb start
  
  # Copy JSON formatted file from s3 bucket. We assume that the file is named ev_data.json and is a valid JSON file.
  aws s3 cp "s3://$S3_BUCKET_NAME/ev_data.json" .  
}

function stream_producer()
{
  # Impements producer side of the pipe. Loads the valid json file and pushes records to the kinesis stream
  python put-helper.py -s "$STREAM_NAME" -r "$AWS_REGION"
}

function stream_consumer()
{
  # Implements the consumer side of the pipe. Gets the records from the stream and pushes it to influxDB
  # TODO update the properties file with the created stream
  `python ev-properties-runner.py --print_command --java $(which java) --properties ev-consumer.properties`
   
}


function tear_down()
{
  # Delete stream after done to conserve resources
  aws kinesis delete-stream --stream-name "$STREAM_NAME"
}

initialize
stream_producer
stream_consumer
tear_down
