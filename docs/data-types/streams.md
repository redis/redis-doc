---
title: "Redis Streams"
linkTitle: "Streams"
weight: 60
description: >
    Introduction to Redis streams
---

A Redis stream is a data structure that acts like an append-only log.
You can use streams to record and simultaneously syndicate events in real time.
Examples of Redis stream use cases include:

* Event sourcing (e.g., tracking user actions, clicks, etc.)
* Sensor monitoring (e.g., readings from devices in the field) 
* Notifications (e.g., storing a record of each user's notifications in a separate stream)

Redis generates a unique ID for each stream entry.
You can use these IDs to retrieve their associated entries later or to read and process all subsequent entries in the stream.

Redis streams support several trimming strategies (to prevent streams from growing unbounded) and more than one consumption strategy (see `XREAD`, `XREADGROUP`, and `XRANGE`).

## Examples

* Add several temperature readings to a stream
```
> XADD temperatures:us-ny:10007 * temp_f 87.2 pressure 29.69 humidity 46
"1658354918398-0"
> XADD temperatures:us-ny:10007 * temp_f 83.1 pressure 29.21 humidity 46.5
"1658354934941-0"
> XADD temperatures:us-ny:10007 * temp_f 81.9 pressure 28.37 humidity 43.7
"1658354957524-0"
```

* Read the first two stream entries starting at ID `1658354934941-0`:
```
> XRANGE temperatures:us-ny:10007 1658354934941-0 + COUNT 2
1) 1) "1658354934941-0"
   2) 1) "temp_f"
      2) "83.1"
      3) "pressure"
      4) "29.21"
      5) "humidity"
      6) "46.5"
2) 1) "1658354957524-0"
   2) 1) "temp_f"
      2) "81.9"
      3) "pressure"
      4) "28.37"
      5) "humidity"
      6) "43.7"
``` 

* Read up to 100 new stream entries, starting at the end of the stream, and block for up to 300 ms if no entries are being written:
```
> XREAD COUNT 100 BLOCK 300 STREAMS temperatures:us-ny:10007 $
(nil)
```

## Basic commands
* `XADD` adds a new entry to a stream.
* `XREAD` reads one or more entries, starting at a given position and moving forward in time.
* `XRANGE` returns a range of entries between two supplied entry IDs.
* `XLEN` returns the length of a stream.
 
See the [complete list of stream commands](https://redis.io/commands/?group=stream).

## Performance

Adding an entry to a stream is O(1).
Accessing any single entry is O(n), where _n_ is the length of the ID.
Since stream IDs are typically short and of a fixed length, this effectively reduces to a constant time lookup.
For details on why, note that streams are implemented as [radix trees](https://en.wikipedia.org/wiki/Radix_tree).

Simply put, Redis streams provide highly efficient inserts and reads.
See each command's time complexity for the details.

## Learn more

* The [Redis Streams Tutorial](/docs/data-types/streams-tutorial) explains Redis streams with many examples.
* [Redis Streams Explained](https://www.youtube.com/watch?v=Z8qcpXyMAiA) is an entertaining introduction to streams in Redis.
* [Redis University's RU102](https://university.redis.com/courses/ru102/) is a free, online course dedicated to Redis Streams.
