#!/usr/bin/env bash
docker run -ti -v $(pwd):/srv/jekyll jekyll/jekyll:4 jekyll build
cp -r _site/* docs/