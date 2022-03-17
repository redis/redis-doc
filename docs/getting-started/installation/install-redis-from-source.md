---
title: "Install Redis from Source"
linkTitle: "Install from Source"
weight: 1
description: >
    Compile and install Redis from source
---

You can compile and install Redis from source on variety of platforms and operating systems including Linux and macOS. Redis has no dependencies other than a C  compiler and `libc`.

## Downloading the source files

The Redis source files are available on [this site's Download page]. You can verify the integrity of these downloads by checking them against the digests in the[redis-hashes git repository](https://github.com/redis/redis-hashes).

To obtain the source files for the latest stable version of Redis from the Redis downloads site, run:

{{< highlight bash >}}
wget https://download.redis.io/redis-stable.tar.gz
{{< / highlight >}}

## Compiling Redis

To compile Redis, first the tarball, change to the root directory, and then run `make`:

{{< highlight bash >}}
tar -xzvf redis-stable.tar.gz
cd redis-stable
make
{{< / highlight >}}

If the compile succeeds, you'll find several Redis binaries in the `src` directory, including:

* **redis-server**: the Redis Server itself
* **redis-cli** is the command line interface utility to talk with Redis.

To install these binaries in `/usr/local/bin`, run:

{{< highlight bash  >}}
make install
{{< / highlight >}}

### Starting and stopping Redis in the foreground

Once installed, you can start Redis by running

{{< highlight bash  >}}
redis-server
{{< / highlight >}}

If successful, you'll see the startup logs for Redis, and Redis will be running in the foreground.

To stop Redis, enter `Ctrl-C`.
