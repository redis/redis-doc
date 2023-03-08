---
title: "Python guide"
linkTitle: "Python"
description: Connect your Python application to a Redis database
weight: 1

---

Install Redis and the Redis client, then connect your Python application to a Redis database. 

## redis-py

Get started with the [redis-py](https://github.com/redis/redis-py) client for Redis.

`redis-py` requires a running Redis server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

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
import redis
r = redis.Redis(host='localhost', port=6379, db=0)
r.set('foo', 'bar')
# True
r.get('foo')
# b'bar'
```

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

Create JSON documents to add to your database.

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

Create an index. In this example, all JSON documents with the key prefix `user:` will be indexed.

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

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

```python
schema = (
    TextField("$.name", as_name="name"), 
    TagField("$.city", as_name="city"), 
    NumericField("$.age", as_name="age")
)
```

Perform a simple search using `FT.SEARCH`.

```python
r.ft().search("Paul")
Result{2 total, docs: [Document {'id': 'user:1', 'payload': None, 'json': '{"user":{"name":"Paul John","email":"paul.john@example.com","age":42,"city":"London"}}'}, Document {'id': 'user:3', 'payload': None, 'json': '{"user":{"name":"Paul Zamir","email":"paul.zamir@example.com","age":35,"city":"Tel Aviv"}}'}]}
```

Create a query. 

```python
q1 = Query("Paul").add_filter(NumericFilter("age", 30, 40))
```

Then, filter search results.

```python
r.ft().search(q1)
Result{1 total, docs: [Document {'id': 'user:3', 'payload': None, 'json': '{"user":{"name":"Paul Zamir","email":"paul.zamir@example.com","age":35,"city":"Tel Aviv"}}'}]}
```

Query using JSON Path expressions.

```python
r.ft().search(Query("Paul").return_field("$.user.city", as_field="city")).docs
[Document {'id': 'user:1', 'payload': None, 'city': 'London'},
 Document {'id': 'user:3', 'payload': None, 'city': 'Tel Aviv'}]
```

Aggregate your results using `FT.AGGREGATE`.

```python
req = aggregations.AggregateRequest("Paul").sort_by("@age")
r.ft().aggregate(req).rows
[[b'age', b'35'], [b'age', b'42']]
```

### Learn more

* [Command reference](https://redis-py.readthedocs.io/en/stable/commands.html)
* [Tutorials](https://redis.readthedocs.io/en/stable/examples.html)
* [GitHub](https://github.com/redis/redis-py)
 
