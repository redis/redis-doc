---
title: "Java guide"
linkTitle: "Java"
description: Connect your Java application to a Redis database
weight: 3

---

Install Redis and the Redis client, then connect your Java application to a Redis database. 

## Jedis

[Jedis](https://github.com/redis/jedis) is a Java client for Redis designed for performance and ease of use.

### Install

To include `Jedis` as a dependency in your application, you can:

* Use the JAR files - Download the latest Jedis and Apache Commons Pool2 JAR files from search.maven.org or any other Maven repository.

* Build from source - You get the most recent version.

* Clone the GitHub project - Very easy; on the command line, you just need to `git clone git://github.com/xetorthio/jedis.git`.

* Build from GitHub - Before you package it using maven, you have to pass the tests. To run the tests and package, run `make package`.

### Configure a Maven dependency

Jedis is also distributed as a Maven dependency through Sonatype. To configure this dependency, just add the following XML snippet to your `pom.xml` file.

```XML
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>2.9.0</version>
    <type>jar</type>
    <scope>compile</scope>
</dependency>
```
### Connect

#### Install a Redis Stack Docker

```
docker run -p 6379:6379 -it redis/redis-stack:latest
```

For many applications, it's best to use a connection pool. But `Jedis` also lets you connect to Redis Clusters, supporting the Redis Cluster Specification.


#### Instantiate a Jedis connection pool

You can instantiate a `Jedis` connection pool like so:

```
JedisPool pool = new JedisPool("localhost", 6379);
```

With a JedisPool instance, you can use a [`try-with-resources` block](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) to get a connection and run Redis commands.

Here's how to run a single `SET` command within a `try-with-resources` block:

```java
try (Jedis jedis = pool.getResource()) {
  jedis.set("clientName", "Jedis");
}
```

`Jedis` instances implement most Redis commands. See the [Jedis Javadocs](https://www.javadoc.io/doc/redis.clients/jedis/latest/redis/clients/jedis/Jedis.html) for the complete list of supported commands.

Using a `try-with-resources` block for each command may be cumbersome, so you may consider using JedisPooled as an easier way of using connection pool.

```
JedisPooled jedis = new JedisPooled("localhost", 6379);
```

Now you can send Redis commands from `Jedis`.

```java
jedis.sadd("planets", "Venus");
```

#### Connect to a Redis cluster

 To connect to a Redis cluster, use `JedisCluster`. 

```
Set<HostAndPort> jedisClusterNodes = new HashSet<HostAndPort>();
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7379));
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7380));
JedisCluster jedis = new JedisCluster(jedisClusterNodes);
```

Now you can use the JedisCluster instance and send commands like you would with a standard pooled connection:

```java
jedis.sadd("planets", "Mars");
```

### Example: Index and query using Jedis

This example shows how to initialize the client and how to create and query an index.

#### Initialize the client

To initialize the client with JedisPooled:

```
JedisPooled client = new JedisPooled("localhost", 6379);
```

To initialize the client with JedisCluster:

```
Set<HostAndPort> nodes = new HashSet<>();
nodes.add(new HostAndPort("127.0.0.1", 7379));
nodes.add(new HostAndPort("127.0.0.1", 7380));

JedisCluster client = new JedisCluster(nodes);
```

#### Create an index

Define a schema for an index and create it.

```java
Schema sc = new Schema()
        .addTextField("title", 5.0)
        .addTextField("body", 1.0)
        .addNumericField("price");

IndexDefinition def = new IndexDefinition()
        .setPrefixes(new String[]{"item:", "product:"})
        .setFilter("@price>100");

client.ftCreate("item-index", IndexOptions.defaultOptions().setDefinition(def), sc);
```

Add documents to the index.

```java
Map<String, Object> fields = new HashMap<>();
fields.put("title", "hello world");
fields.put("state", "NY");
fields.put("body", "lorem ipsum");
fields.put("price", 1337);

client.hset("item:hw", RediSearchUtil.toStringMap(fields));
```

#### Search the index

Create a complex query.

```java
Query q = new Query("hello world")
        .addFilter(new Query.NumericFilter("price", 0, 1000))
        .limit(0, 5);
```

Now for the actual search:

```java
SearchResult sr = client.ftSearch("item-index", q);
```

To perform an aggregation query:

```java
AggregationBuilder ab = new AggregationBuilder("hello")
        .apply("@price/1000", "k")
        .groupBy("@state", Reducers.avg("@k").as("avgprice"))
        .filter("@avgprice>=2")
        .sortBy(10, SortedField.asc("@state"));
```

To get aggregation results:

```java
AggregationResult ar = client.ftAggregate("item-index", ab);
```

### Learn more

* [Packages and classes](https://www.javadoc.io/doc/redis.clients/jedis/latest/index.html)
* [GitHub](https://github.com/redis/jedis)
 
