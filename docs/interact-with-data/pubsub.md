---
title: Redis Pub/Sub
linkTitle: "Pub/sub"
weight: 40
description: How to use pub/sub channels in Redis
aliases:
  - /topics/pubsub
  - /docs/manual/pub-sub
---

`SUBSCRIBE`, `UNSUBSCRIBE` and `PUBLISH` implement the [Publish/Subscribe messaging paradigm](http://en.wikipedia.org/wiki/Publish/subscribe) where (citing Wikipedia) senders (publishers) are not programmed to send their messages to specific receivers (subscribers).
Rather, published messages are characterized into channels, without knowledge of what (if any) subscribers there may be.
Subscribers express interest in one or more channels and only receive messages that are of interest, without knowledge of what (if any) publishers there are.
This decoupling of publishers and subscribers allows for greater scalability and a more dynamic network topology.

For instance, to subscribe to channels "channel11" and "ch:00" the client issues a `SUBSCRIBE` providing the names of the channels:

```bash
SUBSCRIBE channel11 ch:00
```

Messages sent by other clients to these channels will be pushed by Redis to all the subscribed clients.
Subscribers receive the messages in the order that the messages are published.

A client subscribed to one or more channels shouldn't issue commands, although it can `SUBSCRIBE` and `UNSUBSCRIBE` to and from other channels.
The replies to subscription and unsubscribing operations are sent in the form of messages so that the client can just read a coherent stream of messages where the first element indicates the type of message.
The commands that are allowed in the context of a subscribed RESP2 client are:

* `PING`
* `PSUBSCRIBE`
* `PUNSUBSCRIBE`
* `QUIT`
* `RESET`
* `SSUBSCRIBE`
* `SUBSCRIBE`
* `SUNSUBSCRIBE`
* `UNSUBSCRIBE`

However, if RESP3 is used (see `HELLO`), a client can issue any commands while in the subscribed state.

Please note that when using `redis-cli`, in subscribed mode commands such as `UNSUBSCRIBE` and `PUNSUBSCRIBE` cannot be used because `redis-cli` will not accept any commands and can only quit the mode with `Ctrl-C`.

## Delivery semantics

Redis' Pub/Sub exhibits _at-most-once_ message delivery semantics.
As the name suggests, it means that a message will be delivered once if at all.
Once the message is sent by the Redis server, there's no chance of it being sent again.
If the subscriber is unable to handle the message (for example, due to an error or a network disconnect) the message is forever lost.

If your application requires stronger delivery guarantees, you may want to learn about [Redis Streams](/docs/data-types/streams-tutorial).
Messages in streams are persisted, and support both _at-most-once_ as well as _at-least-once_ delivery semantics.

## Format of pushed messages

A message is an [array-reply](/topics/protocol#array-reply) with three elements.

The first element is the kind of message:

* `subscribe`: means that we successfully subscribed to the channel given as the second element in the reply.
  The third argument represents the number of channels we are currently subscribed to.

* `unsubscribe`: means that we successfully unsubscribed from the channel given as second element in the reply.
  The third argument represents the number of channels we are currently subscribed to.
  When the last argument is zero, we are no longer subscribed to any channel, and the client can issue any kind of Redis command as we are outside the Pub/Sub state.

* `message`: it is a message received as a result of a `PUBLISH` command issued by another client.
  The second element is the name of the originating channel, and the third argument is the actual message payload.

## Database & Scoping

Pub/Sub has no relation to the key space.
It was made to not interfere with it on any level, including database numbers.

Publishing on db 10, will be heard by a subscriber on db 1.

If you need scoping of some kind, prefix the channels with the name of the environment (test, staging, production...).

## Wire protocol example

```
SUBSCRIBE first second
*3
$9
subscribe
$5
first
:1
*3
$9
subscribe
$6
second
:2
```

At this point, from another client we issue a `PUBLISH` operation against the channel named `second`:

```
> PUBLISH second Hello
```

This is what the first client receives:

```
*3
$7
message
$6
second
$5
Hello
```

Now the client unsubscribes itself from all the channels using the `UNSUBSCRIBE` command without additional arguments:

```
UNSUBSCRIBE
*3
$11
unsubscribe
$6
second
:1
*3
$11
unsubscribe
$5
first
:0
```

## Pattern-matching subscriptions

The Redis Pub/Sub implementation supports pattern matching.
Clients may subscribe to glob-style patterns to receive all the messages sent to channel names matching a given pattern.

For instance:

```
PSUBSCRIBE news.*
```

Will receive all the messages sent to the channel `news.art.figurative`, `news.music.jazz`, etc.
All the glob-style patterns are valid, so multiple wildcards are supported.

```
PUNSUBSCRIBE news.*
```

Will then unsubscribe the client from that pattern.
No other subscriptions will be affected by this call.

Messages received as a result of pattern matching are sent in a different format:

* The type of the message is `pmessage`: it is a message received as a result from a `PUBLISH` command issued by another client, matching a pattern-matching subscription. 
  The second element is the original pattern matched, the third element is the name of the originating channel, and the last element is the actual message payload.

Similarly to `SUBSCRIBE` and `UNSUBSCRIBE`, `PSUBSCRIBE` and `PUNSUBSCRIBE` commands are acknowledged by the system sending a message of type `psubscribe` and `punsubscribe` using the same format as the `subscribe` and `unsubscribe` message format.

## Messages matching both a pattern and a channel subscription

A client may receive a single message multiple times if it's subscribed to multiple patterns matching a published message, or if it is subscribed to both patterns and channels matching the message. 
This is shown by the following example:

```
SUBSCRIBE foo
PSUBSCRIBE f*
```

In the above example, if a message is sent to channel `foo`, the client will receive two messages: one of type `message` and one of type `pmessage`.

## The meaning of the subscription count with pattern matching

In `subscribe`, `unsubscribe`, `psubscribe` and `punsubscribe` message types, the last argument is the count of subscriptions still active. 
This number is the total number of channels and patterns the client is still subscribed to. 
So the client will exit the Pub/Sub state only when this count drops to zero as a result of unsubscribing from all the channels and patterns.

## Sharded Pub/Sub

From Redis 7.0, sharded Pub/Sub is introduced in which shard channels are assigned to slots by the same algorithm used to assign keys to slots. 
A shard message must be sent to a node that owns the slot the shard channel is hashed to. 
The cluster makes sure the published shard messages are forwarded to all nodes in the shard, so clients can subscribe to a shard channel by connecting to either the master responsible for the slot, or to any of its replicas.
`SSUBSCRIBE`, `SUNSUBSCRIBE` and `SPUBLISH` are used to implement sharded Pub/Sub.

Sharded Pub/Sub helps to scale the usage of Pub/Sub in cluster mode. 
It restricts the propagation of messages to be within the shard of a cluster. 
Hence, the amount of data passing through the cluster bus is limited in comparison to global Pub/Sub where each message propagates to each node in the cluster.
This allows users to horizontally scale the Pub/Sub usage by adding more shards.
 
## Programming example

Pieter Noordhuis provided a great example using EventMachine and Redis to create [a multi user high performance web chat](https://gist.github.com/pietern/348262).

## Client library implementation hints

Because all the messages received contain the original subscription causing the message delivery (the channel in the case of message type, and the original pattern in the case of pmessage type) client libraries may bind the original subscription to callbacks (that can be anonymous functions, blocks, function pointers), using a hash table.

When a message is received an O(1) lookup can be done to deliver the message to the registered callback.
