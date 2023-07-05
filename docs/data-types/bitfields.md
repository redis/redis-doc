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

Suppose you're keeping track of activity in an online game.
You want to maintain two crucial metrics for each player: the total amount of gold and the number of monsters slain.
Because your game is highly addictive, these counters should be at least 32 bits wide.

You can represent these counters with one bitfield per player.

* New players start the tutorial with 1000 gold (counter in offset 0).
```
> BITFIELD player:1:stats SET u32 #0 1000
1) (integer) 0
```

* After killing the goblin holding the prince captive, add the 50 gold earned and increment the "slain" counter (offset 1).
```
> BITFIELD player:1:stats INCRBY u32 #0 50 INCRBY u32 #1 1
1) (integer) 1050
2) (integer) 1
```

* Pay the blacksmith 999 gold to buy a legendary rusty dagger.
```
> BITFIELD player:1:stats INCRBY u32 #0 -999
1) (integer) 51
```

* Read the player's stats:
```
> BITFIELD player:1:stats GET u32 #0 GET u32 #1
1) (integer) 51
2) (integer) 1
```


## Performance

`BITFIELD` is O(n), where _n_ is the number of counters accessed.
