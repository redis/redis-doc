---
title: "Install Redis from Source"
linkTitle: "Install from Source"
weight: 5
description: >
    Compile and install Redis from source
---

You can compile and install Redis from source on variety of platforms and operating systems including Linux and macOS. Redis has no dependencies other than a C  compiler and `libc`.

## Downloading the source files

The Redis source files are available on [this site's Download page]. You can verify the integrity of these downloads by checking them against the digests in the [redis-hashes git repository](https://github.com/redis/redis-hashes).

To obtain the source files for the latest stable version of Redis from the Redis downloads site, run:

{{< highlight bash >}}
wget https://download.redis.io/redis-stable.tar.gz
{{< / highlight >}}

## Install needed dependencies

{{< highlight bash >}}
apt install gcc -y
{{< / highlight >}}

or

{{< highlight bash >}}
apt install build-essential tcl8.5 -y
{{< / highlight >}}

## Compiling Redis

To compile Redis, first the tarball, change to the root directory, and then run `make`:

{{< highlight bash >}}
tar -xzvf redis-stable.tar.gz
cd redis-stable
make
{{< / highlight >}}

If the compile succeeds, you'll find several Redis binaries in the `src` directory, including:

* **redis-server**: The Redis Server itself
* **redis-cli**: The command line interface utility to talk with Redis.
* **redis-benchmark**: The command line tool for benchmarks

### Starting and stopping Redis in the foreground

Once installed, you can start Redis by running

{{< highlight bash  >}}
src/redis-server
{{< / highlight >}}

To install the binaries above in `/usr/local/bin`, run:

{{< highlight bash >}}
make install
{{< / highlight >}}

Then Redis can also be started like this:

{{< highlight bash  >}}
redis-server
{{< / highlight >}}

If successful, you'll see the startup logs for Redis. Redis will be running in the foreground.

Check if screen exists with the following command, if not, it will be installed directly:

{{< highlight bash  >}}
if ! command -v screen > /dev/null; then
    apt install screen -y
fi
{{< / highlight >}}

If you want to run redis in the background

{{< highlight bash  >}}
screen -S Redis redis-server
{{< / highlight >}}

To stop Redis, enter `Ctrl-C`.