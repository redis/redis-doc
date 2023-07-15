---
title: "Install Redis on Windows"
linkTitle: "Install on Windows"
weight: 1
description: Use Redis on Windows for development
---

Redis is not officially supported on Windows. However, you can install Redis on Windows for development by following the instructions below.

To install Redis on Windows, you'll first need to enable [Scoop](https://scoop.sh). Scoop is a tool that enables installing and managing software packages on Windows systems using the Scoop package manager.

## Install Scoop

Scoop has a pretty clean [installation process](https://github.com/ScoopInstaller/Scoop#installation). Type the following command
{{< highlight bash  >}}
iwr -useb get.scoop.sh | iex
{{< / highlight  >}}

## Install Redis

Simply install `redis` through Scoop that installs the two main shims for you, `redis-cli` & `redis-server`

{{< highlight bash  >}}
scoop install redis
{{< / highlight  >}}

Lastly, start the Redis server like so:

{{< highlight bash  >}}
redis-server
{{< / highlight  >}}

## Connect to Redis

You can test that your Redis server is running by connecting with the Redis CLI:

{{< highlight bash  >}}
redis-cli 
127.0.0.1:6379> ping
PONG
{{< / highlight >}}
