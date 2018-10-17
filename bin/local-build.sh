#!/usr/bin/env bash

BASE_DIR=$(realpath $(dirname $0)/..)
DOCKER_USER=lets
IMAGE=docker-heroku-ruby-local
LOCAL_IMAGE=$DOCKER_USER/$IMAGE:latest

cd $BASE_DIR \
  && docker build --rm -t $LOCAL_IMAGE . \
  && echo -e "\nGenerated local image: ${LOCAL_IMAGE}"
