#!/bin/bash

LOCAL_SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
CONTAINER_SSH_AUTH_SOCK=/ssh-agent

# support ssh agent forwarding on mac, see https://github.com/docker/for-mac/issues/410
# it has to be this particular magic string, even in the container, nothing else works
if [ "$(uname)" == "Darwin" ]; then
  LOCAL_SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
  CONTAINER_SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
fi

docker run --rm -d \
  -v $LOCAL_SSH_AUTH_SOCK:$CONTAINER_SSH_AUTH_SOCK \
  --env SSH_SSH_AUTH_SOCK=$CONTAINER_SSH_AUTH_SOCK \
  -p 4567:4567 \
  -p 4568:4568 \
  -v ~/workspace:/home/pivotal/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock $@ \
  --cap-add NET_ADMIN --device /dev/net/tun \
  --name docker-workspace \
  --hostname work-machine \
  -u root \
  exie/networking-workspace

# more steps to support ssh agent forwarding on mac: https://github.com/docker/for-mac/issues/410#issuecomment-553323021
if [ "$(uname)" == "Darwin" ]; then
  docker exec -u root docker-workspace /bin/bash -c "chmod 666 $CONTAINER_SSH_AUTH_SOCK"
fi
