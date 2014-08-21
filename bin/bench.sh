#!/bin/bash

if [ ! -d "$1" ];then
  echo !! sub_test_dir required ... stop !!
  exit 1
fi

SUB_TEST_DIR=$1
source $SUB_TEST_DIR/vars.sh

if [ ! $CONTAINER_NAME ];then
  echo !! CONTAINER_NAME required ... stop !!
  exit 1
fi

################################################################################

print_state() {
  echo
  echo "----- mpstat ----->"
  mpstat
  echo "----- mpstat -----<"

  echo
  echo "----- vmstat ----->"
  vmstat
  echo "----- vmstat -----<"

  echo
  echo "----- ps docker.io daemon ----->"
  ps auxw | grep '/usr/bin/docker -d' | grep -v grep
  echo "----- ps docker.io daemon -----<"
}

print_state_detail() {
  local container_num=${1:-0}

  if [ $container_num -gt 0 ];then
    echo
    echo "----- vmstat : detail ----->"
    echo "----- used all cont, befre bench free, crr free, used per cont -----"
    local mem_free_start=${MEM_FREE_START:-0}
    local mem_free_crr=`vmstat | tail -1 | awk '{ print $4}'`
    local mem_used_all_cont=`expr $mem_free_start - $mem_free_crr`
    local mem_used_per_cont=`expr $mem_used_all_cont / $container_num`
    printf "%'16d / %'16d / %'16d / %'16d\n" \
      $mem_used_all_cont $mem_free_start $mem_free_crr $mem_used_per_cont
    echo "----- vmstat : detail -----<"
  fi

  echo
  echo "----- ps docker.io daemon : detail ----->"
  echo "----- VSZ, RSS -----"
  ps auxw | grep '/usr/bin/docker -d' | grep -v grep \
    | awk '{ printf("%\04716d / %\04716d\n", $5, $6) }'
  echo "----- ps docker.io daemon : detail -----<"
}

################################################################################

echo --------------------------------------------------
echo "-> $SUB_TEST_DIR bench start `date`"
echo "   docker container: $CONTAINER_NAME"
echo --------------------------------------------------

PROG_NAME=`basename $0`
WORK_FILE=`mktemp /tmp/$PROG_NAME.XXXXXXXX`

CONTAINER_COUNT=${CONTAINER_COUNT:-1}
DOCKER_RUN_PARAMS=${DOCKER_RUN_PARAMS:-''}

trap "echo !! trap signal !!; rm $WORK_FILE; exit" SIGHUP SIGINT SIGTERM

MEM_FREE_START=`vmstat | tail -1 | awk '{ print $4}'`

echo "===== zero docker container =====>"
print_state
print_state_detail
echo "===== zero docker container =====<"

for i in `seq 1 $CONTAINER_COUNT`;do
  [ ! -e $WORK_FILE ] && break

  echo
  echo "===== run docker container #$i =====>"

  echo
  echo "----- time docker run ----->"
  (time docker run -d $DOCKER_RUN_PARAMS $CONTAINER_NAME > /dev/null) 2>&1
  echo "----- time docker run -----<"

  container_id=`docker ps -lq`

  echo
  echo "----- docker logs tail ----->"
  docker logs $container_id | tail
  echo "----- docker logs tail -----<"

  print_state $i
  print_state_detail $i

  echo
  echo "===== run docker container #$i =====<"
done
rm $WORK_FILE

echo
echo --------------------------------------------------
echo "<- $SUB_TEST_DIR bench finish `date`"
echo --------------------------------------------------
