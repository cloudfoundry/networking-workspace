#!/bin/bash

docker run --rm -d \
  -v ~/workspace:/home/pivotal/workspace $@ \
  --name docker-workspace \
  -u root \
  exie/networking-workspace

