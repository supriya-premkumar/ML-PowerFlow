# Install Influxdb
wget https://dl.influxdata.com/influxdb/releases/influxdb_1.5.3_amd64.deb
sudo dpkg -i influxdb_1.5.3_amd64.deb


# INstalling Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
# sudo systemctl status docker

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
##################

# ipython
# from IPython.lib import passwd
# passwd()
##################
# Record the password hash
# exit

jupyter notebook --generate-config
# vim ~/.jupyter/jupyter_notebook_config.py
# Paste the following text at the end of the file. You will need to provide your password hash
# c = get_config()  # Get the config object.
# c.NotebookApp.certfile = u'/home/ubuntu/ssl/cert.pem' # path to the certificate we generated
# c.NotebookApp.keyfile = u'/home/ubuntu/ssl/cert.key' # path to the certificate key we generated
# c.NotebookApp.ip = '*'  # Serve notebooks locally.
# c.NotebookApp.open_browser = False  # Do not open a browser window by default when using notebooks.
# c.NotebookApp.password = <'sha1:fc216:3a35a98ed980b9...'>
#
jupyter notebook
