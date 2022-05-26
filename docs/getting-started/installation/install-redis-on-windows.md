---
title: "Install Redis on Windows"
linkTitle: "Install on Windows"
weight: 1
description: Use Redis on Windows for development
---

Redis is not officially supported on Windows. However, you can install Redis on Windows for development by the following the instructions below.

To install Redis on Windows, you'll first need to enable [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux). WSL2 lets you run Linux binaries natively on Windows. For this method to work, you'll need to be running Windows 10 version 2004 and higher or Windows 11.

## Install or enable WSL2

Microsoft provides [detailed instructions for installing WSL](https://docs.microsoft.com/en-us/windows/wsl/install). Follow these instructions, and take note of the default Linux distribution it installs. This guide assumes Ubuntu.

## Install Redis

Once you're running Ubuntu on Windows, you can install Redis using `apt-get`:

{{< highlight bash  >}}
sudo apt-add-repository ppa:redislabs/redis
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install redis-server
{{< / highlight >}}

Then start the Redis server like so:

{{< highlight bash  >}}
sudo service redis-server start
{{< / highlight  >}}

## Connect to Redis

You can test that your Redis server is running by connecting with the Redis CLI:

{{< highlight bash  >}}
redis-cli 
127.0.0.1:6379> ping
PONG
{{< / highlight >}}
