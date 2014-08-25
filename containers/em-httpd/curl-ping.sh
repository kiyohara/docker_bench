#!/bin/bash

while true; do
  DATE=`date +%Y%m%d%H%M%S.%N`
  curl -X POST -d "{\"date\": $DATE }" 127.0.0.1:8888
  sleep 1
done
