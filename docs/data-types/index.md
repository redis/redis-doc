---
title: "Redis data types"
linkTitle: "Data types"
description: Overview of the many data types supported by Redis
weight: 1
aliases:
    - /topics/data-types
    - /docs/manual/data-types
---

Redis is a data structure server. At its core, Redis provides a collection of native data types that help you solve a wide variety of problems, from caching to queuing to event processing. Below is a short description of each data type, with links to broader overviews and command references.

If you'd like a rich tutorial, see the classic [Redis data types tutorial](/docs/manual/data-types/data-types-tutorial/).

## Available data types

### Strings 

[Redis strings](/docs/manual/data-types/strings) are the most basic Redis data type, representing a sequence of bytes.

* See an [overview of Redis strings](/docs/manual/data-types/strings/)
* View the [Redis string command reference](/commands/?group=string)

### Lists

[Redis lists](/docs/manual/data-types/lists) are lists of strings, sorted by insertion order.

* See an [overview of Redis lists](/docs/manual/data-types/lists/)
* View the [Redis list command reference](/commands/?group=list)

### Sets

[Redis sets](/docs/manual/data-types/sets). are unordered collections of unique strings that act a lot like the sets from your favorite programming language (e.g., [Java HashSet](https://docs.oracle.com/javase/7/docs/api/java/util/HashSet.html)s, [Python sets](https://docs.python.org/3.10/library/stdtypes.html#set-types-set-frozenset), etc.). You can add remove, and test for existence O(1) time (i.e., regardless of the number of set elements).

* See an [overview of Redis sets](/docs/manual/data-types/sets/)
* View the [Redis set command reference](/commands/?group=set)

### Hashes

[Redis hashes](/docs/manual/data-types/hashes) are record types modeled as a collections of field-value pairs. As such, Redis Hashes resemble [Python dictionaries](https://docs.python.org/3/tutorial/datastructures.html#dictionaries), [Java HashMaps](https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html), and [Ruby hashes](https://ruby-doc.org/core-3.1.2/Hash.html).

* See an [overview of Redis hashes](/docs/manual/data-types/hashes/)
* View the [Redis hashes command reference](/commands/?group=hash)

### Sorted Sets

[Redis sorted sets](/docs/manual/data-types/sorted-sets) are collections of unique strings that maintain order by each string's associated score.

* See an [overview of Redis sorted sets](/docs/manual/data-types/sorted-sets)
* View the [Redis sorted set command reference](/commands/?group=sorted-set)

### Streams

A [Redis stream](/docs/manual/data-types/stream) is a data structure that acts like an append-only log. Streams are useful for recording events in the order they occur and then syndicating them for processing.

* See an [overview of Redis Streams](/docs/manual/data-types/stream)
* View the [Redis Streams command reference](/commands/?group=streams)
* Read the [Redis Streams tutorial](/docs/manual/data-types/streams-tutorial)

### Geospatial indexes

[Redis geospatial indexes](/docs/manual/data-types/geospatial) are useful for finding locations within a given geographic radius.

* See an [overview of Redis geospatial indexes](/docs/manual/data-types/geospatial/)
* View the [Redis geospatial indexes reference](/commands/?group=geo)

### Bitmaps

[Redis bitmaps](/docs/manual/data-types/bitmaps/) let you perform bitwise operations on strings.

* See an [overview of Redis bitmaps](/docs/manual/data-types/bitmaps/)
* View the [Redis bitmap reference](/commands/?group=bitmap)

### Hyperloglogs

[Redis hyperloglogs](/docs/manual/data-types/hyperloglogs) provide probabilistic estimates of the cardiality (i.e., number of elements) of large sets.

* [Overview of Redis hyperloglogs](/docs/manual/data-types/hyperloglogs)
* View the [Redis bitmap reference](/commands/?group=bitmap)

## Extending Redis data types

If you need functionality not provided by the included data types, you have several options:

1. Consider writing your own custom, [server-side functions in Lua](/docs/manual/programmability/).
2. Use the [JSON](/docs/stack/json/), [querying](/docs/stack/search/), [time series](/docs/stack/timeseries/), and other capabilities provided by [Redis Stack](/docs/stack/).
3. Write your own Redis extension using the [modules API](https://redis.io/docs/reference/modules/), or check out the many [community-supported modules](/docs/modules/).
