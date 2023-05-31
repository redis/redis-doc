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

### What are Lists?
To explain the List data type it's better to start with a little bit of theory,
as the term *List* is often used in an improper way by information technology
folks. For instance "Python Lists" are not what the name may suggest (Linked
Lists), but rather Arrays (the same data type is called Array in
Ruby actually).

From a very general point of view a List is just a sequence of ordered
elements: 10,20,1,2,3 is a list. But the properties of a List implemented using
an Array are very different from the properties of a List implemented using a
*Linked List*.

Redis lists are implemented via Linked Lists. This means that even if you have
millions of elements inside a list, the operation of adding a new element in
the head or in the tail of the list is performed *in constant time*. The speed of adding a
new element with the [`LPUSH`](/commands/lpush) command to the head of a list with ten
elements is the same as adding an element to the head of list with 10
million elements.

What's the downside? Accessing an element *by index* is very fast in lists
implemented with an Array (constant time indexed access) and not so fast in
lists implemented by linked lists (where the operation requires an amount of
work proportional to the index of the accessed element).

Redis Lists are implemented with linked lists because for a database system it
is crucial to be able to add elements to a very long list in a very fast way.
Another strong advantage, as you'll see in a moment, is that Redis Lists can be
taken at constant length in constant time.

When fast access to the middle of a large collection of elements is important,
there is a different data structure that can be used, called sorted sets.
Sorted sets are covered in the [Sorted sets](/docs/data-types/sorted-sets) tutorial page.

### First steps with Redis Lists

The [`LPUSH`](/commands/lpush) command adds a new element into a list, on the
left (at the head), while the [`RPUSH`](/commands/rpush) command adds a new
element into a list, on the right (at the tail). Finally the
[`LRANGE`](/commands/lrange) command extracts ranges of elements from lists:

    > rpush mylist A
    (integer) 1
    > rpush mylist B
    (integer) 2
    > lpush mylist first
    (integer) 3
    > lrange mylist 0 -1
    1) "first"
    2) "A"
    3) "B"

Note that [LRANGE](/commands/lrange) takes two indexes, the first and the last
element of the range to return. Both the indexes can be negative, telling Redis
to start counting from the end: so -1 is the last element, -2 is the
penultimate element of the list, and so forth.

As you can see [`RPUSH`](/commands/rpush) appended the elements on the right of the list, while
the final [`LPUSH`](/commands/lpush) appended the element on the left.

Both commands are *variadic commands*, meaning that you are free to push
multiple elements into a list in a single call:

    > rpush mylist 1 2 3 4 5 "foo bar"
    (integer) 9
    > lrange mylist 0 -1
    1) "first"
    2) "A"
    3) "B"
    4) "1"
    5) "2"
    6) "3"
    7) "4"
    8) "5"
    9) "foo bar"

An important operation defined on Redis lists is the ability to *pop elements*.
Popping elements is the operation of both retrieving the element from the list,
and eliminating it from the list, at the same time. You can pop elements
from left and right, similarly to how you can push elements in both sides
of the list:

    > rpush mylist a b c
    (integer) 3
    > rpop mylist
    "c"
    > rpop mylist
    "b"
    > rpop mylist
    "a"

We added three elements and popped three elements, so at the end of this
sequence of commands the list is empty and there are no more elements to
pop. If we try to pop yet another element, this is the result we get:

    > rpop mylist
    (nil)

Redis returned a NULL value to signal that there are no elements in the
list.

### Common use cases for lists

Lists are useful for a number of tasks, two very representative use cases
are the following:

* Remember the latest updates posted by users into a social network.
* Communication between processes, using a consumer-producer pattern where the producer pushes items into a list, and a consumer (usually a *worker*) consumes those items and executes actions. Redis has special list commands to make this use case both more reliable and efficient.

For example both the popular Ruby libraries [resque](https://github.com/resque/resque) and
[sidekiq](https://github.com/mperham/sidekiq) use Redis lists under the hood in order to
implement background jobs.

The popular Twitter social network [takes the latest tweets](http://www.infoq.com/presentations/Real-Time-Delivery-Twitter)
posted by users into Redis lists.

To describe a common use case step by step, imagine your home page shows the latest
photos published in a photo sharing social network and you want to speedup access.

* Every time a user posts a new photo, we add its ID into a list with [`LPUSH`](/commands/lpush).
* When users visit the home page, we use `LRANGE 0 9` in order to get the latest 10 posted items.

### Capped lists

In many use cases we just want to use lists to store the *latest items*,
whatever they are: social network updates, logs, or anything else.

Redis allows us to use lists as a capped collection, only remembering the latest
N items and discarding all the oldest items using the [`LTRIM`](/commands/ltrim) command.

The [`LTRIM`](/commands/ltrim) command is similar to [`LRANGE`](/commands/lrange), but **instead of displaying the
specified range of elements** it sets this range as the new list value. All
the elements outside the given range are removed.

An example will make it more clear:

    > rpush mylist 1 2 3 4 5
    (integer) 5
    > ltrim mylist 0 2
    OK
    > lrange mylist 0 -1
    1) "1"
    2) "2"
    3) "3"

The above [`LTRIM`](/commands/ltrim) command tells Redis to keep just list elements from index
0 to 2, everything else will be discarded. This allows for a very simple but
useful pattern: doing a List push operation + a List trim operation together
in order to add a new element and discard elements exceeding a limit:

    LPUSH mylist <some element>
    LTRIM mylist 0 999

The above combination adds a new element and keeps only the 1000
newest elements into the list. With [`LRANGE`](/commands/lrange) you can access the top items
without any need to remember very old data.

Note: while [`LRANGE`](/commands/lrange) is technically an O(N) command, accessing small ranges
towards the head or the tail of the list is a constant time operation.

Blocking operations on lists
---

Lists have a special feature that make them suitable to implement queues,
and in general as a building block for inter process communication systems:
blocking operations.

Imagine you want to push items into a list with one process, and use
a different process in order to actually do some kind of work with those
items. This is the usual producer / consumer setup, and can be implemented
in the following simple way:

* To push items into the list, producers call [`LPUSH`](/commands/lpush).
* To extract / process items from the list, consumers call [`RPOP`](/commands/rpop).

However it is possible that sometimes the list is empty and there is nothing
to process, so [`RPOP`](/commands/rpop) just returns NULL. In this case a consumer is forced to wait
some time and retry again with [`RPOP`](/commands/rpop). This is called *polling*, and is not
a good idea in this context because it has several drawbacks:

1. Forces Redis and clients to process useless commands (all the requests when the list is empty will get no actual work done, they'll just return NULL).
2. Adds a delay to the processing of items, since after a worker receives a NULL, it waits some time. To make the delay smaller, we could wait less between calls to [`RPOP`](/commands/rpop), with the effect of amplifying problem number 1, i.e. more useless calls to Redis.

So Redis implements commands called [`BRPOP`](/commands/brpop) and [`BLPOP`](/commands/blpop) which are versions
of [`RPOP`](/commands/rpop) and [`LPOP`](/commands/lpop) able to block if the list is empty: they'll return to
the caller only when a new element is added to the list, or when a user-specified
timeout is reached.

This is an example of a [`BRPOP`](/commands/brpop) call we could use in the worker:

    > brpop tasks 5
    1) "tasks"
    2) "do_something"

It means: "wait for elements in the list `tasks`, but return if after 5 seconds
no element is available".

Note that you can use 0 as timeout to wait for elements forever, and you can
also specify multiple lists and not just one, in order to wait on multiple
lists at the same time, and get notified when the first list receives an
element.

A few things to note about [`BRPOP`](/commands/brpop):

1. Clients are served in an ordered way: the first client that blocked waiting for a list, is served first when an element is pushed by some other client, and so forth.
2. The return value is different compared to [`RPOP`](/commands/rpop): it is a two-element array since it also includes the name of the key, because [`BRPOP`](/commands/brpop) and [`BLPOP`](/commands/blpop) are able to block waiting for elements from multiple lists.
3. If the timeout is reached, NULL is returned.

There are more things you should know about lists and blocking ops. We
suggest that you read more on the following:

* It is possible to build safer queues or rotating queues using [`LMOVE`](/commands/lmove).
* There is also a blocking variant of the command, called [`BLMOVE`](/commands/blmove).

## Automatic creation and removal of keys

So far in our examples we never had to create empty lists before pushing
elements, or removing empty lists when they no longer have elements inside.
It is Redis' responsibility to delete keys when lists are left empty, or to create
an empty list if the key does not exist and we are trying to add elements
to it, for example, with [`LPUSH`](/commands/lpush).

This is not specific to lists, it applies to all the Redis data types
composed of multiple elements -- Streams, Sets, Sorted Sets and Hashes.

Basically we can summarize the behavior with three rules:

1. When we add an element to an aggregate data type, if the target key does not exist, an empty aggregate data type is created before adding the element.
2. When we remove elements from an aggregate data type, if the value remains empty, the key is automatically destroyed. The Stream data type is the only exception to this rule.
3. Calling a read-only command such as [`LLEN`](/commands/llen) (which returns the length of the list), or a write command removing elements, with an empty key, always produces the same result as if the key is holding an empty aggregate type of the type the command expects to find.

Examples of rule 1:

    > del mylist
    (integer) 1
    > lpush mylist 1 2 3
    (integer) 3

However we can't perform operations against the wrong type if the key exists:

    > set foo bar
    OK
    > lpush foo 1 2 3
    (error) WRONGTYPE Operation against a key holding the wrong kind of value
    > type foo
    string

Example of rule 2:

    > lpush mylist 1 2 3
    (integer) 3
    > exists mylist
    (integer) 1
    > lpop mylist
    "3"
    > lpop mylist
    "2"
    > lpop mylist
    "1"
    > exists mylist
    (integer) 0

The key no longer exists after all the elements are popped.

Example of rule 3:

    > del mylist
    (integer) 0
    > llen mylist
    (integer) 0
    > lpop mylist
    (nil)


## Limits

The max length of a Redis list is 2^32 - 1 (4,294,967,295) elements.


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
