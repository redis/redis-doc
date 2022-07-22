---
title: "Redis Strings"
linkTitle: "Lists"
weight: 3
description: >
    Introduction to Redis Lists
---

Redis lists are lists of string values. Redis lists are frequenty used to:

* implement stacks and queues.
* build queue management for background worker systems.

## Examples

* Treat a list like a queue (first in, first out):
```
redis:6379> LPUSH work:queue:ids 101
(integer) 1
redis:6379> LPUSH work:queue:ids 237
(integer) 2
redis:6379> RPOP work:queue:ids
"101"
redis:6379> RPOP work:queue:ids
"237"
```

* Treat a list like a stack (first in, last out):
```
redis:6379> LPUSH work:queue:ids 101
(integer) 1
redis:6379> LPUSH work:queue:ids 237
(integer) 2
redis:6379> LPOP work:queue:ids
"237"
redis:6379> LPOP work:queue:ids
"101"
```

* Check the length of a list:
```
redis:6379> LLEN work:queue:ids
(integer) 0
```

* Atomically pop an element from one list and push to another:
```
redis:6379> LPUSH board:todo:ids 101
(integer) 1
redis:6379> LPUSH board:todo:ids 273
(integer) 2
redis:6379> LMOVE board:todo:ids board:in-progress:ids LEFT LEFT
"273"
redis:6379> LRANGE board:todo:ids 0 -1
1) "101"
redis:6379> LRANGE board:in-progress:ids 0 -1
1) "273"
```

* To create a capped list that never grows beyond 100 elements, you can call [LTRIM] after each call to [LPUSH]:
```
redis:6379> LPUSH notifications:user:1 "You've got mail!"
(integer) 1
redis:6379> LTRIM notifications:user:1 0 99
OK
redis:6379> LPUSH notifications:user:1 "Your package will be delivered at 12:01 today."
(integer) 2
redis:6379> LTRIM notifications:user:1 0 99
OK
```

## Limits

The max length of a Redis list is 2^32 - 1 (4,294,967,295) elements.

## Commands

### Basic commands

* [LPUSH](/commands/lpush) adds a new element on the head of a list; [RPUSH](/commands/rpush) adds to the tail. 
* [LPOP](/commands/lpush) removes and returns an element from the head of a list; [RPOP](/commands/rpush) does the same but from the tails of a list. 
* [LLEN](/commands/llen) returns the length of a list.
* [LMOVE](/commands/lmove) atomically moves an elements from one list to another.
* [LTRIM](/commands/ltrim) reduces a list to the specified range of elements.

### Blocking commands

Lists supports several blocking commands. For example:

* [BLPOP](/commands/blpush) removes and returns an element from the head of a list. If the list is empty, the command blocks until an element becomes available or until the specified timeout is reached.
* [BLMOVE](/commands/blmove) atomically moves an elements from a source list to a target list. If the source list is empty, the the command will block until a elements becomes available.

See the [complete series of list commands](https://redis.io/commands/?group=list).

## Performance

Most list operations are O(1), which means they're highly efficient. However, commands that manipulate elements within a list are usually O(n). Examples of these include [LINDEX](/commands/lindex), [LINSERT](/commands/linsert), and [LSET](/commmands/lset). Exercise some are when running these commands, especially when operating on large lists.

## Alternatives

Consider [Redis streams](/docs/data-types/streams) as an alternative to lists when you need to store and process an indeterminate series of events.

## Learn more

* [Redis Lists Explained](https://www.youtube.com/watch?v=PB5SeOkkxQc) is a short, comprehensive video explainer on Redis lists.
* [Redis University's RU101](https://university.redis.com/courses/ru101/) covers Redis lists in detail.
