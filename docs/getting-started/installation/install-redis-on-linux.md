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
If you're running a minimal Linux distribution (such as a Docker container), you may need to install `lsb-release` first:

{{< highlight bash  >}}
sudo apt install lsb-release
{{< / highlight  >}}
{{% /alert  %}}

Add the Redis package repository to the <code>apt</code> index.

{{< highlight bash  >}}
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
{{< / highlight  >}}

Next, update apt. Then install Redis:
{{< highlight bash  >}}
sudo apt update
sudo apt install redis
{{< / highlight  >}}

## Install from Snapcraft

Snapcraft is a universal Linux package manager. The [Snapcraft store](https://snapcraft.io/store) provides [Redis packages](https://snapcraft.io/redis) for many Linux distributions.

If your Linux does not currently have [snap](https://snapcraft.io/) installed, you may install it by following the instructions described in [Installing snapd](https://snapcraft.io/docs/installing-snapd).

To install via snap, run:

{{< highlight bash  >}}
sudo snap install redis
{{< / highlight  >}}

## Starting and stopping Redis on Linux

You can start Redis in the foreground by executing the `redis-server` executable directly:

{{< highlight bash  >}}
redis-server
{{< / highlight >}}

If successful, you'll see the startup logs for Redis, and Redis will be up and running.

To stop Redis, enter `Ctrl-C`.

## Next steps

Once you have a running Redis instance, you may want to:

* [Try the Redis CLI tutorial](/manual/cli)
* [Connect using one of the Redis clients](/docs/clients)