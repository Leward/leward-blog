#!/usr/bin/env bash

docker run -ti -v $(pwd):/srv/jekyll jekyll/jekyll:3 jekyll serve