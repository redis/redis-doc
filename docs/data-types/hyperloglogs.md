---
title: "Redis HyperLogLog"
linkTitle: "HyperLogLog"
weight: 10
description: >
    Introduction to the Redis HyperLogLog data type
---

HyperLogLog is a data structure that estimates the cardinality of a set. As a probabilistic data structure, hyperloglog trades perfect accuracy for efficient space utilization.

## Examples

* Add some items to the HyperLogLog:
```
redis:6379> PFADD members 123
(integer) 1
redis:6379> PFADD members 500
(integer) 1
redis:6379> PFADD members 12
(integer) 1
```

* Estimate the number of members in the set:
```
redis:6379> PFCOUNT members
(integer) 3
```

## Basic commands

[PFADD](/commands/pfadd) add an item to a HyperLogLog.
[PFCOUNT](/commands/pfcount) returns an estimate of the number of items in the set.

See the [complete list of HyperLogLog commands](https://redis.io/commands/?group=hyperloglog).

## Learn more

* [Redis HyperLogLog Explained](https://www.youtube.com/watch?v=MunL8nnwscQ) shows you how to use Redis HyperLogLog data structures to build a traffic heat map.

