---
title: "Redis HyperLogLog"
linkTitle: "HyperLogLog"
weight: 90
description: >
    Introduction to the Redis HyperLogLog data type
---

HyperLogLog (HLL) is a probabilistic data structure, a.k.a a sketch.
Sketches trade perfect accuracy for efficient space utilization.
Rather than storing the data, these structures maintain only summaries.

The HyperLogLog's purpose is to estimate the cardinality of a set, i.e., count unique things.
The Redis HLL implementation takes up to 12KB to store and has a standard error of 0.81%.

## Examples

* Add some items to the HyperLogLog:
```
> PFADD members 123
(integer) 1
> PFADD members 500
(integer) 1
> PFADD members 12
(integer) 1
```

* Estimate the number of members in the set:
```
> PFCOUNT members
(integer) 3
```

## Basic commands

* `PFADD` adds an item to a HyperLogLog.
* `PFCOUNT` returns an estimate of the number of items in the set.
* `PFMERGE` combines two or more HyperLogLogs into one.

See the [complete list of HyperLogLog commands](https://redis.io/commands/?group=hyperloglog).

## Performance

Writing (`PFADD`) to and reading from (`PFCOUNT`) the HyperLogLog is done in constant time and space.
Merging HLLs is O(n), where _n_ is the number of sketches.

## Limits

The HyperLogLog can estimate the cardinality of sets with up to 18,446,744,073,709,551,616 (2^64) members.

## Learn more

* [Redis new data structure: the HyperLogLog](https://antirez.com/news/75) has a lot of details about the data structure and its implementation in Redis.
* [Redis HyperLogLog Explained](https://www.youtube.com/watch?v=MunL8nnwscQ) shows you how to use Redis HyperLogLog data structures to build a traffic heat map.
