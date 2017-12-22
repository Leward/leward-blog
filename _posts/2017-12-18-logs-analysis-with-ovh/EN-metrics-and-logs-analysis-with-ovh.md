---
layout:     post
title:      "Logs analysis with OVH Logs Data Platform"
slug:       logs-analysis-with-ovh"
date:       2017-12-18 00:40:00 +0800
categories:
lang:       en
ref:        logs-analysis-with-ovh
excerpt_separator: <!--more-->
---

OVH offers a service called “Logs Data Platform” which helps you centralizing and analyzing your logs. 

<!--more-->

I see two main benefits using this service:

1. It's a managed service (SaaS)
2. It's cheap

The offertings starts at 1€ per month for 1GB of logs with one stream of logs and one dashboard. The data retention is of 45 days.

It also allows to setup multiple users and define more fine-grained access rules even though I did not test the feature.

The service allows to interact with your logs using [Graylog](https://www.graylog.org/features) or [Elastisearch](https://www.elastic.co/products/elasticsearch).

So I decided to give a try to store and analyze the the logs of [Inkzone](https://inkzone.games), a website I am currently working on.

<!--more-->

## About Graylog and GELF format

Graylog is a tool that centralize your logs in one place and make in easier to browse and analyze them. 

The more applications you have the more benefits you'll get from this kind of tool. The more you have, the more log files you also have to manage with rotation and retention policy. 

Greylog uses a log format called [GELF (Graylog Extended Lenght Format)](http://docs.graylog.org/en/2.3/pages/gelf.html). GELF differs from other log formats (like [syslog](https://en.wikipedia.org/wiki/Syslog)) by being a structured logging format with custom typed fields. This makes it better suited for indexing and analysis than other non structured formats.

## Send Docker container logs to Graylog

Docker has a native [gelf log driver](https://docs.docker.com/engine/admin/logging/gelf/).
If you use Docker to deploy your applications and print your logs in the standard output to print your logs you can directly send your logs to graylog by changing the log driver of your containers.

In order to proceed you will need to know:
 * The endpoint to collect GELF logs over UDP (`udp://gra2.logs.ovh.com:2202` for me)
  * The token for your stream

Then, run the docker container with the following configuration: 

```
docker run \
  -e X-OVH-TOKEN="7982bbc4-9a66-4426-9de3-33d6eb201ed6" \
  --log-driver gelf \
  --log-opt gelf-address=udp://gra2.logs.ovh.com:2202 \
  --log-opt env=X-OVH-TOKEN \
  -d busybox
```

Replace `7982bbc4-9a66-4426-9de3-33d6eb201ed6` by your actual Stream token.

`--log-opt env=X-OVH-TOKEN` for the gelf log driver will put the specified environment variable as a custom field in the GELF message (prefixed by an underscore `_`). That's how OVH can accept and properly route the incoming logs.

It works, however the main drawback is that the logs will be made from the Docker perspective. The reported log levels are the ones from Docker, not from the java app. Docker will only consider for log levels the standard and error outputs, so you will note have the same granulary as the java logs (DEBUG, INFO, WARN, ERROR, etc.) without doing intermediate processing. 

If you want richer logs there are two possible approaches:

1. Configure and use an [Extractor](http://docs.graylog.org/en/2.3/pages/extractors.html) in graylog
2. Send logs from the Java logging framework of your choice (logback in my case)

## Send logback logs to Graylog

From logback you can send the logs to to Greylogs by adding a new Appender: 

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="true">

  <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <layout class="ch.qos.logback.classic.PatternLayout">
      <Pattern>
        %level %logger - %msg%n
      </Pattern>
    </layout>
  </appender>

  <appender name="GELF" class="de.siegmar.logbackgelf.GelfUdpAppender">
    <graylogHost>gra2.logs.ovh.com</graylogHost>
    <graylogPort>2202</graylogPort>
    <layout class="de.siegmar.logbackgelf.GelfLayout">
        <staticField>X-OVH-TOKEN:7982bbc4-9a66-4426-9de3-33d6eb201ed6</staticField>
    </layout>
  </appender>

  <root level="INFO">
    <appender-ref ref="STDOUT" />
    <appender-ref ref="GELF" />
  </root>

</configuration>
```

Replace `7982bbc4-9a66-4426-9de3-33d6eb201ed6` by your actual Stream token.

You'll need to add the following dependency to you project: `compile 'de.siegmar:logback-gelf:1.0.4'`

There is logback appender [`biz.paluch.logging:logstash-gelf`](https://github.com/mp911de/logstash-gelf) that is quite popular, but I did not manage to make it work. So I went for [`de.siegmar:logback-gelf`](https://github.com/osiegmar/logback-gelf) instead.
