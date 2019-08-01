# Redis server-assisted client side caching

Client side caching is a technique used in order to create high performance
services. It exploits the available memory in the application servers, that
usually are distinct computers compared to the database nodes, in order to
store some subset of the database information directly in the application side.

Normally when some data is required, the application servers will ask the
database about such information, like in the following picture:


    +-------------+                                +----------+
    |             | ------- GET user:1234 -------> |          |
    | Application |                                | Database |
    |             | <---- username = Alice ------- |          |
    +-------------+                                +----------+

When client side caching is used, the application will store the reply of
popular queries directily inside the application memory, so that it can
reuse such replies later, without contacting the database again.

    +-------------+                                +----------+
    |             |                                |          |
    | Application |       ( No chat needed )       | Database |
    |             |                                |          |
    +-------------+                                +----------+
    | Local cache |
    |             |
    | user:1234 = |
    | username    |
    | Alice       |
    +-------------+

While the application memory used for the local cache may not be very big,
the time needed in order to access the local computer memory is orders of
magnitude smaller compared to asking a networked service like a database.
Since often the same small percentage of data are accessed very frequently
this pattern can greatly reduce the latency for the application to get data
and, at the same time, the load in the database side.

## There are only two big problems in computer science...

A problem with the above pattern is how to invalidate the information that
the application is holding, in order to avoid presenting to the user stale
data. For example after the application above locally cached the user:1234
information, Alice may update her username to Flora. Yet the application
may continue to serve the old username for user 1234.

Sometimes this problem is not a big deal, so the client will just use a
"time to live" for the cached information. Once a given amount of time has
elapsed, the information will no longer be considered valid. More complex
patterns, when using Redis, leverage Pub/Sub messages in order to
send invalidation messages to clients listening. This can be made to work
but is tricky and costly from the point of view of the bandwidth used, because
often such patterns involve sending the invalidation messages to every client
in the application, even if certain clients may not have any copy of the
invalidated data.

Regardless of what schema is used, there is however a simple fact: many
very large applications implement some form of client side caching, because
it is the next logical step to having a fast store or a fast cache server.
Once clients can retrieve an important amount of information without even
asking a networked server at all, but just accessing their local memory,
then it is possible to fetch more data per second (since many queries will
not hit the database or the cache at all) with much smaller latency.
For this reason Redis 6 implements direct support for client side cachig,
in order to make this pattern much simpler to implement, more accessible,
reliable and efficient.

## The Redis implementation of client side caching

The Redis client side caching support is called _Tracking_. It basically
consist in a few very simple ideas:

1. Clients can enable tracking if they want. Connections start without tracking enabled.
2. When tracking is enabled, the server remembers what keys each client requseted during the connection lifetime (by sending read commands about such keys).
3. When a key is modified by some client, or is evicted because it has an associated expire time, or evicted because of a _maxmemory_ policy, all the clients with tracking enabled that may have the key cached, are notified with an _invalidation message_.
4. When clients receive invalidation messages, they are required to remove the corresponding keys, in order to avoid serving stale data.

This is an example of the protocol (the actual details are very different as you'll discover reading this document till the end):

* Client 1 `->` Server: CLIENT TRACKING ON
* Client 1 `->` Server: GET foo
* (The server remembers that Client 1 may have the key "foo" cached)
* (Client 1 may remember the value of "foo" inside its local memory)
* Client 2 `->` Server: SET foo SomeOtherValue
* Server `->` Client 1: INVALIDATE "foo"

While this is the general idea, the actual implementation and the details are very different, because the vanilla implementation of what exposed above would be extremely inefficient. For instance a Redis instance may have 10k clients all caching 1 million keys each. In such situation Redis would be required to remember 10 billions distinct informations, including the key name itself, which could be quite expensive. Moreover once a client disconnects, there is to garbage collect all the no longer useful information associated with it.

In order to make client side caching more viable the Redis actual
implementation uses the following ideas:

* The keyspace is divided into a bit more than 16 millions caching slots. Given a key, the caching slot is obtained by taking the CRC64(key) modulo 16777216 (this basically means that just the lower 24 bits of the result are taken).
* The server remembers which client may have cached keys about a given caching slots. To do so we just need a table with 16 millions of entries (one for each caching slot), associated with a dictionary of all the clients that may have keys about it. This table is called the **Invalidation Table**.
* Inside the invalidation table we don't really need to store pointers to clients structures and do any garbage collection when the client disconnects: instead what we do is just storing client IDs (each Redis client has an unique numberical ID). If a client disconnects, the information will be incrementally garbage collected as caching slots are invalidated.

This means that clients also have to organize their local cache according to the caching slots, so that when they receive an invalidation message about a given caching slot, such group of keys are no longer considered valid.

Another advantage of caching slots, other than being more space efficient, is that, once the user memory in the server side in order to track client side information become too big, it is very simple to release some memory, just picking a random caching slot and evicting it, even if there was no actual modification hitting any key of such caching slot.

Note that by using 16 millions of caching slots, it is still possible to have plenty of keys per instance, with just a few keys hashing to the same caching slot: this means that invalidation messages will expire just a couple of keys in the avareage case, even if the instance has tens of millions of keys.

## Two connections mode

Using the new version of the Redis protocol, RESP3, supported by Redis 6, it is possible to run the data queries and receive the invalidation messages in the same connection. However many client implementations may prefer to implement client side caching using two separated connections: one for data, and one for invalidation messages. For this reason when a client enables tracking, it can specify to redirect the invalidation messages to another connection by specifying the "client ID" of different connection. Many data connections can redirect invalidation messages to the same connection, this is useful for clients implementing connection pooling. The two connections model is the only one that is also supported for RESP2 (that lacks the ability to multiplex different kind of information in the same connection).

We'll show an example, this time by using the actual Redis protocol in the old RRESP2 mode, how a complete session, involving the following steps: enabling tracking redirecting to another connection, asking for a key, and getting an invalidation message once such key gets modified.

## Opt-in caching

## When client side caching makes sense

# Implementing client side caching in client libraries

## What to cache

## Limiting the amount of memory used by clients

## Avoiding race conditions
