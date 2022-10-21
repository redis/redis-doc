---
title: "Explore Redis with CLI"
linkTitle: "Explore Redis with CLI"
weight: 2
description: >
    Interact with Redis
aliases:
    - /docs/getting-started/explore-redis
---

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
