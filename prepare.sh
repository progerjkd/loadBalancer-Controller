#!/bin/bash

echo "" > /etc/udev/rules.d/70-persistent-net.rules
echo "" > /lib/udev/rules.d/75-persistent-net-generator.rules

rm  /etc/ssh/ssh_host_*

