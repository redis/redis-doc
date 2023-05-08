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

### Example: Indexing and querying JSON documents

Make sure that you have Redis Stack and `Jedis` installed. 

Connect to your Redis database.

{{< clients-example search_quickstart connect Java />}}

Add a sample `Bicycle` class:

{{< clients-example search_quickstart data_class Java />}}

Let's create some test data to add to your database.

{{< clients-example search_quickstart data_sample Java />}}

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

{{< clients-example search_quickstart define_index Java />}}

Create an index. In this example, all JSON documents with the key prefix `bicycle:` will be indexed.

{{< clients-example search_quickstart create_index Java />}}

Use `JSON.SET` to add bicycle data to the database.

{{< clients-example search_quickstart add_documents Java />}}

Let's find a folding bicycle and filter the results by price range. For more information, see [Query syntax](/docs/stack/search/reference/query_syntax).

{{< clients-example search_quickstart query_single_term_and_num_range Java />}}

Return only the `price` field.

{{< clients-example search_quickstart query_single_term_limit_fields Java />}}

Count all bicycles based on their condition with `FT.AGGREGATE`.

{{< clients-example search_quickstart simple_aggregation Java />}}

### Learn more

* [Jedis API reference](https://www.javadoc.io/doc/redis.clients/jedis/latest/index.html)
* [GitHub](https://github.com/redis/jedis)
