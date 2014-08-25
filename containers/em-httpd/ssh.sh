ssh \
  -o StrictHostKeychecking=no \
  -i ./id_rsa \
  docker@$(docker inspect `docker ps -ql` | jq .[0].NetworkSettings.IPAddress | xargs echo)
