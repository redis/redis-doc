---
title: "Lettuce guide"
linkTitle: "Lettuce"
description: Connect your Lettuce application to a Redis database
weight: 3
---

Install Redis and the Redis client, then connect your Lettuce application to a Redis database.

## Lettuce

Lettuce offers a powerful and efficient way to interact with Redis through its asynchronous and reactive APIs. By leveraging these capabilities, you can build high-performance, scalable Java applications that make optimal use of Redis's capabilities.

## Install

To include Lettuce as a dependency in your application, edit the appropriate dependency file as shown below.

If you use Maven, add the following dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>io.lettuce</groupId>
    <artifactId>lettuce-core</artifactId>
    <version>6.3.2.RELEASE</version> <!-- Check for the latest version on Maven Central -->
</dependency>
```

If you use Gradle, include this line in your `build.gradle` file:

```
dependencies {
    compile 'io.lettuce:lettuce-core:6.3.2.RELEASE
}
```

If you wish to use the JAR files directly, download the latest Lettuce and, optionally, Apache Commons Pool2 JAR files from Maven Central or any other Maven repository.

To build from source, see the instructions on the [Lettuce source code GitHub repo](https://github.com/lettuce-io/lettuce-core).

## Connect

Start by creating a connection to your Redis server. There are many ways to achieve this using Lettuce. Here are a few.

### Asynchronous connection

```java
package org.example;
import java.util.*;
import java.util.concurrent.ExecutionException;

import io.lettuce.core.*;
import io.lettuce.core.api.async.RedisAsyncCommands;
import io.lettuce.core.api.StatefulRedisConnection;

public class Async {
  public static void main(String[] args) {
    RedisClient redisClient = RedisClient.create("redis://localhost:6379");

    try (StatefulRedisConnection<String, String> connection = redisClient.connect()) {
      RedisAsyncCommands<String, String> asyncCommands = connection.async();

      // Asynchronously store & retrieve a simple string
      asyncCommands.set("foo", "bar").get();
      System.out.println(asyncCommands.get("foo").get()); // prints bar

      // Asynchronously store key-value pairs in a hash directly
      Map<String, String> hash = new HashMap<>();
      hash.put("name", "John");
      hash.put("surname", "Smith");
      hash.put("company", "Redis");
      hash.put("age", "29");
      asyncCommands.hset("user-session:123", hash).get();

      System.out.println(asyncCommands.hgetall("user-session:123").get());
      // Prints: {name=John, surname=Smith, company=Redis, age=29}
    } catch (ExecutionException | InterruptedException e) {
      throw new RuntimeException(e);
    } finally {
      redisClient.shutdown();
    }
  }
}
```

Learn more about asynchronous Lettuce API in [the reference guide](https://lettuce.io/core/release/reference/index.html#asynchronous-api).

### Reactive connection

```java
package org.example;
import java.util.*;
import io.lettuce.core.*;
import io.lettuce.core.api.reactive.RedisReactiveCommands;
import io.lettuce.core.api.StatefulRedisConnection;

public class Main {
  public static void main(String[] args) {
    RedisClient redisClient = RedisClient.create("redis://localhost:6379");

    try (StatefulRedisConnection<String, String> connection = redisClient.connect()) {
      RedisReactiveCommands<String, String> reactiveCommands = connection.reactive();

      // Reactively store & retrieve a simple string
      reactiveCommands.set("foo", "bar").block();
      reactiveCommands.get("foo").doOnNext(System.out::println).block(); // prints bar

      // Reactively store key-value pairs in a hash directly
      Map<String, String> hash = new HashMap<>();
      hash.put("name", "John");
      hash.put("surname", "Smith");
      hash.put("company", "Redis");
      hash.put("age", "29");

      reactiveCommands.hset("user-session:124", hash).then(
              reactiveCommands.hgetall("user-session:124")
                  .collectMap(KeyValue::getKey, KeyValue::getValue).doOnNext(System.out::println))
          .block();
      // Prints: {surname=Smith, name=John, company=Redis, age=29}

    } finally {
      redisClient.shutdown();
    }
  }
}
```

Learn more about reactive Lettuce API in [the reference guide](https://lettuce.io/core/release/reference/index.html#reactive-api).

### Redis Cluster connection

```java
import io.lettuce.core.RedisURI;
import io.lettuce.core.cluster.RedisClusterClient;
import io.lettuce.core.cluster.api.StatefulRedisClusterConnection;
import io.lettuce.core.cluster.api.async.RedisAdvancedClusterAsyncCommands;

// ...

RedisURI redisUri = RedisURI.Builder.redis("localhost").withPassword("authentication").build();

RedisClusterClient clusterClient = RedisClusterClient.create(redisUri);
StatefulRedisClusterConnection<String, String> connection = clusterClient.connect();
RedisAdvancedClusterAsyncCommands<String, String> commands = connection.async();

// ...

connection.close();
clusterClient.shutdown();
```

### TLS connection

When you deploy your application, use TLS and follow the [Redis security guidelines](/docs/management/security/).

```java
RedisURI redisUri = RedisURI.Builder.redis("localhost")
                                 .withSsl(true)
                                 .withPassword("secret!") // use your Redis password
                                 .build();

RedisClient client = RedisClient.create(redisUri);
```



## Connection Management in Lettuce

Lettuce uses `ClientResources` for efficient management of shared resources like event loop groups and thread pools.
For connection pooling, Lettuce leverages `RedisClient` or `RedisClusterClient`, which can handle multiple concurrent connections efficiently.

A typical approach with Lettuce is to create a single `RedisClient` instance and reuse it to establish connections to your Redis server(s).
These connections are multiplexed; that is, multiple commands can be run concurrently over a single or a small set of connections, making explicit pooling less critical.

Lettuce provides pool config to be used with Lettuce asynchronous connection methods.


```java
package org.example;
import io.lettuce.core.RedisClient;
import io.lettuce.core.RedisURI;
import io.lettuce.core.TransactionResult;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.async.RedisAsyncCommands;
import io.lettuce.core.codec.StringCodec;
import io.lettuce.core.support.*;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

public class Pool {
  public static void main(String[] args) {
    RedisClient client = RedisClient.create();

    String host = "localhost";
    int port = 6379;

    CompletionStage<BoundedAsyncPool<StatefulRedisConnection<String, String>>> poolFuture
        = AsyncConnectionPoolSupport.createBoundedObjectPoolAsync(
            () -> client.connectAsync(StringCodec.UTF8, RedisURI.create(host, port)),
            BoundedPoolConfig.create());

    // await poolFuture initialization to avoid NoSuchElementException: Pool exhausted when starting your application
    AsyncPool<StatefulRedisConnection<String, String>> pool = poolFuture.toCompletableFuture()
        .join();

    // execute work
    CompletableFuture<TransactionResult> transactionResult = pool.acquire()
        .thenCompose(connection -> {

          RedisAsyncCommands<String, String> async = connection.async();

          async.multi();
          async.set("key", "value");
          async.set("key2", "value2");
          System.out.println("Executed commands in pipeline");
          return async.exec().whenComplete((s, throwable) -> pool.release(connection));
        });
    transactionResult.join();

    // terminating
    pool.closeAsync();

    // after pool completion
    client.shutdownAsync();
  }
}
```

In this setup, `LettuceConnectionFactory` is a custom class you would need to implement, adhering to Apache Commons Pool's `PooledObjectFactory` interface, to manage lifecycle events of pooled `StatefulRedisConnection` objects.

## DNS cache and Redis

When you connect to a Redis database with multiple endpoints, such as Redis Enterprise Active-Active, it's recommended to disable the JVM's DNS cache to load-balance requests across multiple endpoints.

You can do this in your application's code with the following snippet:

```java
java.security.Security.setProperty("networkaddress.cache.ttl","0");
java.security.Security.setProperty("networkaddress.cache.negative.ttl", "0");
```

## Learn more

- [Lettuce reference documentation](https://lettuce.io/docs/)
- [Redis commands](https://redis.io/commands)
- [Project Reactor](https://projectreactor.io/)