#!/bin/bash

echo --------------------------------------------------
echo "-> docker.io restarting start `date`"
echo --------------------------------------------------

sudo service docker restart

echo --------------------------------------------------
echo "<- docker.io restarting finish `date`"
echo --------------------------------------------------

