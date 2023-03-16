---
title: "Python guide"
linkTitle: "Python"
description: Connect your Python application to a Redis database
weight: 1

---

Install Redis and the Redis client, then connect your Python application to a Redis database. 

## redis-py

Get started with the [redis-py](https://github.com/redis/redis-py) client for Redis. 

`redis-py` requires a running Redis server a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

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
For more information, see [Redis-Py Clustering](https://redis-py.readthedocs.io/en/stable/clustering.html).

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

```python
import redis

r = redis.Redis(
    host="my-redis.cloud.redislabs.com", port=6379,
    username="default", # user your Redis user. More info https://redis.io/docs/management/security/acl/
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
For more information, see [Redis-Py TLS examples](https://redis-py.readthedocs.io/en/stable/examples/ssl_connection_examples.html).

### Example: Indexing and querying JSON documents

Make sure that you have Redis Stack and `redis-py` installed. Import dependencies:

```python
import redis
from redis.commands.json.path import Path
import redis.commands.search.aggregation as aggregations
import redis.commands.search.reducers as reducers
from redis.commands.search.field import TextField, NumericField, TagField
from redis.commands.search.indexDefinition import IndexDefinition, IndexType
from redis.commands.search.query import NumericFilter, Query
```

Connect to your Redis database.

```python
r = redis.Redis(host='localhost', port=6379)
```

Specify which fields to return from the JSON document.

```python
user1 = {
    "name": "Paul John",
    "email": "paul.john@example.com",
    "age": 42,
    "city": "London"
}
user2 = {
    "name": "Eden Zamir",
    "email": "eden.zamir@example.com",
    "age": 29,
    "city": "Tel Aviv"
}
user3 = {
    "name": "Paul Zamir",
    "email": "paul.zamir@example.com",
    "age": 35,
    "city": "Tel Aviv"
}
```

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

```python
schema = (
    TextField("$.name", as_name="name"), 
    TagField("$.city", as_name="city"), 
    NumericField("$.age", as_name="age")
)
```

Create an index. In this example, all JSON documents with the key prefix `user:` will be indexed. For more information, see [Query syntax](https://redis.io/docs/stack/search/reference/query_syntax). 

```python
rs = r.ft("idx:users")
rs.create_index(
    schema,
    definition=IndexDefinition(
        prefix=["user:"], index_type=IndexType.JSON
    )
)
# b'OK'
```

Use `JSON.SET` to set each user value at the specified path.

```python
r.json().set("user:1", Path.root_path(), user1)
r.json().set("user:2", Path.root_path(), user2)
r.json().set("user:3", Path.root_path(), user3)
```

Let's find user `Paul` and filter the results by age.

```python
res = rs.search(
    Query("Paul @age:[30 40]")
)
# Result{1 total, docs: [Document {'id': 'user:3', 'payload': None, 'json': '{"name":"Paul Zamir","email":"paul.zamir@example.com","age":35,"city":"Tel Aviv"}'}]}
```

Query using JSON Path expressions.

```python
rs.search(
    Query("Paul").return_field("$.city", as_field="city")
).docs
# [Document {'id': 'user:1', 'payload': None, 'city': 'London'}, Document {'id': 'user:3', 'payload': None, 'city': 'Tel Aviv'}]
```

Aggregate your results using `FT.AGGREGATE`.

```python
req = aggregations.AggregateRequest("*").group_by('@city', reducers.count().alias('count'))
print(rs.aggregate(req).rows)
# [[b'city', b'Tel Aviv', b'count', b'2'], [b'city', b'London', b'count', b'1']]
```

### Learn more

* [Command reference](https://redis-py.readthedocs.io/en/stable/commands.html)
* [Tutorials](https://redis.readthedocs.io/en/stable/examples.html)
* [GitHub](https://github.com/redis/redis-py)
 
