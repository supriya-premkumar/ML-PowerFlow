#!/usr/bin/env bash
set -xe
MAX_RETRIES=10
if [ "$#" -lt 1 ]; then
	echo "Script to create AWS Instances for VADER"
	echo "Usage: $0 <instance count> [create-key]"
  echo "Also please run aws configure prior to running this script"
	exit 1
fi

########### Global Constants ##################
INSTANCE_COUNT=$1
CREATE_KEY=$2
echo $INSTANCE_COUNT
echo $CREATE_KEY

set -u

IMAGE_ID="ami-db710fa3" #us-west-1 (Amazon Linux AMI- N.California)
SG_ID="sg-ee4f3b96"
SG_NAME="launch-wizard-12"
REGION="us-west-2"
INSTANCE_TYPE="t2.micro"
PREFIX="VADER-PowerFlow"
ADMIN_USER="ubuntu"
KEY=PowerFlow-Key
KEY_PATH=powerflow-creds-us-west-2

############ Default Helper Commands ##############
ssh_cmd="ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"
scp_cmd="scp -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"

############Adding rules to security group ###########
aws_add_port_cmd="aws --region $REGION ec2 authorize-security-group-ingress --group-name $SG_NAME"

## create_key generates a new aws key pair to use to log in to the instance
function create_key()
{
  KEY=$1
  KEY_PATH=$2
	mkdir -p $KEY_PATH
	aws ec2 delete-key-pair --key-name $KEY || true
  aws ec2 create-key-pair --key-name $KEY --query 'KeyMaterial' --output text > $KEY_PATH/$KEY.pem
  chmod 400 $KEY_PATH/$KEY.pem
}

############ Create Key. This is expected to be run only once ################
if [ "$CREATE_KEY" = "create_key" ]; then
	create_key $KEY $KEY_PATH
fi

# is_sshd_up checks if the remote instance ssh server is up.
# It will retry MAX_RETRIES number of times before it quits
function is_sshd_up()
{
	set +e
	IP=$1
	ID_FILE=$2
	count=MAX_RETRIES
	$ssh_cmd -i $ID_FILE $ADMIN_USER@$IP exit
	SSH_STATUS=$?
	until [ "$SSH_STATUS" = 0 -o count = 0 ]
	do
		echo "Checking is ssh daemon is up..."
		$ssh_cmd -i $ID_FILE $ADMIN_USER@$IP 'whoami'
		SSH_STATUS=$?
		let "count--"
	 sleep 5
	done
	set -e
}

# create_security_group creates the security group required for the powerflow stack
# currently we are using a hardcoded security group in us-west-2.
# ToDo move away from hardcoded security groups and autogenerate this based on the stack
function create_security_group()
{
	echo "************ Creating Security Group ******************"
	set +e
	sg_vader=$(aws --region $REGION --output json ec2 create-security-group --group-name $SG_NAME --description "VADER-DATA-GridLabD Security Group" | jq .GroupId | sed s_'"'__g)
	$aws_add_port_cmd --protocol tcp --port 22 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 80 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 6267 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 8091 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 8090 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 3306 --cidr 0.0.0.0/0
	$aws_add_port_cmd --protocol tcp --port 443 --cidr 0.0.0.0/0
	return $sg_vader

}

 # $(create_security_group)

# deploy_instances creates aws instances and installs ml powerflow stack
function deploy_instances()
{
	echo "################## Instance Details ##################" > result.out
  for i in `seq 1 $INSTANCE_COUNT`;
	do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --security-group-ids $SG_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY  --query 'Instances[0].InstanceId' | sed s_'"'__g)
    INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' | sed s_'"'__g)

    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PREFIX-$i
    echo "################### WRITING ARTIFACTS ########################"
    echo $INSTANCE_IP > $KEY_PATH/instance-ip-$i
    sleep 30
		is_sshd_up $INSTANCE_IP "$KEY_PATH/$KEY.pem"
		generate_pw_hash $i
		$scp_cmd -i $KEY_PATH/$KEY.pem cfg.append $ADMIN_USER@$INSTANCE_IP:~/cfg.tmpl
    $scp_cmd -i $KEY_PATH/$KEY.pem install_details.sh $ADMIN_USER@$INSTANCE_IP:~/
    $ssh_cmd -i $KEY_PATH/$KEY.pem $ADMIN_USER@$INSTANCE_IP 'bash  ~/install_details.sh'
		echo "################## Instance $i:" >> result.out
		echo "Login Page: https://$INSTANCE_IP:8888" >> result.out
		echo "Password File: $KEY_PATH/passwd-$i.txt" >> result.out
	done
	cat result.out
}

# generate_pw_hash uses iPython and urandom to first generate a random Password
# and run SHA1 hashing algorithm on it. It uses the template file to
# append the generated SHA1 to jupyter_config.py. This will enable user
# to directly login with the password and not have to manage password on his own.
function generate_pw_hash()
{
	prefix=$1
	export LC_CTYPE=C
	export NOTEBOOK_PASSWD=$(cat /dev/urandom  |  tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo $NOTEBOOK_PASSWD>$KEY_PATH/passwd-$prefix.txt
	python gen_hash.py $KEY_PATH $prefix
	cp cfg.tmpl cfg.append
	SHA_SUM=$(cat $KEY_PATH/passwd_hash-$prefix.txt)
	sed -i '' -e "s/PASSWD_SHA/$SHA_SUM/g" cfg.append
	rm $KEY_PATH/passwd_hash-$prefix.txt
}

deploy_instances
