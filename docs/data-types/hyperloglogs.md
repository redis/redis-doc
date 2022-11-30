---
title: "Redis HyperLogLog"
linkTitle: "HyperLogLog"
weight: 90
description: >
    Introduction to the Redis HyperLogLog data type
---

HyperLogLog is a data structure that estimates the cardinality of a set. As a probabilistic data structure, HyperLogLog trades perfect accuracy for efficient space utilization.

The Redis HyperLogLog implementation uses up to 12 KB and provides a standard error of 0.81%.

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

* [Redis new data structure: the HyperLogLog](http://antirez.com/news/75) has a lot of details about the data structure and its implementation in Redis.
* [Redis HyperLogLog Explained](https://www.youtube.com/watch?v=MunL8nnwscQ) shows you how to use Redis HyperLogLog data structures to build a traffic heat map.
