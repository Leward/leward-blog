#!/usr/bin/env bash
jekyll build
docker image build -t leward/blog .
docker image push leward/blog:latest