An introduction to Redis data types and abstractions
===

Redis is not a *plain* key-value store, actually it is a *data structures server*, supporting different kind of values. What this means is that, while in
traditional key-value stores you associated string keys to string values, in
Redis the value is not limited to a simple string, but can also hold more complex
data structures. The following is the list of all the data structures supported
by Redis, which will be covered separately in this tutorial:

* Binary-safe strings.
* Lists: collections of string elements sorted according to the order of insertion. They are basically *linked lists*.
* Sets: collections of unique, unsorted string elements.
* Sorted sets, similar to Sets but where every string element is associated to a
  floating number value, called *score*. The elements are always taken sorted
  by their score, so unlike Sets it is possible to retrieve range of elements
  (for example you may aks: give me the top 10, or the bottom 10).
* Hashes, which are maps composed of fields associated with values. Both the
  field and the value are strings. This are very similary to Ruby or Python
  hashes.
* Bit arrays: it is possible, usign special commands, to handle String values
  like array of bits: you can set and clear individual bits, count all the bits
  set to 1, find the first set or unset bit, and so forth.
* HyperLogLogs: this is a probabilistic data structure which is used in order
  to estimate the cardinality of a set. Don't be scared, it is simpler than
  it seems... See later in the HyperLogLog section of this tutorial.

It's not always trivial to grasp how these data types work and what to use in
order to solve a given problem from the [command reference](/commands), so this
document is a crash course to Redis data types and their most used patterns.

For all the examples we'll use the `redis-cli` utility, that's a simple but
handy command line utility to issue commands against the Redis server.

Redis keys
---

Redis keys are binary safe, this means that you can use any binary sequence as a
key, from a string like "foo" to the content of a JPEG file.
The empty string is also a valid key.

A few other rules about keys:

* Too long keys are not a good idea, for instance a key of 1024 bytes is not a
  good idea not only memory-wise, but also because the lookup of the key in the
  dataset may require several costly key-comparisons. Even when the task at hand
  is to match the existence of a big value, to resort to hashing it (for example
  with SHA1) is a better idea, especially from the point of view of memory
  and bandwidth.
* Too short keys are often not a good idea. There is little point in writing
  "u1000flw" as key if you can write instead "user:1000:followers", the latter
  is more readable and the added space is little compared to the space used by
  the key object itself and the value object. However it is not possible to deny
  that short keys will consume a bit less memory. Your job is to find the
  right balance.
* Try to stick with a schema. For instance "object-type:id" can be a nice
  idea, like in "user:1000". Dots or dashes are often used for multi-words
  fields, like in "comment:1234:reply.to" or "comment:1234:reply-to".
* The maximum allowed key size is 512 MB.

Redis Strings
---

The Redis String type is the simplest type of value you can associate to
a Redis key. It is the only data type in Memcached, so it is also very natural
for newcomers to use it in Redis.

Since Redis keys are strings, when we use the string type as a value too,
we are mapping a string to another string. The string data type is useful
for a number of use cases, like caching HTML fragments or pages.

Let's play a bit with the string type, using `redis-cli` (all the examples
will be performed via `redis-cli` in this tutorial).

    > set mykey somevalue
    OK
    > get mykey
    "somevalue"

As you can see using the `SET` and the `GET` commands are the way we set
and retrieve a string value. Note that `SET` will replace any existing value
stored already into the key, in case the key already exists, even if the key
is associated with a non-string value. So `SET` performs an assignment.

Values can be strings (including binary data) of every kind, for instance you
can store a jpeg image inside a key. A value can't be bigger than 512 MB.

The `SET` command has interesting options, that are provided as additional
arguments. For example if I may ask `SET` to fail if the key already exists,
or the exact contrary, that is, to only succeed if the key already exists:

    > set mykey newval nx
    (nil)
    > set mykey newval xx
    OK

Even if strings are the basic values of Redis, there are interesting operations
you can perform with them. For instance, one is atomic increment:

    > set counter 100
    OK
    > incr counter
    (integer) 101
    > incr counter
    (integer) 102
    > incrby counter 50
    (integer) 152

The [INCR](/commands/incr) command parses the string value as an integer,
increments it by one, and finally sets the obtained value as the new value.
There are other similar commands like [INCRBY](/commands/incrby),
[DECR](commands/decr) and [DECRBY](/commands/decrby).  Internally it's
always the same command, acting in a slightly different way.

What does it mean that INCR is atomic?
That even multiple clients issuing INCR against
the same key will never incur into a race condition. For instance it can never
happen that client 1 read "10", client 2 read "10" at the same time, both
increment to 11, and set the new value of 11. The final value will always be 
12 and the read-increment-set operation is performed while all the other
clients are not executing a command at the same time.

There are a number of commands operating on strings. For example
the `GETSET` command sets a key to a new value, returning the old value as
result. You can use this command, for example, if you have a
system that increments a Redis key using `INCR`
every time your web site receives a new visit. You want to collect this
information one time every hour, without losing a single increment.
You can `GETSET` the key, assigning it the new value of "0" and reading the
old value back.

The ability to set or retrieve the value of multiple keys in a single
command is also useful for reduce latency. For this reason there are
the `MSET` and `MGET` commands:

    > mset a 10 b 20 c 30
    OK
    > mget a b c
    1) "10"
    2) "20"
    3) "30"

When `MSET` is used, Redis returns an array of values.

Altering and querying the key space
---

There are commands that are not defined on particular types, but are useful
in order to interact with the space of keys, and thus, can be used with
keys of any type.

For example the `EXISTS` command returns 1 or 0 to signal if a given key
exists or not in the data base, while the `DEL` command deletes a key
and associated value, whatever the value is.

    > set mykey hello
    OK
    > exists mykey
    (integer) 1
    > del mykey
    (integer) 1
    > exists mykey
    (integer) 0

From the examples you can also see how `DEL` itself returns 1 or 0 whatever
the key was removed (it existed) or not (there was no such key with that
name).

There are many key space related commands, but the above two are the
essential ones together with the `TYPE` command, that returns the kind
of value stored at the specified key:

    > set mykey x
    OK
    > type mykey
    string
    > del mykey
    (integer) 1
    > type mykey
    none

Redis Lists
---

To explain the List data type it's better to start with a little bit of theory,
as the term *List* is often used in an improper way by information technology
folks. For instance "Python Lists" are not what the name may suggest (Linked
Lists), they are actually Arrays (the same data type is called Array in
Ruby actually).

From a very general point of view a List is just a sequence of ordered
elements: 10,20,1,2,3 is a list. But the properties of a List implemented using
an Array are very different from the properties of a List implemented using a
*Linked List*.

Redis lists are implemented via Linked Lists. This means that even if you have
millions of elements inside a list, the operation of adding a new element in
the head or in the tail of the list is performed *in constant time*. Adding a
new element with the `LPUSH` command to the head of a ten
elements list is the same speed as adding an element to the head of a 10
million elements list.

What's the downside? Accessing an element *by index* is very fast in lists
implemented with an Array (constant time indexed access) and not so fast in
lists implemented by linked lists (where the operation requires an amount of
work proportional to the index of the accessed element).

Redis Lists are implemented with linked lists because for a database system it
is crucial to be able to add elements to a very long list in a very fast way.
Another strong advantage is, as you'll see in a moment, that Redis Lists can be
taken at constant length in constant time.

When fast access to the middle of a large collection of elements is important,
there is a different data structure that can be used, called sorted sets. Sorted sets will be covered later in this tutorial.

First steps with Redis Lists
---

The `LPUSH` command adds a new element into a list, on the
left (at the head), while the `RPUSH` command adds a new
element into a list, on the right (at the tail). Finally the
`LRANGE` command extracts ranges of elements from lists:

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
element of the range to return. Both the indexes can be negative to tell Redis
to start to count from the end, so -1 is the last element, -2 is the
penultimate element of the list, and so forth.

As you can see `RPUSH` appended the elements on the right of the list, while
the final `LPUSH` appended the element on the left.

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
Popping elements is the operation of retrieving the element from the list,
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

Redis returned a NULL value to signal that there are no elements into the
list.

Common use cases for lists
---

Lists are useful for a number of tasks, two very representative use cases
are the following:

* Remember the latest updates posted by users into a social network.
* Communication between processes, using a consumer-producer pattern where the producer pushes items into a list, and a consumer (usually a *worker*) consumes those items executing actions. Redis has special list commands to make this use case both more reliable and efficient.

For example both the popular Ruby libraries [resque](https://github.com/resque/resque) and [sidekiq](https://github.com/mperham/sidekiq) use Redis lists under the hoods in order to implement background jobs.

The popular Twitter social network [takes the latest tweets](http://www.infoq.com/presentations/Real-Time-Delivery-Twitter) posted by users into Redis lists.

To describe a common use case step by step, imagine you want to speedup the
list of the latest published photos in the home page of your photo sharing
social network.

* Every time an user posts a new photo, we add its ID into a list with `LPUSH`.
* When users visit the home page, we use `LRANGE 0 9` in order to get the latest 10 posted items.

Capped lists
---

In many use cases we just want to use lists to store the *latest items*,
whatever they are: social network updates, logs, or anything else.

Redis allows to use lists as a capped collection, only remembering the latest
N items and discarding all the oldest items using the `LTRIM` command.

The `LTRIM` command is similar to `LRANGE`, but **instead of displaying the
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

The above `LTRIM` command tells Redis to take just list elements from index
0 to 2, everything else will be discarded. This makes you able to mount
a very simple but useful patter, consisting in doing a List push operation
+ a List trim operation together in order to add a new element and discard
exceeding elements:

    LPUSH mylist <some element>
    LTRIM mylist 0 999

The above combination of elements add a new element taking only the 1000
newest elements into the list. With `LRANGE` you can access the top items
without any need to remember very old data.

Note: while `LRANGE` is technically an O(N) command, accessing small ranges
towards the head or the tail of the list, is a constant time operation.

Blocking operations on lists
---

Lists have a special feature that make them suitable to implement queues,
and in general as a building block for inter process communication systems:
blocking operations.

Imagine you want to push items into a list with one process, and use
a different process in order to actually make some kind of work with those
items. This is the usual producer / consumer setup, that can be implemented
in the following simple way:

* To push items into the list, producers call `LPUSH`.
* To extract / process items from the list, consumers call `RPOP`.

However it is possible that sometimes the list is empty and there is nothing
to process, so `RPOP` just returns NULL. So a consumer is forced to wait
some time and retry again with `RPOP`. This is called *polling*, and is not
a good idea in this context because it has several drawbacks:

1. Forces Redis and clients to process useless commands (all the requests when the list is empty will get no actual work done, they'll just return NULL).
2. Adds a delay to the processing of items, since after a worker receives a NULL, it waits some time. To make the delay smaller, we could wait less between calls to `RPOP`, with the effect of aggravating more problem number 1: more useless calls to Redis.

So Redis implements commands called `BRPOP` and `BLPOP` which are versions
of `RPOP` and `LPOP` able to block if the list is empty: they'll return to
the caller only when a new element is added to the list, or when an user
specified timeout is reached.

This is an example of `BRPOP` call we could use in the worker:

    > brpop tasks 5
    1) "tasks"
    2) "do_something"

It means: "wait for elements in the list `tasks`, but return if after 5 seconds
no element is available".

Note that you can use 0 as timeout to wait forever for elements, and you can
also specify multiple lists and not just one, in order to wait into multiple
lists at the same time, and get notified when the first list receives an
element.

A few things to note about `BRPOP`.

1. Clients are served in an ordered way: the first client that blocked waiting for a list, is served the first when an element is pushed by some other client, and so forth.
2. The return value is different compared to `RPOP`: it is a two elements array since it also includes the name of the key, because `BRPOP` and `BLPOP` are able to block waiting for elements from multiple lists.
3. If the timeout is reached, NULL is returned.

There are more things you should know about lists and blocking ops. We
suggest you to read the following pages:

* It is possible to build safer queues or rotating queues using `RPOPLPUSH`.
* There is also a blocking variant of the command, called `BRPOPLPUSH`.

Automatically creation and removal of keys
---

So far in our examples we never had to create empty lists before pushing
elements, or removing empty lists when they no longer have elements inside.
It is Redis care to delete keys when lists are left empty, or to create
an empty list if the key does not exist and we are trying to add elements
to it, for example, with `LPUSH`.

This is not specific to lists, it applies to all the Redis data types
composed of multiple elements, so also applies to Sets, Sorted Sets and
Hashes.

Basically we can summarize the behavior with three rules:

1. When we add an element to an aggregate data type, if the target key does not exist, an empty aggregate data type is crated before adding the element.
2. When we remove elements from an aggregate data type, if the value remains empty, the key is automatically destroyed.
3. Calling a read-only command such as `LLEN` (which returns the length of the list), or a write command removing elements, with an empty key, always produces the same result as if the key is holding an empty aggregate type of the type the command expects to find.

Examples of rule 1:

    > del mylist
    (integer) 1
    > lpush mylist 1 2 3
    (integer) 3

However we can't perform operations against the wrong type of the key exists:

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

The key does no longer exist after all the elements are popped.

Example of rule 3:

    > del mylist
    (integer) 0
    > llen mylist
    (integer) 0
    > lpop mylist
    (nil)

Redis Hashes
---

Redis hashes look like exactly how you expect an "hash" to look like:

    > hmset user:1000 username antirez birthyear 1977 verified 1
    OK
    > hget user:1000 username
    "antirez"
    > hget user:1000 birthyear
    "1977"
    > hgetall user:1000
    1) "username"
    2) "antirez"
    3) "birthyear"
    4) "1977"
    5) "verified"
    6) "1"

It is just a set of fields-values pairs. While hashes are handy to represent
*objects*, actually the number of fields you can put inside an hash has
no practical limits if not available memory, so you can use hashes in many
different ways inside your application.

The command `HMSET` sets multiple fields of the hash, while `HGET` retrieves
a single field. `HMGET` is similar to `HGET` but returns an array of values:

    > hmget user:1000 username birthyear no-such-field
    1) "antirez"
    2) "1977"
    3) (nil)

There are commands that are able to perform operations on individual fields
as well, like `HINCRBY`:

    > hincrby user:1000 birthyear 10
    (integer) 1987
    > hincrby user:1000 birthyear 10
    (integer) 1997

You can find the [full list of hash commands in the documentation](http://redis.io/commands#hash).

It is worth to note that small hashes (a few elements, not too big values) are
encoded in special way in memory that make them very memory efficient.

Redis Sets
---

Redis Sets are unordered collections of strings. The
`SADD` command adds new elements to a set. It's also possible
to do a number of other operations against sets like testing if a given element
already exists, performing the intersection, union or difference between
multiple sets and so forth.

    > sadd myset 1 2 3
    (integer) 3
    > smembers myset
    1. 3
    2. 1
    3. 2

I added three elements to my set and told Redis to return back all the
elements. As you can see they are not sorted, Redis is free to return the
elements in any order at every call, since there is no contract with the
user about elements ordering.

We have commands to test for membership. Does a given element exists?

    > sismember myset 3
    (integer) 1
    > sismember myset 30
    (integer) 0

"3" is a member of the set, while "30" is not.

Sets are good for expressing relations between objects.
For instance we can easily use sets in order to implement tags.

A simple way to model this problem is to have a set for every object we
want to tag. The set contains the IDs of the tags associated with the object.

Imagine we want to tag news.
If our news ID 1000 is tagged with tag 1,2,5 and 77, we can have one set
associating our tag IDs with the news:

    > sadd news:1000:tags 1 2 5 77
    (integer) 4

However sometimes I may want to have the inverse relation as well: the list
of all the news tagged with a given tag:

    > sadd tag:1:news 1000
    (integer) 1
    > sadd tag:2:news 1000
    (integer) 1
    > sadd tag:5:news 1000
    (integer) 1
    > sadd tag:77:news 1000
    (integer) 1

To get all the tags for a given object is trivial:

    > smembers news:1000:tags
    1. 5
    2. 1
    3. 77
    4. 2

Note: in the example we assume you have another data structure, for example
a Redis hash, which maps tag IDs to tag names.

There are other non trivial operations that are still easy to implement
using the right Redis commands. For instance we may want a list of all the
objects with the tags 1, 2, 10, and 27 together. We can do this using
the `SINTER` command, that performs the intersection between different
sets. We can just use:

    > sinter tag:1:news tag:2:news tag:10:news tag:27:news
    ... results here ...

Intersection is not the only operation performed, you can also perform
unions, difference, extract a random element, and so forth.

The command to extract an element is called `SPOP`, and is handy to model
certain problems. For example in order to implement a web-based poker game,
you may want to represent your deck into a set. Imagine we use a one-char
prefix for (C)lubs, (D)iamonds, (H)earts, (S)pades.

    >  sadd deck C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 CJ CQ CK
       D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 DJ DQ DK H1 H2 H3
       H4 H5 H6 H7 H8 H9 H10 HJ HQ HK S1 S2 S3 S4 S5 S6
       S7 S8 S9 S10 SJ SQ SK
       (integer) 52

Now we want to provide each player with 5 cards. The `SPOP` command
removes a random element, returning it to the client, so it is the
perfect operation in this case.

However if we call it against our deck directly, in the next play of the
game we'll need to populate the deck of cards again, which may not be
ideal. So to start, we can make a copy of the set stored in the `deck` key,
into the `game:1:deck` key.

This is accomplished using `SUNIONSTORE`, which normally performs the
intersection between multiple sets, and stores the result into anther set.
However the intersection of a single set, is itself, so I can copy my deck
with:

    > sunionstore game:1:deck deck
    (integer) 52

Now I'm ready to provide the first player with its five cards:

    > spop game:1:deck
    "C6"
    > spop game:1:deck
    "CQ"
    > spop game:1:deck
    "D1"
    > spop game:1:deck
    "CJ"
    > spop game:1:deck
    "SJ"

One pair of jacks, not great...

It is a good time to introduce the set command that provides the number
of elements inside a set. This is often called *cardinality of a set*
in the context of set theory, so the Redis command is called `SCARD`.

    > scard game:1:deck
    (integer) 47

The math works: 52 - 5 = 47.

When you need to just get random elements without removing them from the
set, there is the `SRANDMEMBER` command suitable for the task. It also features
the ability to return both repeating and non-repeating elements.

Sorted sets
---

Sets are a very handy data type, but... they are a bit too unsorted in order to
fit well for a number of problems ;) This is why Redis 1.2 introduced Sorted
Sets. They are very similar to Sets, collections of binary-safe strings, but
this time with an associated score, and an operation similar to the List LRANGE
operation to return items in order, but working against Sorted Sets, that is,
the [ZRANGE](/commands/zrange) command.

Basically Sorted Sets are in some way the Redis equivalent of Indexes in the
SQL world. For instance in our reddit.com example above there was no mention
about how to generate the actual home page with news raked by user votes and
time. We'll see how sorted sets can fix this problem, but it's better to start
with something simpler, illustrating the basic working of this advanced data
type. Let's add a few selected hackers with their year of birth as "score".

    $ redis-cli zadd hackers 1940 "Alan Kay"
    (integer) 1
    $ redis-cli zadd hackers 1953 "Richard Stallman"
    (integer) 1
    $ redis-cli zadd hackers 1965 "Yukihiro Matsumoto"
    (integer) 1
    $ redis-cli zadd hackers 1916 "Claude Shannon"
    (integer) 1
    $ redis-cli zadd hackers 1969 "Linus Torvalds"
    (integer) 1
    $ redis-cli zadd hackers 1912 "Alan Turing"
    (integer) 1

For sorted sets it's a joke to return these hackers sorted by their birth year
because actually *they are already sorted*. Sorted sets are implemented via a
dual-ported data structure containing both a skip list and a hash table, so
every time we add an element Redis performs an O(log(N)) operation. That's
good, but when we ask for sorted elements Redis does not have to do any work at
all, it's already all sorted:

    $ redis-cli zrange hackers 0 -1
    1. Alan Turing
    2. Claude Shannon
    3. Alan Kay
    4. Richard Stallman
    5. Yukihiro Matsumoto
    6. Linus Torvalds

Didn't know that Linus was younger than Yukihiro btw ;)

What if I want to order them the opposite way, youngest to oldest?
Use [ZREVRANGE](/commands/zrevrange) instead of [ZRANGE](/commands/zrange):

    $ redis-cli zrevrange hackers 0 -1
    1. Linus Torvalds
    2. Yukihiro Matsumoto
    3. Richard Stallman
    4. Alan Kay
    5. Claude Shannon
    6. Alan Turing

A very important note, ZSets have just a "default" ordering but you are still
free to call the [SORT](/commands/sort) command against sorted sets to get a
different ordering (but this time the server will waste CPU). An alternative
for having multiple orders is to add every element in multiple sorted sets at
the same time.

Operating on ranges
---

Sorted sets are more powerful than this. They can operate on ranges.
Let's get all the individuals that were born up to the 1950 inclusive. We
use the [ZRANGEBYSCORE](/commands/zrangebyscore) command to do it:

    $ redis-cli zrangebyscore hackers -inf 1950
    1. Alan Turing
    2. Claude Shannon
    3. Alan Kay

We asked Redis to return all the elements with a score between negative
infinity and 1950 (both extremes are included).

It's also possible to remove ranges of elements. Let's remove all
the hackers born between 1940 and 1960 from the sorted set:

    $ redis-cli zremrangebyscore hackers 1940 1960
    (integer) 2

[ZREMRANGEBYSCORE](/commands/zremrangebyscore) is not the best command name,
but it can be very useful, and returns the number of removed elements.

Back to the Reddit example
---

For the last time, back to the Reddit example. Now we have a decent plan to
populate a sorted set in order to generate the home page. A sorted set can
contain all the news that are not older than a few days (we remove old entries
from time to time using ZREMRANGEBYSCORE). A background job gets all the
elements from this sorted set, get the user votes and the time of the news, and
computes the score to populate the *reddit.home.page* sorted set with the news
IDs and associated scores. To show the home page we just have to perform a
blazingly fast call to ZRANGE.

From time to time we'll remove very old news from the *reddit.home.page* sorted
set to keep our system working with fresh news only.

Updating the scores of a sorted set
---

Just a final note before wrapping up this tutorial. Sorted sets scores can be
updated at any time. Just calling again ZADD against an element already
included in the sorted set will update its score (and position) in O(log(N)),
so sorted sets are suitable even when there are tons of updates.

This tutorial is in no way complete and has covered just the basics. 
Read the [command reference](/commands) to discover a lot more.

Lexicographical ranges
---

HyperLogLogs
---

Counting unique searches with HLLs
---

Iterating the key space
---

Iterating big collections of elements
---

Redis expires: keys with limited time to live
---

Extending Redis with Lua scripting
---

Publish Subscribe with Redis
---

Thanks for reading, and have a good hacking with Redis!
