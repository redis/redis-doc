---
title: "Java guide"
linkTitle: "Java"
description: Connect your Java application to a Redis database
weight: 3
aliases:
  - /docs/clients/java/
  - /docs/redis-clients/java/
---

Install Redis and the Redis client, then connect your Java application to a Redis database. 

## Jedis

[Jedis](https://github.com/redis/jedis) is a Java client for Redis designed for performance and ease of use.

### Install

To include `Jedis` as a dependency in your application, edit the dependency file, as follows.

* If you use **Maven**:   

  ```xml
  <dependency>
      <groupId>redis.clients</groupId>
      <artifactId>jedis</artifactId>
      <version>4.3.1</version>
  </dependency>
  ```

* If you use **Gradle**: 

  ```
  repositories {
      mavenCentral()
  }
  //...
  dependencies {
      implementation 'redis.clients:jedis:4.3.1'
      //...
  }
  ```

* If you use the JAR files, download the latest Jedis and Apache Commons Pool2 JAR files from [Maven Central](https://central.sonatype.com/) or any other Maven repository.

* Build from [source](https://github.com/redis/jedis)

### Connect

For many applications, it's best to use a connection pool. You can instantiate and use a `Jedis` connection pool like so:

```java
package org.example;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;

public class Main {
    public static void main(String[] args) {
        JedisPool pool = new JedisPool("localhost", 6379);

        try (Jedis jedis = pool.getResource()) {
            // Store & Retrieve a simple string
            jedis.set("foo", "bar");
            System.out.println(jedis.get("foo")); // prints bar
            
            // Store & Retrieve a HashMap
            Map<String, String> hash = new HashMap<>();;
            hash.put("name", "John");
            hash.put("surname", "Smith");
            hash.put("company", "Redis");
            hash.put("age", "29");
            jedis.hset("user-session:123", hash);
            System.out.println(jedis.hgetAll("user-session:123"));
            // Prints: {name=John, surname=Smith, company=Redis, age=29}
        }
    }
}
```

Because adding a `try-with-resources` block for each command can be cumbersome, consider using `JedisPooled` as an easier way to pool connections.

```java
import redis.clients.jedis.JedisPooled;

//...

JedisPooled jedis = new JedisPooled("localhost", 6379);
jedis.set("foo", "bar");
System.out.println(jedis.get("foo")); // prints "bar"
```

#### Connect to a Redis cluster

To connect to a Redis cluster, use `JedisCluster`. 

```java
import redis.clients.jedis.JedisCluster;
import redis.clients.jedis.HostAndPort;

//...

Set<HostAndPort> jedisClusterNodes = new HashSet<HostAndPort>();
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7379));
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7380));
JedisCluster jedis = new JedisCluster(jedisClusterNodes);
```

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

Before connecting your application to the TLS-enabled Redis server, ensure that your certificates and private keys are in the correct format.

To convert user certificate and private key from the PEM format to `pkcs12`, use this command:

```
openssl pkcs12 -export -in ./redis_user.crt -inkey ./redis_user_private.key -out redis-user-keystore.p12 -name "redis"
```

Enter password to protect your `pkcs12` file.

Convert the server (CA) certificate to the JKS format using the [keytool](https://docs.oracle.com/en/java/javase/12/tools/keytool.html) shipped with JDK.

```
keytool -importcert -keystore truststore.jks \ 
  -storepass REPLACE_WITH_YOUR_PASSWORD \
  -file redis_ca.pem
```

Establish a secure connection with your Redis database using this snippet.

```java
package org.example;

import redis.clients.jedis.*;

import javax.net.ssl.*;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.KeyStore;

public class Main {

    public static void main(String[] args) throws GeneralSecurityException, IOException {
        HostAndPort address = new HostAndPort("my-redis-instance.cloud.redislabs.com", 6379);

        SSLSocketFactory sslFactory = createSslSocketFactory(
                "./truststore.jks",
                "secret!", // use the password you specified for keytool command
                "./redis-user-keystore.p12",
                "secret!" // use the password you specified for openssl command
        );

        JedisClientConfig config = DefaultJedisClientConfig.builder()
                .ssl(true).sslSocketFactory(sslFactory)
                .user("default") // use your Redis user. More info https://redis.io/docs/management/security/acl/
                .password("secret!") // use your Redis password
                .build();

        JedisPooled jedis = new JedisPooled(address, config);
        jedis.set("foo", "bar");
        System.out.println(jedis.get("foo")); // prints bar
    }

    private static SSLSocketFactory createSslSocketFactory(
            String caCertPath, String caCertPassword, String userCertPath, String userCertPassword)
            throws IOException, GeneralSecurityException {

        KeyStore keyStore = KeyStore.getInstance("pkcs12");
        keyStore.load(new FileInputStream(userCertPath), userCertPassword.toCharArray());

        KeyStore trustStore = KeyStore.getInstance("jks");
        trustStore.load(new FileInputStream(caCertPath), caCertPassword.toCharArray());

        TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance("X509");
        trustManagerFactory.init(trustStore);

        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance("PKIX");
        keyManagerFactory.init(keyStore, userCertPassword.toCharArray());

        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(keyManagerFactory.getKeyManagers(), trustManagerFactory.getTrustManagers(), null);

        return sslContext.getSocketFactory();
    }
}
```

### Production usage

### Configuring Connection pool
As was covered in the previous section, it's recommended to use `JedisPool` or `JedisPooled`. 
`JedisPooled` is available since Jedis 4.0.0 and is a wrapper around `JedisPool` that provides a simpler API.
A connection pool holds a specified amount of connections. 
Creates more connections when needed and terminates them when they are unwanted.

Here is a simplified connection lifecycle in the pool:

1. A connection is requested from the pool.
2. A connection is served. 
   - An idle connection is served when there are available non-active connections or, 
   - A connection is created when the number of connections is under maxTotal. 
3. The connection becomes active.
4. The connection is released back to the pool.
5. The connection is marked as stale. 
6. The connection is kept idle for `minEvictableIdleTime`. 
7. The connection becomes evictable if the number of connections is greater than `minIdle`. 
8. The connection is ready to be closed.

It's important to configure connection pool correctly. 
To configure the connection pool, use `GenericObjectPoolConfig` from [Apache Commons Pool2](https://commons.apache.org/proper/commons-pool/apidocs/org/apache/commons/pool2/impl/GenericObjectPoolConfig.html).



```java

ConnectionPoolConfig poolConfig = new ConnectionPoolConfig();
// maximum active connections in the pool,
// tune this according to your needs and application type
// default is 8
poolConfig.setMaxTotal(8);

// maximum idle connections in the pool, default is 8
poolConfig.setMaxIdle(8);
// minimum idle connections in the pool, default 0
poolConfig.setMinIdle(0);

// Enables waiting for a connection to become available.
poolConfig.setBlockWhenExhausted(true);
// The maximum number of seconds to wait for a connection to become available
poolConfig.setMaxWait(Duration.ofSeconds(1));

// Enables sending a PING command periodically while the connection is idle.
poolConfig.setTestWhileIdle(true);
// controls the period between checks for idle connections in the pool
poolConfig.setTimeBetweenEvictionRuns(Duration.ofSeconds(1));

// JedisPooled does all hard work on fetching and releasing connection to the pool
// to prevent connection starvation
JedisPooled jedis = new JedisPooled(poolConfig, "localhost", 6379);
```


### Timeout

To set a timeout for a connection, use `JedisPooled` or `JedisPool` constructor with `timeout` parameter or `JedisClientConfig` with `socketTimeout` parameter:
```java
HostAndPort hostAndPort = new HostAndPort("localhost", 6379);

JedisPooled jedisWithTimeout = new JedisPooled(hostAndPort, 
    DefaultJedisClientConfig.builder()
        .socketTimeoutMillis(5000)  // set timeout to 5 seconds
        .build(),
    poolConfig
);
```


### Exception handling
The Jedis Exception Hierarchy is rooted on JedisException which implements RuntimeException and are therefore all unchecked exceptions.
```
JedisException
├── JedisDataException
│   ├── JedisRedirectionException
│   │   ├── JedisMovedDataException
│   │   └── JedisAskDataException
│   ├── AbortedTransactionException
│   ├── JedisAccessControlException
│   └── JedisNoScriptException
├── JedisClusterException
│   ├── JedisClusterOperationException
│   ├── JedisConnectionException
│   └── JedisValidationException
└── InvalidURIException
```

#### General Exceptions
In general, Jedis can throw the following exceptions while executing commands:
- `JedisConnectionException` - when the connection to Redis is lost or closed unexpectedly. [Configure failover] to handle this exception automatically with Resilience4J and build-in Jedis failover mechanism.  
- `JedisAccessControlException` - when the user does not have the permission to execute the command or user and/or password are incorrect.
- `JedisDataException` - when there is a problem with the data being sent to or received from the Redis server. Usually, the error message will contain more information about the failed command.
- `JedisException` - this exception is a catch-all exception that can be thrown for any other unexpected errors.

Conditions when `JedisException` can be thrown:
- Bad Return from health check with `PING` command
- Failure during SHUTDOWN
- Pub/Sub failure when issuing commands (disconnect)
- Any unknown server messages
- Sentinel: can connect to sentinel but master is not monitored or all Sentinels are down.
- MULTI or DISCARD command failed 
- Shard commands key hash check failed or no Reachable Shards
- Retry deadline exceeded/number of attempts (Retry Command Executor)
- POOL - pool exhausted, error adding idle objects, returning broken resources to the pool

All the Jedis exceptions are runtime exceptions and in most cases irrecoverable, so in general bubble up the API capturing the error message.

## DNS cache and Redis

When you connect to a Redis with multiple endpoints, such as [Redis Enterprise Active-Active](https://redis.com/redis-enterprise/technology/active-active-geo-distribution/), it's recommended to disable JVM DNS cache to load-balance requests across multiple endpoints.

You can do this in your application's code with the following snippet:
```java
java.security.Security.setProperty("networkaddress.cache.ttl","0");
java.security.Security.setProperty("networkaddress.cache.negative.ttl", "0");
```

### Learn more

* [Jedis API reference](https://www.javadoc.io/doc/redis.clients/jedis/latest/index.html)
* [Failover with Jedis](https://github.com/redis/jedis/blob/master/docs/failover.md)
* [GitHub](https://github.com/redis/jedis)
