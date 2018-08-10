#!/usr/bin/env bash
set -x

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
