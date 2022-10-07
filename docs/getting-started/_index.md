---
title: "Getting started with Redis"
linkTitle: "Getting started"
weight: 1
description: >
    How to get up and running with Redis
aliases:
    - /docs/getting-started/tutorial
---

This is a guide to getting started with Redis. You'll learn how to install, run, and experiment with the Redis server process.

## Install Redis

How you install Redis depends on your operating system. See the guide below that best fits your needs:

* [Install Redis from Source]({{< ref "/docs/getting-started/installation/install-redis-from-source.md" >}})
* [Install Redis on Linux]({{< ref "/docs/getting-started/installation/install-redis-on-linux.md" >}})
* [Install Redis on macOS]({{< ref "/docs/getting-started/installation/install-redis-on-mac-os.md" >}})
* [Install Redis on Windows]({{< ref "/docs/getting-started/installation/install-redis-on-windows.md" >}})


{{% alert title="Note" color="warning" %}}
If you plan to run Redis at scale with large datasets, consider using extended [Redis Enterprise](/docs/about/redis-enterprise/) options: software, cloud, and hybrid/multi-cloud. Want to learn how to install and run Redis Enterprise Software? See [Get started with Redis Enterprise Software](https://docs.redis.com/latest/rs/installing-upgrading/get-started-redis-enterprise-software/).
{{% /alert %}}

Once you have Redis up and running, and can connect using `redis-cli`, you can continue with the steps below.

## Exploring Redis with the CLI

External programs talk to Redis using a TCP socket and a Redis specific protocol. This protocol is implemented in the Redis client libraries for the different programming languages. However to make hacking with Redis simpler Redis provides a command line utility that can be used to send commands to Redis. This program is called **redis-cli**.

The first thing to do in order to check if Redis is working properly is sending a **PING** command using redis-cli:

    $ redis-cli ping
    PONG

Running **redis-cli** followed by a command name and its arguments will send this command to the Redis instance running on localhost at port 6379. You can change the host and port used by `redis-cli` - just try the `--help` option to check the usage information.

Another interesting way to run `redis-cli` is without arguments: the program will start in interactive mode. You can type different commands and see their replies.

    $ redis-cli
    redis 127.0.0.1:6379> ping
    PONG
    redis 127.0.0.1:6379> set mykey somevalue
    OK
    redis 127.0.0.1:6379> get mykey
    "somevalue"

At this point you are able to talk with Redis. It is the right time to pause a bit with this tutorial and start the [fifteen minutes introduction to Redis data types](https://redis.io/topics/data-types-intro) in order to learn a few Redis commands. Otherwise if you already know a few basic Redis commands you can keep reading.

Securing Redis
===

By default Redis binds to **all the interfaces** and has no authentication at
all. If you use Redis in a very controlled environment, separated from the
external internet and in general from attackers, that's fine. However if an unhardened Redis
is exposed to the internet, it is a big security concern. If you are not 100% sure your environment is secured properly, please check the following steps in order to make Redis more secure, which are enlisted in order of increased security.

1. Make sure the port Redis uses to listen for connections (by default 6379 and additionally 16379 if you run Redis in cluster mode, plus 26379 for Sentinel) is firewalled, so that it is not possible to contact Redis from the outside world.
2. Use a configuration file where the `bind` directive is set in order to guarantee that Redis listens on only the network interfaces you are using. For example only the loopback interface (127.0.0.1) if you are accessing Redis just locally from the same computer, and so forth.
3. Use the `requirepass` option in order to add an additional layer of security so that clients will require to authenticate using the `AUTH` command.
4. Use [spiped](http://www.tarsnap.com/spiped.html) or another SSL tunneling software in order to encrypt traffic between Redis servers and Redis clients if your environment requires encryption.

Note that a Redis instance exposed to the internet without any security [is very simple to exploit](http://antirez.com/news/96), so make sure you understand the above and apply **at least** a firewall layer. After the firewall is in place, try to connect with `redis-cli` from an external host in order to prove yourself the instance is actually not reachable.

Using Redis from your application
===

Of course using Redis just from the command line interface is not enough as
the goal is to use it from your application. In order to do so you need to
download and install a Redis client library for your programming language.
You'll find a [full list of clients for different languages in this page](https://redis.io/clients).

For instance if you happen to use the Ruby programming language our best advice
is to use the [Redis-rb](https://github.com/redis/redis-rb) client.
You can install it using the command **gem install redis**.

These instructions are Ruby specific but actually many library clients for
popular languages look quite similar: you create a Redis object and execute
commands calling methods. A short interactive example using Ruby:

    >> require 'rubygems'
    => false
    >> require 'redis'
    => true
    >> r = Redis.new
    => #<Redis client v4.5.1 for redis://127.0.0.1:6379/0>
    >> r.ping
    => "PONG"
    >> r.set('foo','bar')
    => "OK"
    >> r.get('foo')
    => "bar"

Redis persistence
=================

You can learn [how Redis persistence works on this page](https://redis.io/topics/persistence), however what is important to understand for a quick start is that by default, if you start Redis with the default configuration, Redis will spontaneously save the dataset only from time to time (for instance after at least five minutes if you have at least 100 changes in your data), so if you want your database to persist and be reloaded after a restart make sure to call the **SAVE** command manually every time you want to force a data set snapshot. Otherwise make sure to shutdown the database using the **SHUTDOWN** command:

    $ redis-cli shutdown

This way Redis will make sure to save the data on disk before quitting.
Reading the [persistence page](https://redis.io/topics/persistence) is strongly suggested in order to better understand how Redis persistence works.

Installing Redis more properly
==============================

Running Redis from the command line is fine just to hack a bit or for development. However, at some point you'll have some actual application to run on a real server. For this kind of usage you have two different choices:

* Run Redis using screen.
* Install Redis in your Linux box in a proper way using an init script, so that after a restart everything will start again properly.

A proper install using an init script is strongly suggested.
The following instructions can be used to perform a proper installation using the init script shipped with Redis version 2.4 or higher in a Debian or Ubuntu based distribution.

We assume you already copied **redis-server** and **redis-cli** executables under /usr/local/bin.

* Create a directory in which to store your Redis config files and your data:

        sudo mkdir /etc/redis
        sudo mkdir /var/redis

* Copy the init script that you'll find in the Redis distribution under the **utils** directory into `/etc/init.d`. We suggest calling it with the name of the port where you are running this instance of Redis. For example:

        sudo cp utils/redis_init_script /etc/init.d/redis_6379

* Edit the init script.

        sudo vi /etc/init.d/redis_6379

Make sure to modify **REDISPORT** accordingly to the port you are using.
Both the pid file path and the configuration file name depend on the port number.

* Copy the template configuration file you'll find in the root directory of the Redis distribution into `/etc/redis/` using the port number as name, for instance:

        sudo cp redis.conf /etc/redis/6379.conf

* Create a directory inside `/var/redis` that will work as data and working directory for this Redis instance:

        sudo mkdir /var/redis/6379

* Edit the configuration file, making sure to perform the following changes:
    * Set **daemonize** to yes (by default it is set to no).
    * Set the **pidfile** to `/var/run/redis_6379.pid` (modify the port if needed).
    * Change the **port** accordingly. In our example it is not needed as the default port is already 6379.
    * Set your preferred **loglevel**.
    * Set the **logfile** to `/var/log/redis_6379.log`
    * Set the **dir** to `/var/redis/6379` (very important step!)
* Finally add the new Redis init script to all the default runlevels using the following command:

        sudo update-rc.d redis_6379 defaults

You are done! Now you can try running your instance with:

    sudo /etc/init.d/redis_6379 start

Make sure that everything is working as expected:

* Try pinging your instance with redis-cli.
* Do a test save with `redis-cli save` and check that the dump file is correctly stored into `/var/redis/6379/` (you should find a file called `dump.rdb`).
* Check that your Redis instance is correctly logging in the log file.
* If it's a new machine where you can try it without problems make sure that after a reboot everything is still working.

Note: In the above instructions we skipped many Redis configuration parameters that you would like to change, for instance in order to use AOF persistence instead of RDB persistence, or to setup replication, and so forth.
Make sure to read the example [`redis.conf`](https://github.com/redis/redis/blob/6.2/redis.conf) file (that is heavily commented) and the other documentation you can find in this web site for more information.
