#!/usr/bin/env bash

docker run -ti -p 4000:4000 -v $(pwd):/srv/jekyll jekyll/jekyll:4 jekyll serve