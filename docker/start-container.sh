#!/bin/bash

docker run --rm -d \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  --env SSH_AUTH_SOCK=/ssh-agent \
  -p 4567:4567 \
  -v ~/workspace:/home/pivotal/workspace $@ \
  --cap-add NET_ADMIN --device /dev/net/tun \
  --name docker-workspace \
  --hostname work-machine \
  -u root \
  exie/networking-workspace
