---
title: "Install Redis on Linux"
linkTitle: "Install on Linux"
weight: 1
description: >
    How to install Redis on Ubuntu, RHEL, and CentOS
---

Most major Linux distributions provide packages for Redis.

## Install on Ubuntu

You can install the latest stable version of Redis from the `redislabs/redis` package repository. Add the repository to your `apt` index, update the index, and then install:

{{< highlight bash  >}}
sudo add-apt-repository ppa:redislabs/redis
sudo apt-get update
sudo apt-get install redis
{{< / highlight  >}}

## Install from Snapcraft

The [Snapcraft store](https://snapcraft.io/store) provides [Redis installation packages](https://snapcraft.io/redis) for a dozen Linux distributions. For example, here's how to install Redis on CentOS using Snapcraft:

{{< highlight bash  >}}
sudo yum install epel-release
sudo yum install snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install redis
{{< / highlight  >}}