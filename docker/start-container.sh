#!/bin/bash

docker run --rm -d \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  --env SSH_AUTH_SOCK=/ssh-agent \
  -p 4567:4567 \
  -p 4568:4568 \
  -v ~/workspace:/home/pivotal/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock $@ \
  --cap-add NET_ADMIN --device /dev/net/tun \
  --name docker-workspace \
  --hostname work-machine \
  -u root \
  exie/networking-workspace
