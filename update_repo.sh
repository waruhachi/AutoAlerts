#!/bin/sh
rm -rf packages/*
export FINALPACKAGE=1
make clean package
# ssh mostm@denver.lan "rm -rf /home/mostm/projects/repo/data/secure/debs/com.shiftcmdk.autoalerts_*"
scp packages/* mostm@denver.lan:/home/mostm/projects/repo/data/secure/debs/
ssh mostm@denver.lan "bash /home/mostm/projects/repo/data/secure/updaterepo.sh"