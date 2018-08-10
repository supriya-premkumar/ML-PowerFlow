#!/usr/bin/env bash
set -xe
KEY_PATH="jupyter_notebook_pass"
mkdir -p $KEY_PATH

sudo apt-get install -y python
sudo apt-get update
sudo apt-get install -y python-pip
sudo apt-get install -y ipython

function generate_pw_hash()
{
	prefix=$1
	export LC_CTYPE=C
	export NOTEBOOK_PASSWD=$(cat /dev/urandom  |  tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo $NOTEBOOK_PASSWD>$KEY_PATH/passwd.txt
	python ~/ML-PowerFlow/Infra/templates/gen_hash.py $KEY_PATH
	SHA_SUM=$(cat $KEY_PATH/passwd_hash.txt)
  echo $SHA_SUM
	sed -i "s/PASSWD_SHA/$SHA_SUM/g" ~/ML-PowerFlow/Infra/templates/cfg.tmpl 
	rm $KEY_PATH/passwd_hash.txt
}

generate_pw_hash 4
