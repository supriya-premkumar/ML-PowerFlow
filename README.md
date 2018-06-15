# ML-PowerFlow
## Description:
This auto deploys ML Powerflow stack on AWS using a single script

## Prerequisites
1. configured aws cli.
```
$ aws configure
AWS Access Key ID [None]: <Your AWS Access Key>
AWS Secret Access Key [None]: <Your AWS Secret Access Key>
Default region name [None]: us-west-2
Default output format [None]: json
```
[more details](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

2. iPython installed on the machine that runs the script.
```
pip install ipython
```
[instructions here](https://ipython.org/install.html)

## How to use
`bash auto-deploy.sh <instance count> [create-key]`
```
instance count: specifies how many instances we need to spin up
create-key: optional parameter which will ensure that new ssh keys are generated to access the machine
```

## Instance Details
All the instance details like IP, key to ssh into the machine and the password to log in to jupyter hub notebook lives in a powerflow-creds-us-west-2


## DataIngestion to Influxdb from csv files
1. `DataIngestion.py` ingests 8 bus csv data to Influxdb
2.  Required arguments: `host` and `port`
