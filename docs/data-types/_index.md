---
title: "Redis data types"
linkTitle: "Data types"
description: Overview of the many data types supported by Redis
weight: 2
aliases:
    - /docs/manual/data-types
    - /topics/data-types
---

Redis is a data structure server. At its core, Redis provides a collection of native data types that help you solve a wide variety of problems, from [caching](/docs/manual/client-side-caching/) to [queuing](/docs/data-types/lists/) to [event processing](/docs/data-types/stream/). Below is a short description of each data type, with links to broader overviews and command references.

If you'd like a rich tutorial, see the classic [Redis data types tutorial](/docs/data-types/tutorial/).

## Core

### Strings 

[Redis strings](/docs/data-types/strings) are the most basic Redis data type, representing a sequence of bytes.

* See an [overview of Redis strings](/docs/data-types/strings/)
* View the [Redis string command reference](/commands/?group=string)

### Lists

[Redis lists](/docs/data-types/lists) are lists of strings, sorted by insertion order.

* See an [overview of Redis lists](/docs/data-types/lists/)
* View the [Redis list command reference](/commands/?group=list)

### Sets

[Redis sets](/docs/data-types/sets). are unordered collections of unique strings that act a lot like the sets from your favorite programming language (e.g., [Java HashSet](https://docs.oracle.com/javase/7/docs/api/java/util/HashSet.html)s, [Python sets](https://docs.python.org/3.10/library/stdtypes.html#set-types-set-frozenset), etc.). You can add remove, and test for existence O(1) time (i.e., regardless of the number of set elements).

* See an [overview of Redis sets](/docs/data-types/sets/)
* View the [Redis set command reference](/commands/?group=set)

### Hashes

[Redis hashes](/docs/data-types/hashes) are record types modeled as a collections of field-value pairs. As such, Redis Hashes resemble [Python dictionaries](https://docs.python.org/3/tutorial/datastructures.html#dictionaries), [Java HashMaps](https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html), and [Ruby hashes](https://ruby-doc.org/core-3.1.2/Hash.html).

* See an [overview of Redis hashes](/docs/data-types/hashes/)
* View the [Redis hashes command reference](/commands/?group=hash)

### Sorted Sets

[Redis sorted sets](/docs/data-types/sorted-sets) are collections of unique strings that maintain order by each string's associated score.

* See an [overview of Redis sorted sets](/docs/data-types/sorted-sets)
* View the [Redis sorted set command reference](/commands/?group=sorted-set)

### Streams

A [Redis stream](/docs/data-types/stream) is a data structure that acts like an append-only log. Streams are useful for recording events in the order they occur and then syndicating them for processing.

* See an [overview of Redis Streams](/docs/data-types/stream)
* View the [Redis Streams command reference](/commands/?group=streams)
* Read the [Redis Streams tutorial](/docs/data-types/streams-tutorial)

### Geospatial indexes

[Redis geospatial indexes](/docs/data-types/geospatial) are useful for finding locations within a given geographic radius.

* See an [overview of Redis geospatial indexes](/docs/data-types/geospatial/)
* View the [Redis geospatial indexes command reference](/commands/?group=geo)

### Bitmaps

[Redis bitmaps](/docs/data-types/bitmaps/) let you perform bitwise operations on strings.

* See an [overview of Redis bitmaps](/docs/data-types/bitmaps/)
* View the [Redis bitmap command reference](/commands/?group=bitmap)

### Hyperloglogs

[Redis hyperloglogs](/docs/data-types/hyperloglogs) provide probabilistic estimates of the cardiality (i.e., number of elements) of large sets.

* [Overview of Redis hyperloglogs](/docs/data-types/hyperloglogs)
* View the [Redis hyperloglog command reference](/commands/?group=bitmap)

## Extensions

If you to extend the features provided by the included data types, you have several options:

1. Consider writing your own custom, [server-side functions in Lua](/docs/manual/programmability/).
2. Use the [JSON](/docs/stack/json/), [querying](/docs/stack/search/), [time series](/docs/stack/timeseries/), and other capabilities provided by [Redis Stack](/docs/stack/).
3. Write your own Redis extension using the [modules API](/docs/reference/modules/), or check out the many [community-supported modules](/docs/modules/).
