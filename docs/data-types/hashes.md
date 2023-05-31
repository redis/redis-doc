---
title: "Redis hashes"
linkTitle: "Hashes"
weight: 40
description: >
    Introduction to Redis hashes
---

Redis hashes are record types structured as collections of field-value pairs.
You can use hashes to represent basic objects and to store groupings of counters, among other things.

    > hset user:1000 username antirez birthyear 1977 verified 1
    (integer) 3
    > hget user:1000 username
    "antirez"
    > hget user:1000 birthyear
    "1977"
    > hgetall user:1000
    1) "username"
    2) "antirez"
    3) "birthyear"
    4) "1977"
    5) "verified"
    6) "1"

While hashes are handy to represent *objects*, actually the number of fields you can
put inside a hash has no practical limits (other than available memory), so you can use
hashes in many different ways inside your application.

The command [`HSET`](/commands/hset) sets multiple fields of the hash, while [`HGET`](/commands/hget) retrieves
a single field. [`HMGET`](/commands/hmget) is similar to [`HGET`](/commands/hget) but returns an array of values:

    > hmget user:1000 username birthyear no-such-field
    1) "antirez"
    2) "1977"
    3) (nil)

There are commands that are able to perform operations on individual fields
as well, like [`HINCRBY`](/commands/hincrby):

    > hincrby user:1000 birthyear 10
    (integer) 1987
    > hincrby user:1000 birthyear 10
    (integer) 1997

You can find the [full list of hash commands in the documentation](https://redis.io/commands#hash).

It is worth noting that small hashes (i.e., a few elements with small values) are
encoded in special way in memory that make them very memory efficient.

## Basic commands

* `HSET` sets the value of one or more fields on a hash.
* `HGET` returns the value at a given field.
* `HMGET` returns the values at one or more given fields.
* `HINCRBY` increments the value at a given field by the integer provided.

See the [complete list of hash commands](https://redis.io/commands/?group=hash).


## Examples

* Represent a basic user profile as a hash:
```
> HSET user:123 username martina firstName Martina lastName Elisa country GB
(integer) 4
> HGET user:123 username
"martina"
> HGETALL user:123
1) "username"
2) "martina"
3) "firstName"
4) "Martina"
5) "lastName"
6) "Elisa"
7) "country"
8) "GB"
```

* Store counters for the number of times device 777 had pinged the server, issued a request, or sent an error:
```
> HINCRBY device:777:stats pings 1
(integer) 1
> HINCRBY device:777:stats pings 1
(integer) 2
> HINCRBY device:777:stats pings 1
(integer) 3
> HINCRBY device:777:stats errors 1
(integer) 1
> HINCRBY device:777:stats requests 1
(integer) 1
> HGET device:777:stats pings
"3"
> HMGET device:777:stats requests errors
1) "1"
2) "1"
```


## Performance

Most Redis hash commands are O(1).

A few commands - such as `HKEYS`, `HVALS`, and `HGETALL` - are O(n), where _n_ is the number of field-value pairs.

## Limits

Every hash can store up to 4,294,967,295 (2^32 - 1) field-value pairs.
In practice, your hashes are limited only by the overall memory on the VMs hosting your Redis deployment.

## Learn more

* [Redis Hashes Explained](https://www.youtube.com/watch?v=-KdITaRkQ-U) is a short, comprehensive video explainer covering Redis hashes.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis hashes in detail.
