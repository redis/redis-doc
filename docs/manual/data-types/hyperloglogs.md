---
title: "Redis Hyperloglog Type"
linkTitle: "Hyperloglogs"
weight: 1
description: >
    Introduction to the Redis Hyperloglog data type
---

Hyperloglog is a data structure that estimates the cardinality of a set. As a probabilistic data structure, hyperloglog trades perfect accuracy for efficient space utilization.

## Examples

* Add some items to the hyperloglog:
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

## Commands

[PFADD](/commands/pfadd) add an item to a hyperloglog.
[PFCOUNT](/commands/pfcount) returns an estimate of the number of items in the set.

See the [complete list of hyperloglog commands](https://redis.io/commands/?group=hyperloglog).

## Learn more

* [Redis HyperLogLog Explained](https://www.youtube.com/watch?v=MunL8nnwscQ) shows you how to use the Redis hyperloglog to build a traffic heat map.

