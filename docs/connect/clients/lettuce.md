---
title: "Lettuce guide"
linkTitle: "Lettuce"
description: Connect your Lettuce application to a Redis database
weight: 3
---

Install Redis and the Redis client, then connect your Lettuce application to a Redis database.

## Lettuce

Lettuce offers a powerful and efficient way to interact with Redis through its asynchronous and reactive APIs. By leveraging these capabilities, developers can build high-performance, scalable Java applications that make optimal use of Redis's capabilities.

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
package com.redis;

import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.async.RedisAsyncCommands;
import java.util.concurrent.ExecutionException;

/**
 * Example Redis application using Lettuce.
 */
public final class Main {
    private Main() {
    }

    /**
      * Main method.
      * @param args The arguments of the program.
      */
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        RedisClient redisClient = RedisClient.create("redis://localhost:6379");
        StatefulRedisConnection<String, String> connection = redisClient.connect();

        try {
            RedisAsyncCommands<String, String> asyncCommands = connection.async();

            // Asynchronously store & retrieve a simple string
            asyncCommands.set("foo", "bar").get();
            System.out.println(asyncCommands.get("foo").get()); // prints bar

            // Asynchronously store key-value pairs in a hash directly
            asyncCommands.hset("user-session:123", "name", "John").get();
            asyncCommands.hset("user-session:123", "surname", "Smith").get();
            asyncCommands.hset("user-session:123", "company", "Redis").get();
            asyncCommands.hset("user-session:123", "age", "29").get();

            System.out.println(asyncCommands.hgetall("user-session:123").get());
            // Prints: {name=John, surname=Smith, company=Redis, age=29}
        } finally {
            connection.close();
            redisClient.shutdown();
        }
    }
}
```

### Reactive connection

```java
package com;

import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.reactive.RedisReactiveCommands;
import reactor.core.publisher.Flux;

/**
 * Example Redis application using Lettuce.
 */
public final class MainR {
    private MainR() {
    }

    /**
      * Main method.
      * @param args The arguments of the program.
      */
    public static void main(String[] args) {
        RedisClient redisClient = RedisClient.create("redis://localhost:6379");
        StatefulRedisConnection<String, String> connection = redisClient.connect();

        try {
            RedisReactiveCommands<String, String> reactiveCommands = connection.reactive();

            // Reactively store & retrieve a simple string
            reactiveCommands.set("foo", "bar").block();
            reactiveCommands.get("foo").doOnNext(System.out::println).block(); // prints bar

            // Reactively store key-value pairs in a hash directly
            Flux.just(
                    reactiveCommands.hset("user-session:124", "name", "John"),
                    reactiveCommands.hset("user-session:124", "surname", "Smith"),
                    reactiveCommands.hset("user-session:124", "company", "Redis"),
                    reactiveCommands.hset("user-session:124", "age", "29")
                )
                .then()
                .thenMany(reactiveCommands.hgetall("user-session:124"))
                .doOnNext(System.out::println)
                .blockLast();
        } finally {
            connection.close();
            redisClient.shutdown();
        }
    }
}
```

### Redis Cluster connection

```java
RedisURI redisUri = RedisURI.Builder.redis("localhost").withPassword("authentication").build();

RedisClusterClient clusterClient = RedisClusterClient.create(redisUri);
StatefulRedisClusterConnection<String, String> connection = clusterClient.connect();
RedisAdvancedClusterCommands<String, String> syncCommands = connection.sync();

...

connection.close();
clusterClient.shutdown();
```

### TLS connection

When you deploy your application, use TLS and follow the [Redis security guidelines](/docs/management/security/).

```java
RedisURI redisUri = RedisURI.Builder.redis("localhost")
                                 .withSsl(true)
                                 .withPassword("authentication")
                                 .withDatabase(2)
                                 .build();

RedisClient client = RedisClient.create(redisUri);
```

## Performing Asynchronous Operations

Lettuce's asynchronous API returns instances of `CompletionStage` that can be composed or combined for complex non-blocking operations.
Here's how to work with these operations:

### Chaining Asynchronous Operations

```java
asyncCommands.set("key1", "value1")
    .thenCompose(result -> asyncCommands.get("key1"))
    .thenAccept(System.out::println);
```

This example sets a value and then retrieves it in a non-blocking manner.

### Handling Exceptions

Use `exceptionally` to handle exceptions in asynchronous chains:

```java
asyncCommands.get("unknown_key")
    .thenAccept(value -> System.out.println("Found value: " + value))
    .exceptionally(e -> {
        System.err.println("Error fetching key: " + e.getMessage());
        return null;
    });
```

### Using CompletableFuture for Complex Workflows

`CompletableFuture` allows for more complex asynchronous workflows with operations like `allOf` or `anyOf`:

```java
CompletableFuture<Void> allFutures = CompletableFuture.allOf(
    asyncCommands.set("key1", "value1"),
    asyncCommands.set("key2", "value2")
);

allFutures.thenRun(() ->
    System.out.println("All keys set.")
);
```

## More details on exception handling

The Lettuce exception hierarchy is rooted on `RedisException` and `RedisClientException`, both of which implement `RuntimeException`.

```
RedisException
├── RedisCommandExecutionException
├── RedisCommandTimeoutException
├── RedisConnectionException
│   └── RedisCommandInterruptedException
├── ConnectionWatchdogException
└── RedisValidationException

RedisClientException
```

**RedisException**:

* **RedisCommandExecutionException** - represents general errors that occur during the execution of Redis commands.
* **RedisCommandTimeoutException** - indicates a timeout has occurred during command execution.
* **RedisConnectionException** - pertains to issues related to establishing or maintaining a connection to the Redis server.
    * **RedisCommandInterruptedException** - indicates the execution of a Redis command was interrupted.
* **ConnectionWatchdogException** - special case of connection issues managed by Lettuce's connection watchdog mechanism.
* **RedisValidationException** - thrown for validation errors, such as when command arguments do not meet expected criteria.

**RedisClientException** - used for issues specifically related to the Redis client configuration or behavior, not directly tied to command execution or server communication.

## Connection Management in Lettuce

Lettuce uses `ClientResources` for efficient management of shared resources like event loop groups and thread pools.
For connection pooling, Lettuce leverages `RedisClient` or `RedisClusterClient`, which can handle multiple concurrent connections efficiently.

A typical approach with Lettuce is to create a single `RedisClient` instance and reuse it to establish connections to your Redis server(s).
These connections are multiplexed; that is, multiple commands can be run concurrently over a single or a small set of connections, making explicit pooling less critical than in blocking clients like Jedis.

However, if you specifically need connection pooling for blocking operations or wish to limit the number of concurrent connections to Redis, you can use Lettuce in combination with Apache Commons Pool or any other generic object pooling library.

### Example: connection pool using Apache Commons Pool

First, add dependencies for Lettuce and Apache Commons Pool to your project. If you're using Maven, include the following in your pom.xml:

```xml
<dependencies>
    <dependency>
        <groupId>io.lettuce</groupId>
        <artifactId>lettuce-core</artifactId>
        <version>6.1.5.RELEASE</version> <!-- Use the latest version available -->
    </dependency>
    <dependency>
        <groupId>org.apache.commons</groupId>
        <artifactId>commons-pool2</artifactId>
        <version>2.11.0</version> <!-- Use the latest version available -->
    </dependency>
</dependencies>
```

Then, you can create a pool of `StatefulRedisConnection` objects using `GenericObjectPool` from Apache Commons Pool. Here's an example setup:

```java
import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import org.apache.commons.pool2.ObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPool;
import org.apache.commons.pool2.impl.GenericObjectPoolConfig;

public class LettucePoolExample {
    public static void main(String[] args) {
        // Create RedisClient
        RedisClient redisClient = RedisClient.create("redis://localhost:6379");

        // Pool configuration
        GenericObjectPoolConfig<StatefulRedisConnection<String, String>> poolConfig = new GenericObjectPoolConfig<>();
        poolConfig.setMaxTotal(8); // Maximum active connections
        poolConfig.setMaxIdle(8); // Maximum idle connections
        poolConfig.setMinIdle(0); // Minimum idle connections
        
        // Creating the pool
        ObjectPool<StatefulRedisConnection<String, String>> pool = new GenericObjectPool<>(
                new LettuceConnectionFactory(redisClient), poolConfig);

        try {
            // Use the pool
            StatefulRedisConnection<String, String> connection = pool.borrowObject();
            // Perform operations
            String result = connection.sync().get("key");
            System.out.println(result);
            // Return the connection to the pool
            pool.returnObject(connection);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            pool.close();
            redisClient.shutdown();
        }
    }
}
```

In this setup, `LettuceConnectionFactory` is a custom class you would need to implement, adhering to Apache Commons Pool's `PooledObjectFactory` interface, to manage lifecycle events of pooled `StatefulRedisConnection` objects.

## DNS cache and Redis

When you connect to a Redis with multiple endpoints, such as Redis Enterprise Active-Active, it's recommended to disable the JVM's DNS cache to load-balance requests across multiple endpoints.

You can do this in your application's code with the following snippet:

```java
java.security.Security.setProperty("networkaddress.cache.ttl","0");
java.security.Security.setProperty("networkaddress.cache.negative.ttl", "0");
```

## Advanced Topics

Lettuce supports a wide range of advanced features that cater to complex application requirements:

- **Pub/Sub**: Utilize Lettuce's asynchronous API for efficient message publishing and subscribing.
- **Transactions**: Execute multiple commands atomically using Redis transactions with async support.
- **Cluster and Sentinel Support**: Connect to Redis clusters or Sentinels for high availability and scalability.
- **Custom Codecs**: Customize serialization and deserialization of Redis keys and values.

## Learn more

- [Lettuce reference documentation](https://lettuce.io/docs/)
- [Redis commands](https://redis.io/commands)
- [Project Reactor](https://projectreactor.io/)