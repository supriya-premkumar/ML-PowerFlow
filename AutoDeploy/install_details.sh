# Install Influxdb
set -xe
wget https://dl.influxdata.com/influxdb/releases/influxdb_1.5.3_amd64.deb
sudo dpkg -i influxdb_1.5.3_amd64.deb


# Installing Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
# sudo systemctl status docker

#Install Screen
sudo apt-get install -y screen

# Install Jupyter notebook
sudo apt-get update
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
cat /home/ubuntu/cfg.tmpl >> /home/ubuntu/.jupyter/jupyter_notebook_config.py
cd -
screen -S jupyter_notebook -d -m  bash -c 'jupyter notebook'
