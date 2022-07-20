---
title: "Install Redis on Linux"
linkTitle: "Install on Linux"
weight: 1
description: >
    How to install Redis on Ubuntu, RHEL, and CentOS
---

Most major Linux distributions provide packages for Redis.

## Install on Ubuntu/Debian

You can install recent stable versions of Redis from the official `packages.redis.io` APT repository.

{{% alert title="Prerequisites" color="warning" %}}
If you're running a very minimal distribution (such as a Docker container) you may need to install `lsb-release` first:

{{< highlight bash  >}}
sudo apt install lsb-release first"
{{< / highlight  >}}

{{% /alert  %}}

Add the repository to the <code>apt</code> index, update it, and then install:

{{< highlight bash  >}}
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt-get update
sudo apt-get install redis
{{< / highlight  >}}

## Install from Snapcraft

The [Snapcraft store](https://snapcraft.io/store) provides [Redis packages](https://snapcraft.io/redis) that can be installed on platforms that support snap.

To install via snap, run:

{{< highlight bash  >}}
sudo snap install redis
{{< / highlight  >}}

If your Linux does not currently have snap installed, you may install it by following the instructions described in [Installing snapd](https://snapcraft.io/docs/installing-snapd).
