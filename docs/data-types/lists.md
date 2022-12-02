---
title: "Redis lists"
linkTitle: "Lists"
weight: 20
description: >
    Introduction to Redis lists
---

Redis lists are linked lists of string values.
Redis lists are frequently used to:

* Implement stacks and queues.
* Build queue management for background worker systems.

## Examples

* Treat a list like a queue (first in, first out):
```
> LPUSH work:queue:ids 101
(integer) 1
> LPUSH work:queue:ids 237
(integer) 2
> RPOP work:queue:ids
"101"
> RPOP work:queue:ids
"237"
```

* Treat a list like a stack (first in, last out):
```
> LPUSH work:queue:ids 101
(integer) 1
> LPUSH work:queue:ids 237
(integer) 2
> LPOP work:queue:ids
"237"
> LPOP work:queue:ids
"101"
```

* Check the length of a list:
```
> LLEN work:queue:ids
(integer) 0
```

* Atomically pop an element from one list and push to another:
```
> LPUSH board:todo:ids 101
(integer) 1
> LPUSH board:todo:ids 273
(integer) 2
> LMOVE board:todo:ids board:in-progress:ids LEFT LEFT
"273"
> LRANGE board:todo:ids 0 -1
1) "101"
> LRANGE board:in-progress:ids 0 -1
1) "273"
```

* To create a capped list that never grows beyond 100 elements, you can call `LTRIM` after each call to `LPUSH`:
```
> LPUSH notifications:user:1 "You've got mail!"
(integer) 1
> LTRIM notifications:user:1 0 99
OK
> LPUSH notifications:user:1 "Your package will be delivered at 12:01 today."
(integer) 2
> LTRIM notifications:user:1 0 99
OK
```

## Limits

The max length of a Redis list is 2^32 - 1 (4,294,967,295) elements.

## Basic commands

* `LPUSH` adds a new element to the head of a list; `RPUSH` adds to the tail.
* `LPOP` removes and returns an element from the head of a list; `RPOP` does the same but from the tails of a list. 
* `LLEN` returns the length of a list.
* `LMOVE` atomically moves elements from one list to another.
* `LTRIM` reduces a list to the specified range of elements.

### Blocking commands

Lists support several blocking commands.
For example:

* `BLPOP` removes and returns an element from the head of a list.
  If the list is empty, the command blocks until an element becomes available or until the specified timeout is reached.
* `BLMOVE` atomically moves elements from a source list to a target list.
  If the source list is empty, the command will block until a new element becomes available.

See the [complete series of list commands](https://redis.io/commands/?group=list).

## Performance

List operations that access its head or tail are O(1), which means they're highly efficient.
However, commands that manipulate elements within a list are usually O(n).
Examples of these include `LINDEX`, `LINSERT`, and `LSET`.
Exercise caution when running these commands, mainly when operating on large lists.

## Alternatives

Consider [Redis streams](/docs/data-types/streams) as an alternative to lists when you need to store and process an indeterminate series of events.

## Learn more

* [Redis Lists Explained](https://www.youtube.com/watch?v=PB5SeOkkxQc) is a short, comprehensive video explainer on Redis lists.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis lists in detail.
