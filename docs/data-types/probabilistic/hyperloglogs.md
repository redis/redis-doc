---
title: "HyperLogLog"
linkTitle: "HyperLogLog"
weight: 1
description: >
    HyperLogLog is a probabilistic data structure that estimates the cardinality of a set.
aliases:
    - /docs/data-types/hyperloglogs/
---

HyperLogLog is a probabilistic data structure that estimates the cardinality of a set. As a probabilistic data structure, HyperLogLog trades perfect accuracy for efficient space utilization.

The Redis HyperLogLog implementation uses up to 12 KB and provides a standard error of 0.81%.

Counting unique items usually requires an amount of memory
proportional to the number of items you want to count, because you need
to remember the elements you have already seen in the past in order to avoid
counting them multiple times. However, a set of algorithms exist that trade 
memory for precision: they return an estimated measure with a standard error, 
which, in the case of the Redis implementation for HyperLogLog, is less than 1%.
The magic of this algorithm is that you no longer need to use an amount of memory
proportional to the number of items counted, and instead can use a
constant amount of memory; 12k bytes in the worst case, or a lot less if your
HyperLogLog (We'll just call them HLL from now) has seen very few elements.

HLLs in Redis, while technically a different data structure, are encoded
as a Redis string, so you can call `GET` to serialize a HLL, and `SET`
to deserialize it back to the server.

Conceptually the HLL API is like using Sets to do the same task. You would
`SADD` every observed element into a set, and would use `SCARD` to check the
number of elements inside the set, which are unique since `SADD` will not
re-add an existing element.

While you don't really *add items* into an HLL, because the data structure
only contains a state that does not include actual elements, the API is the
same:

* Every time you see a new element, you add it to the count with `PFADD`.
* Every time you want to retrieve the current approximation of the unique elements *added* with `PFADD` so far, you use the `PFCOUNT`. Two different HLLs can be merged into a single one using `PFMERGE` and since HLLs approximate unique elements, the result of the merge is the approximated number of unique elements in the union of the source HLLs.

{{< clients-example hll_tutorial pfadd >}}

{{< clients-example hll_tutorial pfadd >}}
> PFADD bikes Hyperion Deimos Phoebe Quaoar
(integer) 1
> PFCOUNT bikes
(integer) 4
> PFADD commuter_bikes Salacia Mimas Quaoar
(integer) 1
> PFMERGE all_bikes bikes commuter_bikes
OK
> PFCOUNT all_bikes
(integer) 6
{{< /clients-example >}}

Some examples of use cases for this data structure is counting unique queries
performed by users in a search form every day, number of unique visitors to a web page and other similar cases.

Redis is also able to perform the union of HLLs, please check the
[full documentation](/commands#hyperloglog) for more information.

## Use cases

**Anonymous unique visits of a web page (SaaS, analytics tools)** 

This application answers these questions: 

- How many unique visits has this page had on this day? 
- How many unique users have played this song? 
- How many unique users have viewed this video? 

{{% alert title="Note" color="warning" %}}
 
Storing the IP address or any other kind of personal identifier is against the law in some countries, which makes it impossible to get unique visitor statistics on your website.

{{% /alert %}}

One HyperLogLog is created per page (video/song) per period, and every IP/identifier is added to it on every visit.

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

