#!/usr/bin/env bash
set -xe
MAX_RETRIES=10

# Pre flight checks
if [ -z $AWS_SECRET_ACCESS_KEY ]; then
	echo "Could not find AWS_SECRET_ACCESS_KEY in the environment."
  echo "Please run export AWS_SECRET_ACCESS_KEY=<aws secret key>"
	exit 1
fi

if [ -z $AWS_ACCESS_KEY_ID ]; then
	echo "Could not find AWS_ACCESS_KEY_ID in the environment."
  echo "Please run export AWS_ACCESS_KEY_ID=<aws secret key>"
	exit 1
fi

########### Global Constants ##################
# INSTANCE_COUNT=$1
# CREATE_KEY=$1
# echo $INSTANCE_COUNT
# echo $CREATE_KEY

set -u
source templates/config
KEY_NAME="Instance-Key"
KEY_PATH=.creds/creds-$REGION
KEY_FILE="$KEY_PATH/$KEY_NAME.pem"

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


if [ ! -f $KEY_FILE ]; then
  # Create key only if the key file doesn't exist
  create_key $KEY_NAME $KEY_PATH
fi


############ Default Helper Commands ##############
ssh_cmd="ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"
scp_cmd="scp -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"

############Adding rules to security group ###########
aws_add_port_cmd="aws --region $REGION ec2 authorize-security-group-ingress --group-name $SG_NAME"

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

function deploy_db_instance()
{
	PREFIX="VADER-DB-TEST"
	echo "################## Instance Details ##################" > templates/result.out
	# for i in `seq 1 $INSTANCE_COUNT`;
	# do
		INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --security-group-ids $SG_ID --count 1 --instance-type $INSTANCE_TYPE --key-name "$KEY_NAME"  --query 'Instances[0].InstanceId' | sed s_'"'__g)
		INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' | sed s_'"'__g)

		aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PREFIX
		echo "################### WRITING ARTIFACTS ########################"
		echo $INSTANCE_IP > $KEY_PATH/instance-ip
    DB_NODE_IP=$INSTANCE_IP
		sleep 30
		is_sshd_up $INSTANCE_IP "$KEY_PATH/$KEY_NAME.pem"
		$ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'wget https://dl.influxdata.com/influxdb/releases/influxdb_1.5.3_amd64.deb && sudo dpkg -i influxdb_1.5.3_amd64.deb && sudo service influxdb start '

}

# deploy_instances creates aws instances and installs ml powerflow stack
function deploy_instances()
{
	PREFIX="VADER-APP-TEST"
	echo "################## Instance Details ##################" > templates/result.out
  # for i in `seq 1 $INSTANCE_COUNT`;
	# do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --security-group-ids $SG_ID --count 1 --instance-type $INSTANCE_TYPE --key-name "$KEY_NAME"  --query 'Instances[0].InstanceId' | sed s_'"'__g)
    INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' | sed s_'"'__g)

    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PREFIX
    echo "################### WRITING ARTIFACTS ########################"
    echo $INSTANCE_IP > $KEY_PATH/instance-ip
    APP_NODE_IP=$INSTANCE_IP
    sleep 30
		is_sshd_up $INSTANCE_IP "$KEY_PATH/$KEY_NAME.pem"

		# $scp_cmd -i $KEY_PATH/$KEY.pem templates/cfg.append $ADMIN_USER@$INSTANCE_IP:~/cfg.tmpl
    # $scp_cmd -i $KEY_PATH/$KEY.pem templates/install_details.sh $ADMIN_USER@$INSTANCE_IP:~/
		$ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone https://github.com/supriya-premkumar/ML-PowerFlow'
		$ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'cd ML-PowerFlow && git checkout containerize-auto-deploy'
		$ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'bash ~/ML-PowerFlow/Infra/templates/generate_pw_hash.sh'
    $ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'bash  ~/ML-PowerFlow/Infra/templates/install_details.sh'
    JUPYTER_PASSWD=$($ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" $ADMIN_USER@$INSTANCE_IP 'cat ~/jupyter_notebook_pass/passwd.txt')
		# $scp_cmd -i $KEY_PATH/$KEY.pem -r DataStream $ADMIN_USER@$INSTANCE_IP:~/
		echo "################## Instance Deatils:" >> templates/result.out
		echo "Login Page: https://$INSTANCE_IP:8888" >> templates/result.out
		echo "Password: $JUPYTER_PASSWD" >> templates/result.out
	# done
	cat templates/result.out
}

function bringup_svcs()
{
	# Run the ssh command with -t as we need the local
  $ssh_cmd -i "$KEY_PATH/$KEY_NAME.pem" -tt $ADMIN_USER@$APP_NODE_IP 'bash -l -c export PATH=$PATH:~/ML-PowerFlow/App/DataStream && bash -l -c ls && export AWS_ACCESS_KEY_ID='"'$AWS_ACCESS_KEY_ID'"' && export DB_ENDPOINT='"'$DB_NODE_IP'"' && export AWS_SECRET_ACCESS_KEY='"'$AWS_SECRET_ACCESS_KEY'"' && ~/ML-PowerFlow/App/DataStream/kinesis.sh vader.data.chargepoint us-west-1'
}


deploy_db_instance
deploy_instances
bringup_svcs
