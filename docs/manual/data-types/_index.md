---
title: "Redis data types"
linkTitle: "Data types"
description: Overview of the many data types supported by Redis
weight: 1
aliases:
    - /topics/data-types
---

Redis provides a collection of native data types that help you solve a wide variety of problems, from caching to queuing to event processing.

## Strings

Redis strings are the most basic Redis data type, representing a sequence of bytes.

* [Overview of Redis strings](/docs/manual/data-types/strings).

## Lists

Redis lists are lists of strings, sorted by insertion order.

* [Overview of Redis lists](/docs/manual/data-types/lists).

## Sets

Redis sets are unordered collections of unique strings that act a lot like the sets from your favorite programming language (e.g., [Java HashSet](https://docs.oracle.com/javase/7/docs/api/java/util/HashSet.html)s, [Python sets](https://docs.python.org/3.10/library/stdtypes.html#set-types-set-frozenset), etc.). You can add remove, and test for existence O(1) time (i.e., regardless of the number of set elements).

* [Overview of Redis sets](/docs/manual/data-types/sets).

## Hashes

Redis hashes are record types modeled as a collections of field-value pairs. As such, Redis Hashes resemble [Python dictionaries](https://docs.python.org/3/tutorial/datastructures.html#dictionaries), [Java HashMaps](https://docs.oracle.com/javase/8/docs/api/java/util/HashMap.html), and [Ruby hashes](https://ruby-doc.org/core-3.1.2/Hash.html).

[Overview of Redis hashes](/docs/manual/data-types/hashes).

## Sorted Sets

Redis sorted sets are collections of unique strings that maintain order by each string's associated score.

* [Overview of Redis sorted sets](/docs/manual/data-types/sorted-sets).

## Streams

A Redis stream is a data structure that acts like an append-only log. Streams are useful for recording events in the order they occur and then syndicating them for processing.

* [Overview of Redis Streams](/docs/manual/data-types/stream).
* [The Redis Streams tutorial](/docs/manual/data-types/streams-tutorial).

## Geospatial indexes

Redis geospatial indexes are useful for finding locations within a given geographic radius.

* [Overview of Redis geospatial indexes](/docs/manual/data-types/geospatial).

## Bitmaps

Redis bitmaps let you perform bitwise operations on strings.

* [Overview of Redis bitmaps](/docs/manual/data-types/bitmaps).

## Hyperloglogs

Redis hyperloglogs provided probabilistic estimates of the cardiality (i.e., number of elements) of large sets.

* [Overview of Redis hyperloglogs](/docs/manual/data-types/hyperloglogs).
