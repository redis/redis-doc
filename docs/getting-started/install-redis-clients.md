---
title: "Install Redis clients"
linkTitle: "Install Redis clients"
weight: 4
description: >
    How to use Redis from your application
aliases:
    - /docs/getting-started/install-redis-clients
---

Using Redis from the command line interface is not enough as
the goal is to use it from your application. To do so, you need to
download and install a Redis client library for your programming language.
You'll find a [full list of clients for different languages in this page](/docs/clients).

For instance if you happen to use the Ruby programming language our best advice
is to use the [Redis-rb](https://github.com/redis/redis-rb) client.
You can install it using the command **gem install redis**.

These instructions are Ruby specific, but actually many library clients for
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