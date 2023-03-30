﻿---
title: "Redis Strings"
linkTitle: "Strings"
weight: 10
description: >
    Introduction to Redis strings
---

Redis strings store sequences of bytes, including text, serialized objects, and binary arrays.
As such, strings are the most basic Redis data type.
They're often used for caching, but they support additional functionality that lets you implement counters and perform bitwise operations, too.

## Examples

* Store and then retrieve a string in Redis:

```
> SET user:1 salvatore
OK
> GET user:1
"salvatore"
```

* Store a serialized JSON string and set it to expire 100 seconds from now:

```
> SET ticket:27 "\"{'username': 'priya', 'ticket_id': 321}\"" EX 100
```

* Increment a counter:

```
> INCR views:page:2
(integer) 1
> INCRBY views:page:2 10
(integer) 11
```

## Limits

By default, a single Redis string can be a maximum of 512 MB.

## Basic commands

### Getting and setting Strings

* `SET` stores a string value.
* `SETNX` stores a string value only if the key doesn't already exist. Useful for implementing locks.
* `GET` retrieves a string value.
* `MGET` retrieves multiple string values in a single operation.

### Managing counters

* `INCRBY` atomically increments (and decrements when passing a negative number) counters stored at a given key.
* Another command exists for floating point counters: [INCRBYFLOAT](/commands/incrbyfloat).

### Bitwise operations

To perform bitwise operations on a string, see the [bitmaps data type](/docs/data-types/bitmaps) docs.

See the [complete list of string commands](/commands/?group=string).

## Performance

Most string operations are O(1), which means they're highly efficient.
However, be careful with the `SUBSTR`, `GETRANGE`, and `SETRANGE` commands, which can be O(n).
These random-access string commands may cause performance issues when dealing with large strings.

## Alternatives

If you're storing structured data as a serialized string, you may also want to consider [Redis hashes](/docs/data-types/hashes) or [RedisJSON](/docs/stack/json).

## Learn more

* [Redis Strings Explained](https://www.youtube.com/watch?v=7CUt4yWeRQE) is a short, comprehensive video explainer on Redis strings.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis strings in detail.
