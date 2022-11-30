---
title: "Redis bitmaps"
linkTitle: "Bitmaps"
weight: 120
description: >
    Introduction to Redis bitmaps
---

Redis bitmaps are an extension of the string data type that lets you treat a string like a bit vector.
You can also perform bitwise operations on one or more strings.
Some examples of bitmap use cases include:

* Efficient set representations for cases where the members of a set correspond to the integers 0-N.
* Object permissions, where each bit represents a particular permission, similar to the way that file systems store permissions.

## Examples

Suppose you have 1000 sensors deployed in the field, labeled 0-999.
You want to quickly determine whether a given sensor has pinged the server within the hour. 

You can represent this scenario using a bitmap whose key references the current hour.

* Sensor 123 pings the server on January 1, 2024 within the 00:00 hour.
```
> SETBIT pings:2024-01-01-00:00 123 1
(integer) 0
```

* Did sensor 123 ping the server on January 1, 2024 within the 00:00 hour?
```
> GETBIT pings:2024-01-01-00:00 123
1
```

* What about server 456?
```
> GETBIT pings:2024-01-01-00:00 456
0
```

## Basic commands

* `SETBIT` sets a bit at the provided offset to 0 or 1.
* `GETBIT` returns the value of a bit at a given offset.
* `BITOP` lets you perform bitwise operations against one or more strings.

See the [complete list of bitmap commands](https://redis.io/commands/?group=bitmap).

## Performance

`SETBIT` and `GETBIT` are O(1).
`BITOP` is O(n), where _n_ is the length of the longest string in the comparison.

## Learn more

* [Redis Bitmaps Explained](https://www.youtube.com/watch?v=oj8LdJQjhJo) teaches you how to use bitmaps for map exploration in an online game. 
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis bitmaps in detail.