#!/bin/bash

lpass show --notes 'Shared-CF-Networking (Pivotal)/concourse_toolsmiths_api_key' | cut -d= -f2
