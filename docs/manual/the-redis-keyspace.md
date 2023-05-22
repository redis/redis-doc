---
title: "The Redis keyspace"
linkTitle: "The Redis Keyspace"
weight: 1
description: >
    Managing keys in Redis: Key expiration, scanning, altering and querying the key space
---

Redis keys are binary safe; this means that you can use any binary sequence as a
key, from a string like "foo" to the content of a JPEG file.
The empty string is also a valid key.

A few other rules about keys:

* Very long keys are not a good idea. For instance a key of 1024 bytes is a bad
  idea not only memory-wise, but also because the lookup of the key in the
  dataset may require several costly key-comparisons. Even when the task at hand
  is to match the existence of a large value, hashing it (for example
  with SHA1) is a better idea, especially from the perspective of memory
  and bandwidth.
* Very short keys are often not a good idea. There is little point in writing
  "u1000flw" as a key if you can instead write "user:1000:followers".  The latter
  is more readable and the added space is minor compared to the space used by
  the key object itself and the value object. While short keys will obviously
  consume a bit less memory, your job is to find the right balance.
* Try to stick with a schema. For instance "object-type:id" is a good
  idea, as in "user:1000". Dots or dashes are often used for multi-word
  fields, as in "comment:4321:reply.to" or "comment:4321:reply-to".
* The maximum allowed key size is 512 MB.

## Altering and querying the key space

There are commands that are not defined on particular types, but are useful
in order to interact with the space of keys, and thus, can be used with
keys of any type.

For example the `EXISTS` command returns 1 or 0 to signal if a given key
exists or not in the database, while the `DEL` command deletes a key
and associated value, whatever the value is.

    > set mykey hello
    OK
    > exists mykey
    (integer) 1
    > del mykey
    (integer) 1
    > exists mykey
    (integer) 0

From the examples you can also see how `DEL` itself returns 1 or 0 depending on whether
the key was removed (it existed) or not (there was no such key with that
name).

There are many key space related commands, but the above two are the
essential ones together with the `TYPE` command, which returns the kind
of value stored at the specified key:

    > set mykey x
    OK
    > type mykey
    string
    > del mykey
    (integer) 1
    > type mykey
    none

## Key expiration

Before moving on, we should look at an important Redis feature that works regardless of the type of value you're storing: key expiration. Key expiration lets you set a timeout for a key, also known as a "time to live", or "TTL". When the time to live elapses, the key is automatically destroyed. 

A few important notes about key expiration:

* They can be set both using seconds or milliseconds precision.
* However the expire time resolution is always 1 millisecond.
* Information about expires are replicated and persisted on disk, the time virtually passes when your Redis server remains stopped (this means that Redis saves the date at which a key will expire).

Use the `EXPIRE` command to set a key's expiration:

    > set key some-value
    OK
    > expire key 5
    (integer) 1
    > get key (immediately)
    "some-value"
    > get key (after some time)
    (nil)

The key vanished between the two `GET` calls, since the second call was
delayed more than 5 seconds. In the example above we used `EXPIRE` in
order to set the expire (it can also be used in order to set a different
expire to a key already having one, like `PERSIST` can be used in order
to remove the expire and make the key persistent forever). However we
can also create keys with expires using other Redis commands. For example
using `SET` options:

    > set key 100 ex 10
    OK
    > ttl key
    (integer) 9

The example above sets a key with the string value `100`, having an expire
of ten seconds. Later the `TTL` command is called in order to check the
remaining time to live for the key.

In order to set and check expires in milliseconds, check the `PEXPIRE` and
the `PTTL` commands, and the full list of `SET` options.

## Navigating the keyspace

### Scan
To incrementally  iterate over the keys in a Redis database in an efficient manner, you can use the `SCAN` command.

Since `SCAN` allows for incremental iteration, returning only a small number of elements per call, it can be used in production without the downside of commands like `KEYS` or `SMEMBERS` that may block the server for a long time (even several seconds) when called against big collections of keys or elements.

However while blocking commands like `SMEMBERS` are able to provide all the elements that are part of a Set in a given moment, The SCAN family of commands only offer limited guarantees about the returned elements since the collection that we incrementally iterate can change during the iteration process.

#### SCAN basic usage

SCAN is a cursor based iterator. This means that at every call of the command, the server returns an updated cursor that the user needs to use as the cursor argument in the next call.

An iteration starts when the cursor is set to 0, and terminates when the cursor returned by the server is 0. The following is an example of SCAN iteration:

```
redis 127.0.0.1:6379> scan 0
1) "17"
2)  1) "key:12"
    2) "key:8"
    3) "key:4"
    4) "key:14"
    5) "key:16"
    6) "key:17"
    7) "key:15"
    8) "key:10"
    9) "key:3"
   10) "key:7"
   11) "key:1"
redis 127.0.0.1:6379> scan 17
1) "0"
2) 1) "key:5"
   2) "key:18"
   3) "key:0"
   4) "key:2"
   5) "key:19"
   6) "key:13"
   7) "key:6"
   8) "key:9"
   9) "key:11"
```

In the example above, the first call uses zero as a cursor, to start the iteration. The second call uses the cursor returned by the previous call as the first element of the reply, that is, 17.

As you can see the **SCAN return value** is an array of two values: the first value is the new cursor to use in the next call, the second value is an array of elements.

Since in the second call the returned cursor is 0, the server signaled to the caller that the iteration finished, and the collection was completely explored. Starting an iteration with a cursor value of 0, and calling `SCAN` until the returned cursor is 0 again is called a **full iteration**.

#### Scan guarantees

The `SCAN` command, and the other commands in the `SCAN` family, are able to provide to the user a set of guarantees associated to full iterations.

* A full iteration always retrieves all the elements that were present in the collection from the start to the end of a full iteration. This means that if a given element is inside the collection when an iteration is started, and is still there when an iteration terminates, then at some point `SCAN` returned it to the user.
* A full iteration never returns any element that was NOT present in the collection from the start to the end of a full iteration. So if an element was removed before the start of an iteration, and is never added back to the collection for all the time an iteration lasts, `SCAN` ensures that this element will never be returned.

However because `SCAN` has very little state associated (just the cursor) it has the following drawbacks:

* A given element may be returned multiple times. It is up to the application to handle the case of duplicated elements, for example only using the returned elements in order to perform operations that are safe when re-applied multiple times.
* Elements that were not constantly present in the collection during a full iteration, may be returned or not: it is undefined.

#### Number of elements returned at every SCAN call

`SCAN` family functions do not guarantee that the number of elements returned per call are in a given range. The commands are also allowed to return zero elements, and the client should not consider the iteration complete as long as the returned cursor is not zero.

However the number of returned elements is reasonable, that is, in practical terms SCAN may return a maximum number of elements in the order of a few tens of elements when iterating a large collection, or may return all the elements of the collection in a single call when the iterated collection is small enough to be internally represented as an encoded data structure (this happens for small sets, hashes and sorted sets).

However there is a way for the user to tune the order of magnitude of the number of returned elements per call using the **COUNT** option.

#### The COUNT option

While `SCAN` does not provide guarantees about the number of elements returned at every iteration, it is possible to empirically adjust the behavior of `SCAN` using the **COUNT** option. Basically with COUNT the user specified the *amount of work that should be done at every call in order to retrieve elements from the collection*. This is **just a hint** for the implementation, however generally speaking this is what you could expect most of the times from the implementation.

* The default COUNT value is 10.
* When iterating the key space, or a Set, Hash or Sorted Set that is big enough to be represented by a hash table, assuming no **MATCH** option is used, the server will usually return *count* or a bit more than *count* elements per call. Please check the *why SCAN may return all the elements at once* section later in this document.
* When iterating Sets encoded as intsets (small sets composed of just integers), or Hashes and Sorted Sets encoded as ziplists (small hashes and sets composed of small individual values), usually all the elements are returned in the first `SCAN` call regardless of the COUNT value.

Important: **there is no need to use the same COUNT value** for every iteration. The caller is free to change the count from one iteration to the other as required, as long as the cursor passed in the next call is the one obtained in the previous call to the command.

#### The MATCH option

It is possible to only iterate elements matching a given glob-style pattern, similarly to the behavior of the `KEYS` command that takes a pattern as its only argument.

To do so, just append the `MATCH <pattern>` arguments at the end of the `SCAN` command (it works with all the SCAN family commands).

This is an example of iteration using **MATCH**:

```
redis 127.0.0.1:6379> sadd myset 1 2 3 foo foobar feelsgood
(integer) 6
redis 127.0.0.1:6379> sscan myset 0 match f*
1) "0"
2) 1) "foo"
   2) "feelsgood"
   3) "foobar"
redis 127.0.0.1:6379>
```

It is important to note that the **MATCH** filter is applied after elements are retrieved from the collection, just before returning data to the client. This means that if the pattern matches very little elements inside the collection, `SCAN` will likely return no elements in most iterations. An example is shown below:

```
redis 127.0.0.1:6379> scan 0 MATCH *11*
1) "288"
2) 1) "key:911"
redis 127.0.0.1:6379> scan 288 MATCH *11*
1) "224"
2) (empty list or set)
redis 127.0.0.1:6379> scan 224 MATCH *11*
1) "80"
2) (empty list or set)
redis 127.0.0.1:6379> scan 80 MATCH *11*
1) "176"
2) (empty list or set)
redis 127.0.0.1:6379> scan 176 MATCH *11* COUNT 1000
1) "0"
2)  1) "key:611"
    2) "key:711"
    3) "key:118"
    4) "key:117"
    5) "key:311"
    6) "key:112"
    7) "key:111"
    8) "key:110"
    9) "key:113"
   10) "key:211"
   11) "key:411"
   12) "key:115"
   13) "key:116"
   14) "key:114"
   15) "key:119"
   16) "key:811"
   17) "key:511"
   18) "key:11"
redis 127.0.0.1:6379>
```

As you can see most of the calls returned zero elements, but the last call where a COUNT of 1000 was used in order to force the command to do more scanning for that iteration.


#### The TYPE option

You can use the `!TYPE` option to ask `SCAN` to only return objects that match a given `type`, allowing you to iterate through the database looking for keys of a specific type. The **TYPE** option is only available on the whole-database `SCAN`, not `HSCAN` or `ZSCAN` etc.

The `type` argument is the same string name that the `TYPE` command returns. Note a quirk where some Redis types, such as GeoHashes, HyperLogLogs, Bitmaps, and Bitfields, may internally be implemented using other Redis types, such as a string or zset, so can't be distinguished from other keys of that same type by `SCAN`. For example, a ZSET and GEOHASH:

```
redis 127.0.0.1:6379> GEOADD geokey 0 0 value
(integer) 1
redis 127.0.0.1:6379> ZADD zkey 1000 value
(integer) 1
redis 127.0.0.1:6379> TYPE geokey
zset
redis 127.0.0.1:6379> TYPE zkey
zset
redis 127.0.0.1:6379> SCAN 0 TYPE zset
1) "0"
2) 1) "geokey"
   2) "zkey"
```

It is important to note that the **TYPE** filter is also applied after elements are retrieved from the database, so the option does not reduce the amount of work the server has to do to complete a full iteration, and for rare types you may receive no elements in many iterations.

#### Multiple parallel iterations

It is possible for an infinite number of clients to iterate the same collection at the same time, as the full state of the iterator is in the cursor, that is obtained and returned to the client at every call. No server side state is taken at all.

#### Terminating iterations in the middle

Since there is no state server side, but the full state is captured by the cursor, the caller is free to terminate an iteration half-way without signaling this to the server in any way. An infinite number of iterations can be started and never terminated without any issue.

#### Calling SCAN with a corrupted cursor

Calling `SCAN` with a broken, negative, out of range, or otherwise invalid cursor, will result in undefined behavior but never in a crash. What will be undefined is that the guarantees about the returned elements can no longer be ensured by the `SCAN` implementation.

The only valid cursors to use are:

* The cursor value of 0 when starting an iteration.
* The cursor returned by the previous call to SCAN in order to continue the iteration.

#### Guarantee of termination

The `SCAN` algorithm is guaranteed to terminate only if the size of the iterated collection remains bounded to a given maximum size, otherwise iterating a collection that always grows may result into `SCAN` to never terminate a full iteration.

This is easy to see intuitively: if the collection grows there is more and more work to do in order to visit all the possible elements, and the ability to terminate the iteration depends on the number of calls to `SCAN` and its COUNT option value compared with the rate at which the collection grows.

#### Why SCAN may return all the items of an aggregate data type in a single call?

In the `COUNT` option documentation, we state that sometimes this family of commands may return all the elements of a Set, Hash or Sorted Set at once in a single call, regardless of the `COUNT` option value. The reason why this happens is that the cursor-based iterator can be implemented, and is useful, only when the aggregate data type that we are scanning is represented as a hash table. However Redis uses a [memory optimization](/topics/memory-optimization) where small aggregate data types, until they reach a given amount of items or a given max size of single elements, are represented using a compact single-allocation packed encoding. When this is the case, `SCAN` has no meaningful cursor to return, and must iterate the whole data structure at once, so the only sane behavior it has is to return everything in a call.

However once the data structures are bigger and are promoted to use real hash tables, the `SCAN` family of commands will resort to the normal behavior. Note that since this special behavior of returning all the elements is true only for small aggregates, it has no effects on the command complexity or latency. However the exact limits to get converted into real hash tables are [user configurable](/topics/memory-optimization), so the maximum number of elements you can see returned in a single call depends on how big an aggregate data type could be and still use the packed representation.

Also note that this behavior is specific of `SSCAN`, `HSCAN` and `ZSCAN`. `SCAN` itself never shows this behavior because the key space is always represented by hash tables.

### Keys

Another way to iterate over the keyspace is to use the `KEYS` command, but this approach should be used with care, since `KEYS` will block the Redis server until all keys are returned.

**Warning**: consider `KEYS` as a command that should only be used in production
environments with extreme care.

`KEYS` may ruin performance when it is executed against large databases.
This command is intended for debugging and special operations, such as changing
your keyspace layout.
Don't use `KEYS` in your regular application code.
If you're looking for a way to find keys in a subset of your keyspace, consider
using `SCAN` or [sets][tdts].

[tdts]: /topics/data-types#sets

Supported glob-style patterns:

* `h?llo` matches `hello`, `hallo` and `hxllo`
* `h*llo` matches `hllo` and `heeeello`
* `h[ae]llo` matches `hello` and `hallo,` but not `hillo`
* `h[^e]llo` matches `hallo`, `hbllo`, ... but not `hello`
* `h[a-b]llo` matches `hallo` and `hbllo`

Use `\` to escape special characters if you want to match them verbatim.
