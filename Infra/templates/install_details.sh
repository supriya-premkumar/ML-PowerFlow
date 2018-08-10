# AutoDeploy scripts
# git clone https://github.com/supriya-premkumar/ML-PowerFlow
# cd ML-PowerFlow
git checkout containerize-auto-deploy

set -xe


# Install Influxdb
wget https://dl.influxdata.com/influxdb/releases/influxdb_1.5.3_amd64.deb
sudo dpkg -i influxdb_1.5.3_amd64.deb
sudo service influxdb start


# Installing Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
# sudo systemctl status docker

# Install Pandas
sudo apt-get install -y python-pip
# pip install python-pip
sudo pip install pandas
sudo apt-get install python-pip

# Install cvxopt
sudo pip install cvxopt

# Install Kinesis SDK
sudo pip install amazon_kclpy
git clone https://github.com/awslabs/amazon-kinesis-client-python.git
cd amazon-kinesis-client-python
sudo python setup.py install

# Install influx client
sudo pip install influxdb

# Install aws cli and Configure
pip install awscli

# Install Java 8
sudo apt-get install default-jre -y
sudo apt-get install default-jdk -y

# Update .bashrc to refer to awscli

#Install Kinesis
# sudo pip install virtualenv
# pip install amazon_kclpy
# curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
# sudo apt install unzip
# unzip awscli-bundle.zip
# sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws


#Install Screen
sudo apt-get install -y screen


# Install Jupyter notebook
sudo apt-get -y install python2.7 python-pip python-dev
sudo apt-get -y install ipython ipython-notebook
sudo -H pip install jupyter
sudo -H pip install --upgrade pip
sudo -H pip install jupyter

# Configure the Jupyter Server
cd
mkdir ssl
cd ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout "cert.key" -out "cert.pem" -batch
jupyter notebook --generate-config
cat /home/ubuntu/ML-PowerFlow/Infra/templates/cfg.tmpl >> /home/ubuntu/.jupyter/jupyter_notebook_config.py
cd -
screen -S jupyter_notebook -d -m  bash -c 'jupyter notebook'
