#!/usr/bin/env bash

docker run -ti -p 4000:4000 -v $(pwd):/srv/jekyll jekyll/jekyll:3 jekyll serve