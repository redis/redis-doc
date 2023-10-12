---
title: "Redis bitmaps"
linkTitle: "Bitmaps"
weight: 120
description: >
    Introduction to Redis bitmaps
---

Bitmaps are not an actual data type, but a set of bit-oriented operations
defined on the String type which is treated like a bit vector.
Since strings are binary safe blobs and their maximum length is 512 MB,
they are suitable to set up to 2^32 different bits.

You can perform bitwise operations on one or more strings.
Some examples of bitmap use cases include:

* Efficient set representations for cases where the members of a set correspond to the integers 0-N.
* Object permissions, where each bit represents a particular permission, similar to the way that file systems store permissions.

## Basic commands

* `SETBIT` sets a bit at the provided offset to 0 or 1.
* `GETBIT` returns the value of a bit at a given offset.

See the [complete list of bitmap commands](https://redis.io/commands/?group=bitmap).


## Examples

Suppose you have 1000 cyclists racing through the country-side, labeled 0-999.
You want to quickly determine whether a given rider has pinged the server within the hour. 

You can represent this scenario using a bitmap whose key references the current hour.

* Rider 123 pings the server on January 1, 2024 within the 00:00 hour. We can then confirm that rider 123 pinged the server. We can then check to see if rider 456 has pinged the server for that same hour.

{{< clients-example bitmap_tutorial ping >}}
> SETBIT pings:2024-01-01-00:00 123 1
(integer) 0
> GETBIT pings:2024-01-01-00:00 123
1
> GETBIT pings:2024-01-01-00:00 456
0
{{< /clients-examples >}}


## Bit Operations

Bit operations are divided into two groups: constant-time single bit
operations, like setting a bit to 1 or 0, or getting its value, and
operations on groups of bits, for example counting the number of set
bits in a given range of bits (e.g., population counting).

One of the biggest advantages of bitmaps is that they often provide
extreme space savings when storing information. For example in a system
where different users are represented by incremental user IDs, it is possible
to remember a single bit information (for example, knowing whether
a user wants to receive a newsletter) of 4 billion users using just 512 MB of memory.

The `SETBIT` command takes as its first argument the bit number, and as its second
argument the value to set the bit to, which is 1 or 0. The command
automatically enlarges the string if the addressed bit is outside the
current string length.

`GETBIT` just returns the value of the bit at the specified index.
Out of range bits (addressing a bit that is outside the length of the string
stored into the target key) are always considered to be zero.

There are three commands operating on group of bits:

1. `BITOP` performs bit-wise operations between different strings. The provided operations are AND, OR, XOR and NOT.
2. `BITCOUNT` performs population counting, reporting the number of bits set to 1.
3. `BITPOS` finds the first bit having the specified value of 0 or 1.

Both `BITPOS` and `BITCOUNT` are able to operate with byte ranges of the
string, instead of running for the whole length of the string. We can trivially see the number of bits that have been set in a bitmap.

{{< clients-example bitmap_tutorial bitcount >}}
> BITCOUNT pings:2024-01-01-00:00
(integer) 1
{{< /clients-examples >}}

For example imagine you want to know the longest streak of daily visits of
your web site users. You start counting days starting from zero, that is the
day you made your web site public, and set a bit with `SETBIT` every time
the user visits the web site. As a bit index you simply take the current unix
time, subtract the initial offset, and divide by the number of seconds in a day
(normally, 3600\*24).

This way for each user you have a small string containing the visit
information for each day. With `BITCOUNT` it is possible to easily get
the number of days a given user visited the web site, while with
a few `BITPOS` calls, or simply fetching and analyzing the bitmap client-side,
it is possible to easily compute the longest streak.

Bitmaps are trivial to split into multiple keys, for example for
the sake of sharding the data set and because in general it is better to
avoid working with huge keys. To split a bitmap across different keys
instead of setting all the bits into a key, a trivial strategy is just
to store M bits per key and obtain the key name with `bit-number/M` and
the Nth bit to address inside the key with `bit-number MOD M`.



## Performance

`SETBIT` and `GETBIT` are O(1).
`BITOP` is O(n), where _n_ is the length of the longest string in the comparison.

## Learn more

* [Redis Bitmaps Explained](https://www.youtube.com/watch?v=oj8LdJQjhJo) teaches you how to use bitmaps for map exploration in an online game. 
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis bitmaps in detail.
