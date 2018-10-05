#!/usr/bin/env bash

$aws_add_port_cmd --protocol tcp --port 22 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 80 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 6267 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 8091 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 8090 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 3306 --cidr 0.0.0.0/0
$aws_add_port_cmd --protocol tcp --port 443 --cidr 0.0.0.0/0
