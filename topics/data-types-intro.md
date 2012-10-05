A fifteen minute introduction to Redis data types
===

As you already probably know Redis is not a plain key-value store, actually it
is a *data structures server*, supporting different kind of values. That is,
you can set more than just strings as values of keys. All the following data types are
supported as values:

* Binary-safe strings.
* Lists of binary-safe strings.
* Sets of binary-safe strings, that are collection of unique unsorted elements.
  You can think at this as a Ruby hash where all the keys are set to the 'true'
  value.
* Sorted sets, similar to Sets but where every element is associated to a
  floating number score. The elements are taken sorted by score. You can think
  of this as Ruby hashes where the key is the element and the value is the
  score, but where elements are always taken in order without requiring a
  sorting operation.

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
  dataset may require several costly key-comparisons.
* Too short keys are often not a good idea. There is little point in writing "u:1000:pwd"
  as key if you can write instead "user:1000:password", the latter is more
  readable and the added space is little compared to the space used by the
  key object itself and the value object. However it is not possible to deny
  that short keys will consume a bit less memory.
* Try to stick with a schema. For instance "object-type:id:field" can be a nice
  idea, like in "user:1000:password". I like to use dots for multi-words
  fields, like in "comment:1234:reply.to".

The string type
---

This is the simplest Redis type. If you use only this type, Redis will be
something like a memcached server with persistence.

Let's play a bit with the string type:

    $ redis-cli set mykey "my binary safe value"
    OK
    $ redis-cli get mykey
    my binary safe value

As you can see using the [SET command](/commands/set) and the [GET
command](/commands/get) is trivial to set values to strings and have the
strings returned back.

Values can be strings (including binary data) of every kind, for instance you
can store a jpeg image inside a key. A value can't be bigger than 512 MB.

Even if strings are the basic values of Redis, there are interesting operations
you can perform against them. For instance, one is atomic increment:

    $ redis-cli set counter 100
    OK
    $ redis-cli incr counter
    (integer) 101
    $ redis-cli incr counter
    (integer) 102
    $ redis-cli incrby counter 10
    (integer) 112

The [INCR](/commands/incr) command parses the string value as an integer,
increments it by one, and finally sets the obtained value as the new string
value. There are other similar commands like [INCRBY](/commands/incrby),
[DECR](commands/decr) and [DECRBY](/commands/decrby).  Internally it's
always the same command, acting in a slightly different way.

What does it mean that INCR is atomic? That even multiple clients issuing INCR against
the same key will never incur into a race condition. For instance it can never
happen that client 1 read "10", client 2 read "10" at the same time, both
increment to 11, and set the new value of 11. The final value will always be 
12 and the read-increment-set operation is performed while all the other
clients are not executing a command at the same time.

Another interesting operation on string is the [GETSET](/commands/getset)
command, that does just what its name suggests: Set a key to a new value,
returning the old value as result. Why this is useful? Example: you have a
system that increments a Redis key using the [INCR](/commands/incr) command
every time your web site receives a new visit. You want to collect this
information one time every hour, without losing a single key. You can GETSET
the key, assigning it the new value of "0" and reading the old value back.

The List type
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
new element with the [LPUSH](/commands/lpush) command to the head of a ten
elements list is the same speed as adding an element to the head of a 10
million elements list.

What's the downside? Accessing an element *by index* is very fast in lists
implemented with an Array and not so fast in lists implemented by linked lists.

Redis Lists are implemented with linked lists because for a database system it
is crucial to be able to add elements to a very long list in a very fast way.
Another strong advantage is, as you'll see in a moment, that Redis Lists can be
taken at constant length in constant time.

First steps with Redis lists
---

The [LPUSH](/commands/lpush) command adds a new element into a list, on the
left (at the head), while the [RPUSH](/commands/rpush) command adds a new
element into a list, on the right (at the tail). Finally the
[LRANGE](/commands/lrange) command extracts ranges of elements from lists:

    $ redis-cli rpush messages "Hello how are you?"
    OK
    $ redis-cli rpush messages "Fine thanks. I'm having fun with Redis"
    OK
    $ redis-cli rpush messages "I should look into this NOSQL thing ASAP"
    OK
    $ redis-cli lrange messages 0 2
    1. Hello how are you?
    2. Fine thanks. I'm having fun with Redis
    3. I should look into this NOSQL thing ASAP

Note that [LRANGE](/commands/lrange) takes two indexes, the first and the last
element of the range to return. Both the indexes can be negative to tell Redis
to start to count from the end, so -1 is the last element, -2 is the
penultimate element of the list, and so forth.

As you can guess from the example above, lists could be used in
order to implement a chat system. Another use is as queues in order to route
messages between different processes. But the key point is that *you can use
Redis lists every time you require to access data in the same order they are
added*. This will not require any SQL ORDER BY operation, will be very fast,
and will scale to millions of elements even with a toy Linux box.

For instance in ranking systems like that used by social news site reddit.com you can add
every new submitted link into a List, and with [LRANGE](/commands/lrange) it's
possible to paginate results in a trivial way.

In a blog engine implementation you can have a list for every post, where to
push blog comments, and so forth.

Pushing IDs instead of the actual data in Redis lists
---

In the above example we pushed our "objects" (simply messages in the example)
directly inside the Redis list, but this is often not the way to go, as objects
can be referenced in multiple times: in a list to preserve their chronological
order, in a Set to remember they are about a specific category, in another list
but only if this object matches some kind of requisite, and so forth.

Let's return back to the reddit.com example. A better pattern for adding
submitted links (news) to the list is the following:

    $ redis-cli incr next.news.id
    (integer) 1
    $ redis-cli set news:1:title "Redis is simple"
    OK
    $ redis-cli set news:1:url "http://code.google.com/p/redis"
    OK
    $ redis-cli lpush submitted.news 1
    OK

We obtained a unique incremental ID for our news object just incrementing a
key, then used this ID to create the object setting a key for every field in
the object. Finally the ID of the new object was pushed on the *submitted.news*
list.

This is just the start. Check the [command reference](/commands) and read about
all the other list related commands. You can remove elements, rotate lists, get
and set elements by index, and of course retrieve the length of the list with
[LLEN](/commands/llen).

Redis Sets
---

Redis Sets are unordered collection of binary-safe strings. The
[SADD](/commands/sadd) command adds a new element to a set. It's also possible
to do a number of other operations against sets like testing if a given element
already exists, performing the intersection, union or difference between
multiple sets and so forth. An example is worth 1000 words:

    $ redis-cli sadd myset 1
    (integer) 1
    $ redis-cli sadd myset 2
    (integer) 1
    $ redis-cli sadd myset 3
    (integer) 1
    $ redis-cli smembers myset
    1. 3
    2. 1
    3. 2

I added three elements to my set and told Redis to return back all the
elements. As you can see they are not sorted.

Now let's check if a given element exists:

    $ redis-cli sismember myset 3
    (integer) 1
    $ redis-cli sismember myset 30
    (integer) 0

"3" is a member of the set, while "30" is not. Sets are very good for
expressing relations between objects. For instance we can easily use Redis Sets
in order to implement tags.

A simple way to model this is to have a Set for every object containing its associated
tag IDs, and a Set for every tag containing the object IDs that have that tag. 

For instance if our news ID 1000 is tagged with tag 1,2,5 and 77, we can
specify the following five Sets - one Set for the object's tags, and four Sets
for the four tags:

    $ redis-cli sadd news:1000:tags 1
    (integer) 1
    $ redis-cli sadd news:1000:tags 2
    (integer) 1
    $ redis-cli sadd news:1000:tags 5
    (integer) 1
    $ redis-cli sadd news:1000:tags 77
    (integer) 1
    $ redis-cli sadd tag:1:objects 1000
    (integer) 1
    $ redis-cli sadd tag:2:objects 1000
    (integer) 1
    $ redis-cli sadd tag:5:objects 1000
    (integer) 1
    $ redis-cli sadd tag:77:objects 1000
    (integer) 1

To get all the tags for a given object is trivial:

    $ redis-cli smembers news:1000:tags
    1. 5
    2. 1
    3. 77
    4. 2

But there are other non trivial operations that are still easy to implement
using the right Redis commands. For instance we may want a list of all the
objects with the tags 1, 2, 10, and 27 together. We can do this using
the [SINTER](/commands/sinter) that performs the intersection between different
sets. So in order to reach our goal we can just use:

    $ redis-cli sinter tag:1:objects tag:2:objects tag:10:objects tag:27:objects
    ... no result in our dataset composed of just one object ;) ...

Look at the [command reference](/commands) to discover other Set related
commands, there are a bunch of interesting ones. Also make sure to check the
[SORT](/commands/sort) command as both Redis Sets and Lists are sortable.

A digression: How to get unique identifiers for strings
---

In our tags example we showed tag IDs without mention of how the IDs can be
obtained. Basically for every tag added to the system, you need a unique 
identifier. You also want to be sure that there are no race conditions if
multiple clients are trying to add the same tag at the same time. Also, if a
tag already exists, you want its ID returned, otherwise a new unique ID should
be created and associated to the tag.

Redis 1.4 will add the Hash type. With it it will be trivial to associate
strings with unique IDs, but how to do this today with the current commands
exported by Redis in a reliable way?

Our first attempt (that is broken) can be the following. Let's suppose we want
to get a unique ID for the tag "redis":

* In order to make this algorithm binary safe (they are just tags but think to
  utf8, spaces and so forth) we start performing the SHA1 digest of the tag.
  SHA1(redis) = b840fc02d524045429941cc15f59e41cb7be6c52.
* Let's check if this tag is already associated with a unique ID with the
  command *GET tag:b840fc02d524045429941cc15f59e41cb7be6c52:id*.
* If the above GET returns an ID, return it back to the user. We already have
  the unique ID.
* Otherwise... create a new unique ID with *INCR next.tag.id* (assume it
  returned 123456).
* Finally associate this new ID to our tag with *SET
  tag:b840fc02d524045429941cc15f59e41cb7be6c52:id 123456* and return the new ID
  to the caller.

Nice. Or rather.. broken! What about if two clients perform these commands at
the same time trying to get the unique ID for the tag "redis"? If the timing is
right they'll both get *nil* from the GET operation, will both increment the
*next.tag.id* key and will set two times the key. One of the two clients will
return the wrong ID to the caller. To fix the algorithm is not hard
fortunately, and this is the sane version:

* In order to make this algorithm binary safe (they are just tags but think to
  utf8, spaces and so forth) we start performing the SHA1 digest of the tag.
  SHA1(redis) = b840fc02d524045429941cc15f59e41cb7be6c52.
* Let's check if this tag is already associated with a unique ID with the
  command *GET tag:b840fc02d524045429941cc15f59e41cb7be6c52:id*.
* If the above GET returns an ID, return it back to the user. We already have
  the unique ID.
* Otherwise... create a new unique ID with *INCR next.tag.id* (assume it
  returned 123456).
* Finally associate this new ID to our tag with *SETNX
  tag:b840fc02d524045429941cc15f59e41cb7be6c52:id 123456*. By using SETNX if a
  different client was faster than this one the key will not be setted. Not
  only, SETNX returns 1 if the key is set, 0 otherwise. So... let's add a final
  step to our computation.
* If SETNX returned 1 (We set the key) return 123456 to the caller, it's our
  tag ID, otherwise perform *GET
  tag:b840fc02d524045429941cc15f59e41cb7be6c52:id* and return the value to the
  caller.

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

Thanks for reading,
Salvatore.
