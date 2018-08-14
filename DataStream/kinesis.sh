#!/usr/bin/env bash
set -x
<<<<<<< HEAD

STREAM_NAME="ML-PowerFlow-stream"
SHARD_ITERATOR=$(aws kinesis get-shard-iterator --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --stream-name "$STREAM_NAME" --query 'ShardIterator')

aws kinesis get-records --shard-iterator $SHARD_ITERATOR
function create_stream()
{
  aws kinesis create-stream --stream-name "$STREAM_NAME" --shard-count 1
  aws kinesis describe-stream --stream-name "$STREAM_NAME"
}


# create_stream #call only once
function get_objects_from_s3()
{
  aws kinesis put-record --stream-name "$STREAM_NAME" --partition-key 123 --data '{"city": "Sonoma", "zip": "95476", "state": "California", "country": "United States", "energy": 1.345533, "stationID": "37163", "sessionID": "9798123", "intervals": [{"energyConsumed": 0.133237, "rollingPowerAvg": 3.0551, "stationTime": "2013-01-01T01:27:23+00:00", "peakPower": 3.7186}, {"energyConsumed": 1.057105, "rollingPowerAvg": 3.6955, "stationTime": "2013-01-01T01:30:00+00:00", "peakPower": 3.7174}, {"energyConsumed": 1.345533, "rollingPowerAvg": 3.7621, "stationTime": "2013-01-01T01:45:00+00:00", "peakPower": 3.7101}], "startTime": "2013-01-01T01:27:23+00:00", "endTime": "2013-01-01T01:49:36+00:00"}'
}

get_objects_from_s3

function read_stream()
{
  aws kinesis get-shard-iterator --shard-id "$SHARD_ITERATOR" --shard-iterator-type TRIM_HORIZON --stream-name "$STREAM_NAME"
}

read_stream

function delete_stream()
{
  aws kinesis delete-stream --stream-name "$STREAM_NAME"
  aws kinesis describe-stream --stream-name "$STREAM_NAME" #check_progress

}
=======
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
>>>>>>> c70b5bd9b5437a869880c90ef3f7661daef2e84c
