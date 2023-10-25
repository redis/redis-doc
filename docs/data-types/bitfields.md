---
title: "Redis bitfields"
linkTitle: "Bitfields"
weight: 130
description: >
    Introduction to Redis bitfields
---

Redis bitfields let you set, increment, and get integer values of arbitrary bit length.
For example, you can operate on anything from unsigned 1-bit integers to signed 63-bit integers.

These values are stored using binary-encoded Redis strings.
Bitfields support atomic read, write and increment operations, making them a good choice for managing counters and similar numerical values.


## Basic commands

* `BITFIELD` atomically sets, increments and reads one or more values.
* `BITFIELD_RO` is a read-only variant of `BITFIELD`.


## Examples

## Example

Suppose you want to maintain two metrics for various bicycles: the current price and the number of owners over time. You can represent these counters with a 32-bit wide bitfield per for each bike.

* Bike 1 initially costs 1,000 (counter in offset 0) and has never had an owner. After being sold, it's now considered used and the price instantly drops to reflect its new condition, and it now has an owner (offset 1). After quite some time, the bike becomes a classic. The original owner sells it for a profit, so the price goes up and the number of owners does as well.Finally, you can look at the bike's current price and number of owners.

{{< clients-example bitfield_tutorial bf >}}
> BITFIELD bike:1:stats SET u32 #0 1000
1) (integer) 0
> BITFIELD bike:1:stats INCRBY u32 #0 -50 INCRBY u32 #1 1
1) (integer) 950
2) (integer) 1
> BITFIELD bike:1:stats INCRBY u32 #0 500 INCRBY u32 #1 1
1) (integer) 1450
2) (integer) 2
> BITFIELD bike:1:stats GET u32 #0 GET u32 #1
1) (integer) 1450
2) (integer) 2
{{< /clients-example >}}


## Performance

`BITFIELD` is O(n), where _n_ is the number of counters accessed.
