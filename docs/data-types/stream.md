---
title: "Redis Stream Type"
linkTitle: "Streams"
weight: 6
description: >
    Introduction to Redis Streams
---

A Redis stream is a data structure that acts like an append-only log. You can use streams to record and simultaneously syndicate events in real time. Examples of Redis stream use cases include:

* Event sourcing (e.g., tracking user actions, clicks, etc.)
* Sensor monitoring (e.g., readings from devices in the field) 
* Notifications (e.g., storing a record of each user's notifications in a separate stream)

Redis generates a unique ID for each stream entry. You can use these IDs to later retrieve their associated entries or to read and process all subsequent entries in the stream.

Redis streams support several trimming strategies (to prevent streams from growing unbouded) and more than one consumption strategy (see [XREAD](/commands/xread), [XREADGROUP](/commands/xreadgroup), and [XRANGE](/commands/xrange)).

## Examples

* Add several temperature readings to a stream
```
redis:6379> XADD temperatures:us-ny:10007 * temp_f 87.2 pressure 29.69 humidity 46
"1658354918398-0"
redis:6379> XADD temperatures:us-ny:10007 * temp_f 83.1 pressure 29.21 humidity 46.5
"1658354934941-0"
redis:6379> XADD temperatures:us-ny:10007 * temp_f 81.9 pressure 28.37 humidity 43.7
"1658354957524-0"
```

* Read the first two stream entries starting at ID `1658354934941-0`:
```
redis:6379> XRANGE temperatures:us-ny:10007 1658354934941-0 + COUNT 2
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
redis:6379> XREAD COUNT 100 BLOCK 300 STREAMS tempertures:us-ny:10007 $
(nil)
```

## Commands

* [XADD](/commands/xadd)
* [XREAD](/commands/xread)
* [XRANGE](/commands/xrange) 
* [XLEN](/commands/xlen)
 
See the [complete list of stream commands](https://redis.io/commands/?group=stream).

## Performance

Adding an entry to a streams is O(1). Accessing any single entry is O(n), where n is the length of the ID. Since stream IDs are typically short and of a fixed length, this effectively reduces to a constant time lookup. For details on why, note that streams are implented as [radix trees](https://en.wikipedia.org/wiki/Radix_tree).

Simply put, Redis streams provide highly efficient inserts and reads. See each command's time complexity for the details.

## Learn more

* The [Redis Streams Tutorial](/docs/manual/data-types/streams-tutorial.md) explains Redis streams with many examples
* [Redis Streams Explained](https://www.youtube.com/watch?v=Z8qcpXyMAiA) is an entertaining introduction to sorted sets in Redis.
* [Redis University's RU102](https://university.redis.com/courses/ru101/) is a free, online course dedicated to Redis Streams.
