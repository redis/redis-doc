---
title: "Python guide"
linkTitle: "Python"
description: Connect your Python application to a Redis database
weight: 1

---

Use one of the following options to connect your application to a Redis database:

* [redis-py](#redis-py)
* [redis-om-python](#redis-om-python)

## redis-py

Get started with a Python client for Redis. Looking for a high-level library to handle object mapping? See [redis-om-python](#redis-om-python).

`redis-py` requires a running Redis server. See the [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

To install `redis-py`, type:

```bash
pip install redis
```

For faster performance, install redis with [`hiredis`](https://github.com/redis/hiredis) support. This provides a compiled response parser, and for most cases requires zero code changes. By default, if `hiredis` >= 1.0 is available, `redis-py` attempts to use it for response parsing.

```bash
pip install redis[hiredis]
```

### Connect to your Redis database

By default, `redis-py` uses a connection pool to manage connections. Each instance of a Redis class receives its own connection pool. You can, however, define your own `redis.ConnectionPool`.

```sh
>>> pool = redis.ConnectionPool(host='localhost', port=6379, db=0)
>>> r = redis.Redis(connection_pool=pool)
```

Alternatively, you might want to look at [async connections](https://redis.readthedocs.io/en/stable/examples/asyncio_examples.html), or [cluster connections](https://redis.readthedocs.io/en/stable/connections.html#cluster-client), or [async cluster connections](https://redis.readthedocs.io/en/stable/connections.html#async-cluster-client).

### Example

Connect to localhost on port 6379, set a value in Redis, and retrieve it. All responses are returned as bytes in Python. To receive decoded strings, set `decode_responses=True`. For this, and more connection options, see [these examples](https://redis.readthedocs.io/en/stable/examples.html).

```sh
>>> import redis
>>> r = redis.Redis(host='localhost', port=6379, db=0)
>>> r.set('foo', 'bar')
True
>>> r.get('foo')
b'bar'
```

Explore the following topics to get up and running your application with Python: 

* [Tutorials](https://redis.readthedocs.io/en/stable/examples.html)
* [Command reference](https://redis-py.readthedocs.io/en/stable/commands.html)
* [Source code](https://github.com/redis/redis-py)
 
## redis-om-python

[Redis OM Python](https://github.com/redis/redis-om-python) is a Redis client that provides high-level abstractions for managing document data in Redis. This tutorial shows you how to get up and running with Redis OM Python, Redis Stack, and the [Flask](https://flask.palletsprojects.com/) micro-framework.

We'd love to see what you build with Redis Stack and Redis OM. [Join the Redis community on Discord](https://discord.gg/redis) to chat with us about all things Redis OM and Redis Stack. Read more about Redis OM Python [our announcement blog post](https://redis.com/blog/introducing-redis-om-for-python/).

### Examples
* [Build API](/docs/tutorials/python-om/)