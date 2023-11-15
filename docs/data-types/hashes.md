﻿---
title: "Redis hashes"
linkTitle: "Hashes"
weight: 40
description: >
    Introduction to Redis hashes
---

Redis hashes are record types structured as collections of field-value pairs.
You can use hashes to represent basic objects and to store groupings of counters, among other things.

{{< clients-example hash_tutorial set_get_all >}}
> HSET bike:1 model Deimos brand Ergonom type 'Enduro bikes' price 4972
(integer) 4
> HGET bike:1 model
"Deimos"
> HGET bike:1 price
"4972"
> HGETALL bike:1
1) "model"
2) "Deimos"
3) "brand"
4) "Ergonom"
5) "type"
6) "Enduro bikes"
7) "price"
8) "4972"

{{< /clients-example >}}

While hashes are handy to represent *objects*, actually the number of fields you can
put inside a hash has no practical limits (other than available memory), so you can use
hashes in many different ways inside your application.

The command `HSET` sets multiple fields of the hash, while `HGET` retrieves
a single field. `HMGET` is similar to `HGET` but returns an array of values:

{{< clients-example hash_tutorial hmget >}}
> HMGET bike:1 model price no-such-field
1) "Deimos"
2) "4972"
3) (nil)
{{< /clients-example >}}

There are commands that are able to perform operations on individual fields
as well, like `HINCRBY`:

{{< clients-example hash_tutorial hincrby >}}
> HINCRBY bike:1 price 100
(integer) 5072
> HINCRBY bike:1 price -100
(integer) 4972
{{< /clients-example >}}

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

* Store counters for the number of times bike:1 has been ridden, has crashed, or has changed owners:
{{< clients-example hash_tutorial incrby_get_mget >}}
> HINCRBY bike:1:stats rides 1
(integer) 1
> HINCRBY bike:1:stats rides 1
(integer) 2
> HINCRBY bike:1:stats rides 1
(integer) 3
> HINCRBY bike:1:stats crashes 1
(integer) 1
> HINCRBY bike:1:stats owners 1
(integer) 1
> HGET bike:1:stats rides
"3"
> HMGET bike:1:stats owners crashes
1) "1"
2) "1"
{{< /clients-example >}}


## Performance

Most Redis hash commands are O(1).

A few commands - such as `HKEYS`, `HVALS`, and `HGETALL` - are O(n), where _n_ is the number of field-value pairs.

## Limits

Every hash can store up to 4,294,967,295 (2^32 - 1) field-value pairs.
In practice, your hashes are limited only by the overall memory on the VMs hosting your Redis deployment.

## Learn more

* [Redis Hashes Explained](https://www.youtube.com/watch?v=-KdITaRkQ-U) is a short, comprehensive video explainer covering Redis hashes.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis hashes in detail.