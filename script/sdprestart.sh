#!/bin/bash
# Change the path below to match the path to the SDP-server
cd /home/bblite/SDP-server/bin;
./shutdown.sh
output=$(ps aux | grep S[D]P-server)
set -- $output
kill -15 $2
sleep 10
output=$(ps aux | grep S[D]P-server)
set -- $output
kill -9 $2
sleep 10
# Change the path below to match the path to the SDP-server
cd /home/bblite/SDP-server/bin; 
./startup.sh
