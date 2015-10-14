Secondary indexing with Redis
===

While Redis not exactly a key-value store, since values can be complex data structures, it has an extrenal key-value shell, since at API level data is addressed by the key name. It is fair to say that, natively, Redis only offers primary key access. However since Redis is a data structures server, certain data structures can be used for indexing, in order to create secondary indexes of different kinds, including secondary indexes and composite (multi-column) indexes.

This document explains how it is possible to create indexes in Redis using the following data structures:

* Sorted sets to create secondary indexes by ID or other numerical fields.
* Sorted sets with lexicographical ranges for creating more advanced secondary indexes and composite indexes.
* Sets for creating random indexes.
* Lists for creating simple iterable indexes.

Implementing and maintaining indexes with Redis is an advanced topic, so most
users that need to perform complex queries on data should understand if they
are better served by a relational store. However often, especially in caching
scenarios, there is the explicit need to store indexed data into Redis in order
to speedup common queries which require indexes.

Simple numerical indexes with sorted sets
===

The simplest secondary index you can create with Redis is by using a
sorted set data type, which is a data structure representing a set of
elements ordered by a floating point number which is the *score* of
each element. Elements are ordered from the smallest to the highest score.

Since the score is a double precision float, indexes you can build with
vanilla sorted sets are limited to things were the indexing field is a number
within a given specific range.

The two commands to build those kinda of indexes are `ZADD` and
`ZRANGEBYSCORE` to respectively add items and retrieve items within a
specified range.

For instance, it is possible to index a set of names by their
age by adding element to a sorted set. The element will be the name of the
person and the score will be the age.

    ZADD myindex 25 Manuel
    ZADD myindex 18 Anna
    ZADD myindex 35 Jon
    ZADD myindex 67 Helen

In order to retrieve all the persons with an age between 20 and 40:

    ZRANGEBYSCORE myindex 20 40
    1) "Manuel"
    2) "Jon"

By using the **WITHSCORES** option of `ZRANGEBYSCORE` it is also possible
to obtain the scores associated with the returned elements.

The `ZCOUNT` command can be used in order to retrieve the number of elements
between a given range without actually fetching the elements which is also
useful, especially given the fact the operation has logarithmic time
complexity regardless of the size of the range.

Ranges can be inclusive or exclusive, please refer to the `ZRANGEBYSCORE`
command documentation for more information.

**Note**: Using the `ZREVRANGEBYSCORE` it is possible to query range in
reversed order, which is often useful when data is indexed in a given
direction (ascending or descending) but we want to retrieve information
in the other way.

Using objects IDs as associated values
---

In the above example we associated names to ages. However in general we
may want to index some field of an object to some object. Instead of
using as the sorted set value directly the data associated with the
indexed field, it is possible to use an ID which refers to some object
stored at a different key.

For example I may have Redis hashes, one per key, referring to hashes
representing users:

    HMSET user:1 username id 1 antirez ctime 1444809424 age 38
    HMSET user:2 username id 2 maria ctime 1444808132 age 42
    HMSET user:3 username id 3 jballard ctime 1443246218 age 33

If I want to create an index in order to query users by their age, I
could do:

    ZADD user.age.index 38 1
    ZADD user.age.index 42 2
    ZADD user.age.index 33 3

This time the value associated with the score in the sorted set is the
ID of the object. So once I query the index with `ZRANGEBYSCORE` I'll
also retrieve the informations I need with `HGETALL` or similar commands.

In the next examples we'll always use IDs as values associated with the
index, since this is usually the more sounding design.

Updating simple sorted set indexes
---

Often we index things which change during time. For example in the above
example, the age of the user changes every year. In such a case it would
make sense to use the birth date as index instead of the age itself,
but there are other cases where we simple want some field to change from
time to time, and the index to reflect this change.

The `ZADD` command makes updating simple indexes a very trivial operation
since re-adding back an element with a different score and the same value
will simply update the score and move the element at the right position,
so if the user *antirez* turned 39 years old, in order to update the
data in the hash representing the user, and in the index as well, we need
the following two commands:

    HSET user:1 age 39
    ZADD user.age.index 39 1

The operation may be wrapped in a `MULTI`/`EXEC` transaction in order to
make sure both fields are updated or none.

Turning multi dimensional data into linear data
---

Indexes created with sorted sets are able to index only a single numerical
value. Because of this you may think it is impossible to index something
which has multiple dimensions using this kind of indexes, but actually this
is not always true. If you can efficiently represent something
multi-dimensional in a linear way, they it is often possible to use a simple
sorted set for indexing.

For example the [Redis geo indexing API](/commands/geoadd) users a sorted
set to index places by latitude and longitude using a technique called
[Geo hash](https://en.wikipedia.org/wiki/Geohash). The sorted set score
represents alternating bits of longitude and latitude, so that we map the
linear score of a sorted set to many small *squares* in the earth surface.
By doing an 8+1 style center and neighborhood search it is possible to
retrieve elements by radius.

Limits of the score
---

Sorted set elements scores are double precision integers. It means that
they can represent different decimal or integer values with a different
errors. However what is interesting for indexing is that the score is
always able to represent without any error numbers between -9007199254740992
and 9007199254740992, which is `-/+ 2^53`.

When representing much larger numbers, you need a different form if indexing
that is able to index numbers at any precision, called a lexicographical
index.

Lexicographical indexes
===

Redis sorted sets have an interesting property. When elements are added
with the same score, they are sorted lexicographically, comparing the
strings as binary data with the `memcmp()` function.

Moreover, there are commands such as `ZRANGEBYLEX` and `ZLEXCOUNT` that
are able to query and count ranges in a lexicographically fashion.

This feature is basically equivalent to a `b-tree` data structure which
is often used in order to implement indexes with traditional databases.
As you can guess, because of this, it is possible to use this Redis data
structure in order to implement pretty fancy indexes.

Before to dive into using lexicographical indexes, let's check how
sorted sets behave in this special mode of operations. Since we need to
add elements with the same score, we'll always use the special score of
zero.

    ZADD myindex 0 baaa
    ZADD myindex 0 abbb
    ZADD myindex 0 aaaa
    ZADD myindex 0 bbbb

Fetching all the elements from the sorted set immediately reveals that they
are ordered lexicographically.

    ZRANGE myindex 0 -1
    1) "aaaa"
    2) "abbb"
    3) "baaa"
    4) "bbbb"

Now we can use `ZRANGEBYLEX` in order to perform range queries.

    ZRANGEBYLEX myindex [a (b
    1) "aaaa"
    2) "abbb"

Note that in the range queries I prefixed my min and max element with
`[` and `(`. This prefixes are mandatory, and they specify if the element
we specify for the range is inclusive or exclusive. So the range `[a (b` means give me all the elements lexicographically between `a` inclusive and `b` exclusive, which are all the elements starting with `a`.

There are also two more special characters indicating the infinitely negative
string and the infinitely positive string, which are `-` and `+`.

    ZRANGEBYLEX myindex [b +
    1) "baaa"
    2) "bbbb"

That's it basically. Let's see how to use these features to build indexes.

A first example: completion
---

An interesting application of indexing is completion, similar to what happens
in a search engine when you start to type your search query: it will
anticipate what you are likely typing, providing common queries that
start with the same characters.

A naive approach to completion is to just add every single query we
get from the user into the index. For example if the user search `banana`
we'll just do:

    ZADD myindex 0 banana

And so forth for each search query ever encountered. Then when we want to
complete the user query, we do a very simple query using `ZRANGEBYLEX`, like
the following. Imagine the user is typing "bit", and we want to complete the
query. We send a command like that:

    ZLEXRANGE myindex "[bit" "[bit\xff"

Basically we create a range using the string the user is typing right now
as start, and the same sting plus a trailing byte set to 255, which is `\xff` in the example, as the end of the range. In this way we get all the strings that start for the string the user is typing.

Note that we don't want too many items returned, so we may use the **LIMIT** option in order to reduce the number of results.

Adding frequency into the mix
---

The above approach is a bit naive, because all the user queries are the same
in this way. In a real system we want to complete strings accordingly to their
frequency: very popular queries will be proposed with an higher probability
compared to query strings searched very rarely.

In order to implement something which depends on the frequency, and at the
same time automatically adapts to future inputs and purges query strings that
are no longer popular, we can use a very simple *streaming algorithm*.

To start, we modify our index in order to don't have just the search term,
but also the frequency the term is associated with. So instead of just adding
`banana` we add `banana:1`, where 1 is the frequency.

    ZADD myindex 0 banana:1

We also need logic in order to increment the index if the search term
already exists in the index, so what we'll actually do is something like
that:

    ZRANGEBYLEX myindex "[banana:" + LIMIT 1 1
    1) "banana:1"

This will return the single entry of `banana` if it exists. Then we
can increment the associated frequency and send the following two
commands:

    ZREM myindex 0 banana:1
    ZADD myindex 0 banana:2

Note that because it is possible that there are concurrent updates, the
above three commands should be send via a [Lua script](/commands/eval)
instead, so that the Lua script will atomically get the old count and
re-add the item with incremented score.

So the result will be that, every time an user searches for `banana` we'll
get our entry updated.

There is more: our goal is to just have items searched very frequently.
So we need some form of purging. So, when we actually query the index
in order to complete the user request, we may see something like that:

    ZRANGEBYLEX myindex "[banana:" + LIMIT 1 10
    1) "banana:123"
    2) "banahhh:1"
    3) "banned user:49"
    4) "banning:89"

Apparently nobody searches for "banahhh", for example, but the query was
performed a single time, so we end presenting it to the user.

So what we do is, out of the returned items, we pick a random one, divide
its score by two, and re-add it with half to score. However if the score
was already "1", we simply remove the item from the list. You can use
much more advanced systems, but the idea is that the index in the long run
will contain top queries, and if top queries will change over the time
it will adapt itself.

A refinement to this algorithm is to pick entries in the list according to
their weight: the higher the score, the less likely it is picked
in order to halve its score, or evict it.

Normalizing strings for case and accents
---

In the completion examples we always used lowercase strings. However
reality is much more complex than that: languages have capitalized names,
accents, and so forth.

One simple way do deal with this issues is to actually normalize the
string the user searches. Whatever the user searches for "Banana",
"BANANA" or Ba'nana" we may always turn it into "banana".

However sometimes we could like to present the user with the original
item typed, even if we normalize the string for indexing. In order to
do this, what we do is to change the format of the index so that instead
of just storing `term:frequency` we store `normalized:frequency:original`
like in the following example:

    ZADD myindex 0 banana:273:Banana

Basically we add another field that we'll extract and use only for
visualization. Ranges will always be computed using the normalized strings
instead. This is a common trick which has multiple applications.

Adding auxiliary informations in the index
---

When using sorted set in a direct way, we have two different attributes
for each object: the score, which we use as an index, and an associated
value. When using lexicographical indexes instead, the score is always
set to 0 and basically not used at all. We are left with a single string,
which is the element itself.

Like we did in the previous completion examples, we are still able to
store associated data using separators. For example we used the colon in
order to add the frequency and the original word for completion.

In general we can add any kind of associated value to our primary key.
In order to use a lexicographic index to implement a simple key-value store
we just store the entry as `key:value`:

    ZADD myindex 0 mykey:myvalue

And search for the key with:

    ZRANGEBYLEX myindex mykey: + LIMIT 1 1
    1) "mykey:myvalue"

Then we just get the part after the colon to retrieve the value.
However a problem to solve in this case is collisions. The colon character
may be part of the key itself, so it must be chosen in order to never
collide with the key we add.

Since lexicographical ranges in Redis are binary safe you can use any
byte or any sequence of bytes. However if you receive untrusted user
input, it is better to use some form of escaping in order to guarantee
that the separator will never happen to be part of the key.

For example if you use two null bytes as separator `"\0\0"`, you may
want to always escape null bytes into two bytes sequences in your strings.

Numerical padding
---

Lexicographical indexes may look like good only when the problem at hand
is to index strings. Actually it is very simple to use this kind of index
in order to index arbitrary precision numbers.

In the ASCII character set, digits appear in the order from 0 to 9, so
if we left-pad numbers with leading zeroes, the result is that comparing
them as strings will order them by their numerical value.

    ZADD myindex 0 00324823481:foo
    ZADD myindex 0 12838349234:bar
    ZADD myindex 0 00000000111:zap

    ZRANGE myindex 0 -1
    1) "00000000111:zap"
    2) "00324823481:foo"
    3) "12838349234:bar"

We effectively created an index using a numerical field which can be as
big as we want. This also works with floating point numbers of any precision
by making sure we left pad the numerical part with leading zeroes and the
decimal part with trailing zeroes like in the following list of numbers:

        01000000000000.11000000000000
        01000000000000.02200000000000
        00000002121241.34893482930000
        00999999999999.00000000000000

Using numbers in binary form
---

Storing numbers in decimal may use too much memory. An alternative approach
is just to store numbers, for example 128 bit integers, directly in their
binary form. However for this to work, you need to store the numbers in
*big endian format*, so that the most significant bytes are stored before
the least significant bytes. This way when Redis compares the strings with
`memcmp()`, it will effectively sort the numbers by their value.

However data stored in binary format is less observable for debugging, harder
to parse and export. So it is definitely a trade off.

Composite indexes
===

So far we explored ways to index single fields. However we all now that
SQL stores are able to create indexes using multiple fields. For example
I may index products in a very large store by room number and price.

I need to run queries in order to retrieve all the products in a given
room having a given price range. What I can do is to index each product
in the following way:

    ZADD myindex 0 0056:0028.44:90
    ZADD myindex 0 0034:0011.00:832

Here the fields are `room:price:product_id`. I used just four digits padding
in the example for simplicity. The auxiliary data (the product ID) does not
need any padding.

With an index like that, to get all the products in room 56 having a price
between 10 and 30 dollars is very easy. We can just run the following
command:

    ZRANGEBYLEX myindex [0056:0010.00 [0056:0030.00

The above is called a composed index. Its effectiveness depends on the
order of the fields and the queries I want to run. For example the above
index cannot be used efficiently in order to get all the products having
a specific prince range regardless of the room number. However I can use
the primary key in order to run queries regardless of the prince, like
*give me all the products in room 44*.

Composite indexes are very powerful, and are used in traditional stores
in order to optimize complex queries. In Redis they could be useful both
to perform a very fast in-memory Redis index of something stored into
a traditional data store, or in order to directly index Redis data.

Updating lexicographical indexes
===

The value of the index in a lexicographical index can get pretty fancy
and hard or slow to rebuild from what we store about the object. So one
approach to simplify the handling of the index, at the cost of using more
memory, is to also take alongside to the sorted set representing the index
an hash mapping the object ID to the current index value.

So for example, when we index we also add to an hash:

    MULTI
    ZADD myindex 0 0056:0028.44:90
    HSET index.content 90 0056:0028.44:90
    EXEC

This many not be always needed, but simplifies the operations of updating
the index. In order to remove the old information we indexed for the object
ID 90, regardless of the *current* fields values of the object, we just
have to retrieve the hash value by object id and `ZREM` it in the sorted
set view.

Representing and querying graphs using an hexastore
===

One cool thing about composite indexes is that they are handy in order
to represent graphs, using a data structure which is called
[Hexastore](http://www.vldb.org/pvldb/1/1453965.pdf).

The hexastore provides a representation for the relations between objects,
formed by a *subject*, a *predicate* and an *object*.
A simple relation between objects could be:

    antirez is-friend-of mcollina

In order to represent this relation I can store the following element
in my lexicographical index:

    ZADD myindex 0 spo:antirez:is-friend-of:mcollina

Note that I prefixed my item with the string **spo**. It means that
the item represents a subject,predicate,object relation.

In can add more 5 items for the same relation, but in a different order:

    ZADD myindex 0 sop:antirez:mcollina:is-friend-of
    ZADD myindex 0 ops:mcollina:is-friend-of:antirez
    ZADD myindex 0 osp:mcollina:antirez:is-friend-of
    ZADD myindex 0 pso:is-friend-of:antirez:mcollina
    ZADD myindex 0 pos:is-friend-of:mcollina:antirez

Now things start to be interesting, and I can query the graph for many
interesting things. For example, what are all the people `antirez`
*is friend to*?

    ZRANGEBYLEX myindex "[sop:antirez:" "[sop:antirez:\xff"

Or, what are all the relationships `antirez` and` mcollina` have where
the first is the subject and the second is the object?

    ZRANGEBYLEX myindex "[sop:antirez:mcollina:" "[sop:antirez:mcollina:\xff"

By combining different queries, I can ask fancy questions. For example:
*What are all my friends that, like beer, live in Barcellona, and mcollina consider friends as well?*
To get this information I start with an `spo` query to find all the people
I'm friend with. Than for each result I get I perform an `spo` query
to check if they like beer, removing the ones for which I can't find
this relation. I do it again to filter by city. Finally I perform an `ops`
query to find, of the list I obtained, who is considered friend by
mcollina.

Make sure to check [Matteo Collina's slides about Levelgraph](http://nodejsconfit.levelgraph.io/) in order to better understand these ideas.

Non range indexes
===

So far we checked indexes which are useful to query by range or by single
item. However other Redis data structures such as Sets or Lists can be used
in order to build indexes working in different ways.

For instance I can index object IDs into a Set data type in order to use
the *get random elements* operation via `SRANDMEMBER` in order to retrieve
a set of random objects. Sets can also be used to check for existence when
all I need is to test if a given item exists or not or has a single boolean
property or not.

Similarly lists can be used in order to index items into a fixed order,
so I can add all my items into a bit list and rotate the list with
RPOPLPUSH using the same list as source and destination. This is useful
when I want to process a given set of items again and again forever. Think
at an RSS feed system that need to refresh the local copy.

Another popular index often used for Redis is a **capped list**, where items
are added with `LPUSH` and trimmed `LTRIM`, in order to create a view
with just the latest N items encountered.

Index inconsistency
===

Keeping the index updated may be challenging, in the course of months
or years it is possible that inconsistency are added because of software
bugs, network partitions or other events.

Different strategies could be used. If the index data is outside Redis
*read reapir* can be a solution, where data is fixed in a lazy way when
it is requested. When we index data which is stored in Redis itself
the `SCAN` family of commands can be used in order to very, update or
rebuild the index from scratch.
