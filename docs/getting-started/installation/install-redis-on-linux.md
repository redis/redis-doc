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
Add the repository to the <code>apt</code> index, update it, and then install:

{{< highlight bash  >}}
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt-get update
sudo apt-get install redis
{{< / highlight  >}}

## Install from Snapcraft

The [Snapcraft store](https://snapcraft.io/store) provides [Redis packages](https://snapcraft.io/redis) that can be installed on platforms that support snap.
Snap is supported and available on most major Linux distributions.

To install via snap, run:

{{< highlight bash  >}}
sudo snap install redis
{{< / highlight  >}}

If your Linux does not currently have snap installed, install it using the instructions described in [Installing snapd](https://snapcraft.io/docs/installing-snapd).

## Install on RHEL/Fedora/CentOS 8

Red Hat Enterprise Linux (RHEL), Fedora 22+, and CentOS 8 have the default package manager DNF, an updated YUM. Using DNF, Redis can be installed as follows.

{{< highlight bash  >}}
 dnf module install redis
 OR
 dnf install @redis
 {{< / highlight  >}}

## Install on CentOS 7

To avoid having to download the extra packages for enterprise Linux (EPEL) library, CentOS 7 is supported by snap. 

However, if your installation requires the EPEL library, to install Redis along with the other packages see [Install and configure Redis on CentOS 7](https://www.linode.com/docs/guides/install-and-configure-redis-on-centos-7/).
