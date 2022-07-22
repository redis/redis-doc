---
title: "Redis Strings"
linkTitle: "Strings"
weight: 2
description: >
    Introduction to Redis Strings
---

Redis strings store sequences of bytes, including text, serialized objects, and binary arrays. As such, strings are the most basic Redis data type. They're often used for caching, but they support additional functionality that lets you implement counters and bitfields, too.

## Examples

* Store and then retrieve a string in Redis:

```
redis:6379> SET user:1 salvatore
OK
redis:6379> GET user:1
"salvatore"
```

* Store a serialized JSON string and set it to expire 100 seconds from now:

```
redis:6379> SET ticket:27 "\"{'username': 'priya', 'ticket_id': 321}\"" EX 100
```

* Increment a counter:

```
redis:6379> INCR views:page:2
(integer) 1
redis:6379> INCRBY views:page:2 10
(integer) 11
```

## Limits

A single Redis string can be a maximum of 512 MB.

## Commands

### Getting and setting Strings

* [SET](/commands/set) stores a string value.
* [SETNX](/commands/setnx) stores a string value only if the key doesn't already exist. Useful for implemeting locks.
* [GET](/commands/get) retrieve a string value.
* [MGET](/commands/mget) retrieve multiple string values in a single operation.

### Manging counters

* [INCR](/commands/incr), [INCRBY](/commands/incrby), [DECR](/commands/decr), and [DECRBY](/commands/decrby) atomically increment and decrement counters stored at a given key.
* A parellel set of commands existing for floating point counters: [INCRBYFLOAT](/commands/incrbyfloat) and [DECRBYFLOAT](/commands/decrbyfloat).

### Bitfields

To perform bitwise operations on a string, see the [bitmaps data type](/docs/data-types/bitmaps) docs.

See the [complete list of string commands](/commands/?group=string).

## Performance

Most string operations are O(1), which means they're highly efficient. However, be careful with the [SUBSTR](/commands/substr), [GETRANGE](/commands/getrange), and [SETRANGE](/commands/setrange)commands, which can be O(n). These random-access string commands may cause performance issues when dealing with very large strings.

## Alternatives

If you're storing structured data a string, you may also want to consider [Redis hashes](/docs/data-types/hashes) or [RedisJSON](/docs/stack/json).

## Learn more

* [Redis Strings Explained](https://www.youtube.com/watch?v=7CUt4yWeRQE) is a short, comprehensive video explainer on Redis strings.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis strings in detail.
