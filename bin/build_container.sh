#!/bin/bash

if [ ! -d "$1" ];then
  echo !! container_dir required ... stop !!
  exit 1
fi

DIR=$1
source $DIR/vars.sh

if [ ! $CONTAINER_NAME ];then
  echo !! CONTAINER_NAME required ... stop !!
  exit 1
fi

docker build -t $CONTAINER_NAME $DIR
