---
title: "Install Redis on Linux"
linkTitle: "Install on Linux"
weight: 1
description: >
    How to install Redis on Ubuntu, RHEL, and CentOS
---

Most major Linux distributions provide packages for Redis.

## Install on Ubuntu

 You can install recent stable versions of Redis from the official
 `packages.redis.io` APT repository. Add the repository to the <code>apt</code> index, update it, and then install:

{{< highlight bash  >}}
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt-get update
sudo apt-get install redis
{{< / highlight  >}}

## Install from Snapcraft

The [Snapcraft store](https://snapcraft.io/store) provides [Redis installation packages](https://snapcraft.io/redis) for dozens of Linux distributions. For example, here's how to install Redis on CentOS using Snapcraft:

{{< highlight bash  >}}
sudo yum install epel-release
sudo yum install snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap/snap
sudo snap install redis
{{< / highlight  >}}
