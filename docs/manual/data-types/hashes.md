---
title: "Redis Hash Type"
linkTitle: "Hashes"
weight: 2
description: >
    Introduction to the Redis Hash data type
---

Redis hashes are record types structured as a set of field-value pairs. You can uses hashes to represent basic objects and to store a collections of counters, among other things.

## Examples

* Represent a basic user as a hash:
```
redis:6379> HSET user:123 username martina firstName Martina lastName Elisa country GB
(integer) 4
redis:6379> HGET user:123 username
"martina"
redis:6379> HGETALL user:123
1) "username"
2) "martina"
3) "firstName"
4) "Martina"
5) "lastName"
6) "Elisa"
7) "country"
8) "GB"
```

* Store counters for the number of times device 777 has pinged the server, issued a request, or sent an error:
```
redis:6379> HINCRBY device:777:stats pings 1
(integer) 1
redis:6379> HINCRBY device:777:stats pings 1
(integer) 2
redis:6379> HINCRBY device:777:stats pings 1
(integer) 3
redis:6379> HINCRBY device:777:stats errors 1
(integer) 1
redis:6379> HINCRBY device:777:stats requests 1
(integer) 1
redis:6379> HGET device:777:stats errors
"1"
redis:6379> HGET device:777:stats pings
"3"
```

## Commands

[HSET](/commands/hset) sets the value of one or more fields on a hash.
[HGET](/commands/hset) returns the value at a given field. 
[HINCRBY](/commands/hincrby) increments the value at a given field by the integer provided.

See the [complete list of hash commands](https://redis.io/commands/?group=hash).

## Performance

Most Redis hash commands are O(1).

A few command, such as [HGETALL](/commands/hgetall), are O(n), where _n_ is the number of field-value pairs.

## Limits

Every hash can store up to 4,294,967,295 (2^32 - 1) field-value pairs. In practice, the means that your hashes will be limited only by the overall memory on the VMs hosting your Redis deployment.

## Learn more

* [Redis Hashes Explained](https://www.youtube.com/watch?v=-KdITaRkQ-U) is a short, comprehensive video explainer covering Redis hashes.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis hashes in detail.