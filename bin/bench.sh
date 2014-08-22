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

_ps() {
  local pid=${1:-''}

  if [ $pid ];then
    if [ $pid -gt 0 ]; then
      ps -p $pid uw
      return 0
    else
      # echo invalid pid($pid)
      return 1
    fi
  else
    # echo pid required
    return 1
  fi
}

print_state() {
  local container_num=${1:-0}
  local container_hash=${2:-''}

  echo
  echo "----- mpstat ----->"
  mpstat
  echo "----- mpstat -----<"

  echo
  echo "----- vmstat ----->"
  vmstat
  echo "----- vmstat -----<"

  [ $DOCKER_IO_PID ] || DOCKER_IO_PID=`pgrep docker | head -1`
  echo
  echo "----- ps docker.io daemon ----->"
  _ps $DOCKER_IO_PID || echo "WARN: invalid pid($DOCKER_IO_PID) ... docker.io quit?"
  echo "----- ps docker.io daemon -----<"

  if [ $container_hash ];then
    echo
    echo "----- docker logs tail ----->"
    docker logs $container_hash | tail
    echo "----- docker logs tail -----<"

    local container_pid=`docker inspect $container_hash | jq .[0].State.Pid`

    echo
    echo "----- ps container process ----->"
    _ps $container_pid || echo "WARN: invalid pid($container_pid) ... container quit?"
    echo "----- ps container process ----->"
  fi
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
DOCKER_RUN_PARAMS=${DOCKER_RUN_PARAMS:-'-d'}

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
  (time docker run $DOCKER_RUN_PARAMS $CONTAINER_NAME $CONTAINER_RUN_CMD > /dev/null) 2>&1
  echo "----- time docker run -----<"

  container_hash=`docker ps -lq`

  print_state $i $container_hash
  print_state_detail $i $container_hash

  echo
  echo "===== run docker container #$i =====<"
done
rm $WORK_FILE

echo
echo --------------------------------------------------
echo "<- $SUB_TEST_DIR bench finish `date`"
echo --------------------------------------------------
