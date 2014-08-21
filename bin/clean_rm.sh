#!/bin/bash

echo --------------------------------------------------
echo "-> cleanup docker ps start `date`"
echo --------------------------------------------------

for i in `docker ps -aq`; do
  running=`docker inspect --format='{{.State.Running}}' $i`
  kill_flg=''
  if [ $running = 'true' ]; then
    kill_flg='k/'
    docker kill $i > /dev/null
    docker inspect $i > /dev/null
  fi

  printf "%.4s[%srm]  " `docker rm $i` $kill_flg
done
printf "\n"

echo --------------------------------------------------
echo "<- cleanup docker ps finish `date`"
echo --------------------------------------------------
