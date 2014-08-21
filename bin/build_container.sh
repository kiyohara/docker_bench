#!/bin/bash

BASE_DIR=containers

for i in `ls -1 $BASE_DIR`; do
  CONTAINER_NAME=`basename $i`

  echo --------------------------------------------------
  echo "-> $CONTAINER_NAME build start `date`"
  echo --------------------------------------------------

  docker build -t $CONTAINER_NAME $BASE_DIR/$i

  echo --------------------------------------------------
  echo "<- $CONTAINER_NAME build finish `date`"
  echo --------------------------------------------------
done
