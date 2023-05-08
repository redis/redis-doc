---
title: "Python guide"
linkTitle: "Python"
description: Connect your Python application to a Redis database
weight: 5

---

Install Redis and the Redis client, then connect your Python application to a Redis database. 

## redis-py

Get started with the [redis-py](https://github.com/redis/redis-py) client for Redis. 

`redis-py` requires a running Redis or [Redis Stack](/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

To install `redis-py`, enter:

```bash
pip install redis
```

For faster performance, install Redis with [`hiredis`](https://github.com/redis/hiredis) support. This provides a compiled response parser, and for most cases requires zero code changes. By default, if `hiredis` >= 1.0 is available, `redis-py` attempts to use it for response parsing.

```bash
pip install redis[hiredis]
```

### Connect

Connect to localhost on port 6379, set a value in Redis, and retrieve it. All responses are returned as bytes in Python. To receive decoded strings, set `decode_responses=True`. For more connection options, see [these examples](https://redis.readthedocs.io/en/stable/examples.html).

```python
r = redis.Redis(host='localhost', port=6379, decode_responses=True)
```

Store and retrieve a simple string.

```python
r.set('foo', 'bar')
# True
r.get('foo')
# bar
```

Store and retrieve a dict.

```python
r.hset('user-session:123', mapping={
    'name': 'John',
    "surname": 'Smith',
    "company": 'Redis',
    "age": 29
})
# True

r.hgetall('user-session:123')
# {'surname': 'Smith', 'name': 'John', 'company': 'Redis', 'age': '29'}
```

#### Connect to a Redis cluster

To connect to a Redis cluster, use `RedisCluster`.

```python
from redis.cluster import RedisCluster

rc = RedisCluster(host='localhost', port=16379)

print(rc.get_nodes())
# [[host=127.0.0.1,port=16379,name=127.0.0.1:16379,server_type=primary,redis_connection=Redis<ConnectionPool<Connection<host=127.0.0.1,port=16379,db=0>>>], ...

rc.set('foo', 'bar')
# True

rc.get('foo')
# b'bar'
```
For more information, see [redis-py Clustering](https://redis-py.readthedocs.io/en/stable/clustering.html).

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

```python
import redis

r = redis.Redis(
    host="my-redis.cloud.redislabs.com", port=6379,
    username="default", # use your Redis user. More info https://redis.io/docs/management/security/acl/
    password="secret", # use your Redis password
    ssl=True,
    ssl_certfile="./redis_user.crt",
    ssl_keyfile="./redis_user_private.key",
    ssl_ca_certs="./redis_ca.pem",
)
r.set('foo', 'bar')
# True

r.get('foo')
# b'bar'
```
For more information, see [redis-py TLS examples](https://redis-py.readthedocs.io/en/stable/examples/ssl_connection_examples.html).

### Example: Indexing and querying JSON documents

Make sure that you have Redis Stack and `redis-py` installed.

Connect to your Redis database.

{{< clients-example search_quickstart connect Python />}}

Let's create some test data to add to your database.

{{< clients-example search_quickstart data_sample Python />}}

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

{{< clients-example search_quickstart define_index Python />}}

Create an index. In this example, all JSON documents with the key prefix `bicycle:` will be indexed. 

{{< clients-example search_quickstart create_index Python />}}

Use `JSON.SET` to add bicycle data to the database.

{{< clients-example search_quickstart add_documents Python />}}

Let's find a folding bicycle and filter the results by price range. For more information, see [Query syntax](/docs/stack/search/reference/query_syntax).

{{< clients-example search_quickstart query_single_term_and_num_range Python />}}

Return only the `price` field.

{{< clients-example search_quickstart query_single_term_limit_fields Python />}}

Count all bicycles based on their condition with `FT.AGGREGATE`.

{{< clients-example search_quickstart simple_aggregation Python />}}

### Learn more

* [Command reference](https://redis-py.readthedocs.io/en/stable/commands.html)
* [Tutorials](https://redis.readthedocs.io/en/stable/examples.html)
* [GitHub](https://github.com/redis/redis-py)
 
