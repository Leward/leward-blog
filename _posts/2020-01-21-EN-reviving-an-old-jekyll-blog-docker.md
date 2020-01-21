---
layout:     post
title:      "Reviving an old Jekyll Blog thanks to Docker"
slug:       reviving-an-old-jekyll-blog-docker
date:       2020-01-21 11:49:00 +0800
categories:
lang:       en
ref:        reviving-an-old-jekyll-blog-docker
excerpt_separator: <!--more-->
---

I don't know if I have any regular reader. Yet, I know I am not a regular writer and only publish to this blog from time to time.

I recently tried to publish an article about Java modules. I had difficulties rebuilding the blog using the `jekyll build` command. Quite some time has passed since my last publication and Jekyll had a few breaking changes.

<!--more-->

I could have installed an older version of Jekyll on my system. I find this option quite troublesome. In the end, I decided to use Docker. It allows to "simply" use an old version of Jekyll no matter what I have installed on my local system (besides Docker).

    # Run
    docker run -ti \
    	-p 4000:4000 \
    	-v $(pwd):/srv/jekyll \
    	jekyll/jekyll:3 jekyll serve
    
    # Build
    docker run -ti \
    	-v $(pwd):/srv/jekyll \
    	jekyll/jekyll:3 jekyll build

It's not as simple as `jekyll run` or `jekyll build`. However it is more reproducible. Conveniently hidden in a `[run.sh](http://run.sh)` and `[build.sh](http://build.sh)` scripts, it becomes painless to use them.