Partitioning: how to split data among multiple Redis instances.
===

Partitioning is the process of splitting your data into multiple Redis instances, so that every instance will only contain a subset of your keys. The first part of this document will introduce you to the concept of partitioning, the second part will show you the alternatives for Redis partitioning.

Why partitioning is useful
---

Partitioning in Redis serves two main goals:

* It allows for much larger databases, using the sum of the memory of many computers. Without partitioning you are limited to the amount of memory a single computer can support.
* It allows to scale the computational power to multiple cores and multiple computers, and the network bandwidth to multiple computers and network adapters.

Partitioning basics
---

There are different partitioning criteria. Imagine we have four Redis instances **R0**, **R1**, **R2**, **R3**, and many keys representing users like `user:1`, `user:2`, ... and so forth, we can find different ways to select in which instance we store a given key. In other words there are *different systems to map* a given key to a given Redis server.

One of the simplest way to perform partitioning is called **range partitioning**, and is accomplished by mapping ranges of objects into specific Redis instances. For example I could say, users from ID 0 to ID 10000 will go into instance **R0**, while users form ID 10001 to ID 20000 will go into instance **R1** and so forth.

This systems works and is actually used in practice, however it has the disadvantage that there is to take a table mapping ranges to instances. This table needs to be managed and we need a table for every kind of object we have. Usually with Redis it is not a good idea.

An alternative to to range partitioning is **hash partitioning**. This scheme works with any key, no need for a key in the form `object_name:<id>` as is as simple as this:

* Take the key name and use an hash function to turn it into a number. For instance I could use the `crc32` hash function. So if the key is `foobar` I do `crc32(foobar)` that will output something like 93024922.
* I use a modulo operation with this number in order to turn it into a number between 0 and 3, so that I can map this number to one of the four Redis instances I've. So `93024922 modulo 4` equals 2, so I know my key `foobar` should be stored into the **R2** instance. *Note: the modulo operation is just the rest of the division, usually it is implemented by the `%` operator in many programming languages.*

There are many other ways to perform partitioning, but with this two examples you should get the idea. One advanced form of hash partitioning is called **consistent hashing** and is implemented by a few Redis clients and proxies.

Different implementations of partitioning
---

Partitioning can be responsibility of different parts of a software stack.

* **Client side partitioning** means that the clients directly select the right node where to write or read a given key. Many Redis clients implement client side partitioning.
* **Proxy assisted partitioning** means that our clients send requests to a proxy that is able to speak the Redis protocol, instead of sending requests directly to the right Redis instance. The proxy will make sure to forward our request to the right Redis instance accordingly to the configured partitioning schema, and will send the replies back to the client. The Redis and Memcached proxy [Twemproxy](https://github.com/twitter/twemproxy) implements proxy assisted partitioning.
* **Query routing** means that you can send your query to a random instance, and the instance will make sure to forward your query to the right node. Redis Cluster implements an hybrid form of query routing, with the help of the client (the request is not directly forwarded from a Redis instance to another, but the client gets *redirected* to the right node).

Disadvantages of partitioning
---

Some features of Redis don't play very well with partitioning:

* Operations involving multiple keys are usually not supported. For instance you can't perform the intersection between two sets if they are stored in keys that are mapped to different Redis instances (actually there are ways to do this, but not directly).
* Redis transactions involving multiple keys can not be used.
* The partitioning granuliary is the key, so it is not possible to shard a dataset with a single huge key like a very big sorted set.
* When partitioning is used, data handling is more complex, for instance you have to handle multiple RDB / AOF files, and to make a backup of your data you need to aggregate the persistence files from multiple instances and hosts.
* Adding and removing capacity can be complex. For instance Redis Cluster plans to support mostly transparent rebalancing of data with the ability to add and remove nodes at runtime, but other systems like client side partitioning and proxies don't support this feature. However a technique called *Presharding* helps in this regard.

Data store or cache?
---

Partitioning when using Redis ad a data store or cache is conceptually the same, however there is a huge difference. While when Redis is used as a data store you need to be sure that a given key always maps to the same instance, when Redis is used as a cache if a given node is unavailable it is not a big problem if we start using a different node, altering the key-instance map as we wish to improve the *availability* of the system (that is, the ability of the system to reply to our queries).

Consistent hashing implementations are often able to switch to other nodes if the preferred node for a given key is not available. Similarly if you add a new node, part of the new keys will start to be stored on the new node.

The main concept here is the following:

* If Redis is used as a cache **scaling up and down** using consistent hashing is easy.
* If Redis is used as a store, **we need to take the map between keys and nodes fixed, and a fixed number of nodes**. Otherwise we need a system that is able to rebalance keys between nodes when we add or remove nodes, and currently only Redis Cluster is able to do this, but Redis Cluster is not production ready.

Presharding
---

We learned that a problem with partitioning is that, unless we are using Redis as a cache, to add and remove nodes can be tricky, and it is much simpler to use a fixed keys-instances map.

However the data storage needs may vary over the time. Today I can live with 10 Redis nodes (instances), but tomorrow I may need 50 nodes.

Since Redis is extremely small footprint and lightweight (a spare instance uses 1 MB of memory), a simple approach to this problem is to start with a lot of instances since the start. Even if you start with just one server, you can decide to live in a distributed world since your first day, and run multiple Redis instances in your single server, using partitioning.

And you can select this number of instances to be quite big since the start. For example, 32 or 64 instances could do the trick for most users, and will provide enough room for growth.

In this way as your data storage needs increase and you need more Redis servers, what to do is to simply move instances from one server to another. Once you add the first additional server, you will need to move half of the Redis instances from the first server to the second, and so forth.

Using Redis replication you will likely be able to do the move with minimal or no downtime for your users:

* Start empty instances in your new server.
* Move data configuring these new instances as slaves for your source instances.
* Stop your clients.
* Update the configuration of the moved instances with the new server IP address.
* Send the `SLAVEOF NO ONE` command to the slaves in the new server.
* Restart your clients with the new updated configuration.
* Finally shut down the no longer used instances in the old server.

Implementations of Redis partitioning
===

So far we covered Redis partitioning in theory, but what about practice? What system should you use?

Redis Cluster
---

Unfortunately Redis Cluster is currently not production ready, however you can get more information about it [reading the specification](/topics/cluster-spec) or checking the partial implementation in the `unstable` branch of the Redis GitHub repositoriy.

Once Redis Cluster will be available, and if a Redis Cluster complaint client is available for your language, Redis Cluster will be the de facto standard for Redis partitioning.

Redis Cluster is a mix between *query routing* and *client side partitioning*.

Twemproxy
---

[Twemproxy is a proxy developed at Twitter](https://github.com/twitter/twemproxy) for the Memcached ASCII and the Redis protocol. It is single threaded, it is written in C, and is extremely fast. It is open source software released under the terms of the Apache 2.0 license.

Twemproxy supports automatic partitioning among multiple Redis instances, with optional node ejection if a node is not available (this will change the keys-instances map, so you should use this feature only if you are using Redis as a cache).

It is *not* a single point of failure since you can start multiple proxies and instruct your clients to connect to the first that accepts the connection.

Basically Twemproxy is an intermediate layer between clients and Redis instances, that will reliably handle partitioning for us with minimal additional complexities. Currently it is the **suggested way to handle partitioning with Redis**.

You can read more about Twemproxy [in this antirez blog post](http://antirez.com/news/44).

Clients supporting consistent hashing
---

An alternative to Twemproxy is to use a client that implements client side partitioning via consistent hashing or other similar algorithms. There are multiple Redis clients with support for consistent hashing, notably [Redis-rb](https://github.com/redis/redis-rb) and [Predis](https://github.com/nrk/predis).

Please check the [full list of Redis clients](http://redis.io/clients) to check if there is a mature client with consistent hashing implementation for your language.
