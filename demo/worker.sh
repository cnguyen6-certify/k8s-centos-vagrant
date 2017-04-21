#!/bin/bash

echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
setenforce 0
