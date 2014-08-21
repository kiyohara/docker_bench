#!/bin/bash

echo --------------------------------------------------
echo "-> cleanup dangling docker images start `date`"
echo --------------------------------------------------

for i in `docker images -q -f dangling=true`; do
  docker rmi $i
done

echo --------------------------------------------------
echo "<- cleanup dangling docker images start `date`"
echo --------------------------------------------------

