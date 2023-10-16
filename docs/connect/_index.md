---
title: Connect to Redis
linkTitle: Connect
description: Learn how to use user interfaces and client libraries
weight: 35
aliases:
  - /docs/ui
---

You can connect to Redis in the following ways:

* With the `redis-cli` command line tool
* Use RedisInsight as a graphical user interface
* Via a client library for your programming language
  
## Redis command line interface

The [Redis command line interface](/docs/connect/cli) (also known as `redis-cli`) is a terminal program that sends commands to and reads replies from the Redis server. It has the following two main modes: 

1. An interactive Read Eval Print Loop (REPL) mode where the user types Redis commands and receives replies.
2. A command mode where `redis-cli` is executed with additional arguments, and the reply is printed to the standard output.

## RedisInsight

[RedisInsight](/docs/connect/insight) combines a graphical user interface with Redis CLI to let you work with any Redis deployment. You can visually browse and interact with data, take advantage of diagnostic tools, learn by example, and much more. Best of all, RedisInsight is free.

## Client libraries

It's easy to connect your application to a Redis database. The official client libraries cover the following languages:

* [C#/.NET](/docs/connect/clients/dotnet)
* [Go](/docs/connect/clients/go)
* [Java](/docs/connect/clients/java)
* [Node.js](/docs/connect/clients/nodejs)
* [Python](/docs/connect/clients/python)

You can find a complete list of all client libraries, including the community-maintained ones, on the [clients page](/resources/clients/).

<hr/>
