#!/bin/bash

echo "--> rmi dangling docker images"
for i in `docker images -q -f dangling=true`; do
  docker rmi $i
done
