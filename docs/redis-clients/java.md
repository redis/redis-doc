---
title: "Java guide"
linkTitle: "Java"
description: Connect your Java application to a Redis database
weight: 3
​
---
​
Install Redis and the Redis client, then connect your Java application to a Redis database. 
​
## Jedis
​
[Jedis](https://github.com/redis/jedis) is a Java client for Redis designed for performance and ease of use.
​
### Install
​
To include `Jedis` as a dependency in your application, edit the `pom.xml` dependency file, as follows.
​
* If you use **Maven**:   

  ```xml
  <dependency>
      <groupId>redis.clients</groupId>
      <artifactId>jedis</artifactId>
      <version>4.3.1</version>
  </dependency>
  ```

* If you use **Gradle**: 

  ```xml
  repositories {
      mavenCentral()
  }
  //...
  dependencies {
      implementation 'redis.clients:jedis:4.3.1'
      //...
  }
  ```
​
* If you use the JAR files, download the latest Jedis and Apache Commons Pool2 JAR files from [Maven Central](https://central.sonatype.com/) or any other Maven repository.
​
* Build from [source](https://github.com/redis/jedis)
​
​
### Connect
​
For many applications, it's best to use a connection pool. You can instantiate and use a `Jedis` connection pool like so:
​
```
package org.example;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;

public class Main {
    public static void main(String[] args) {
        JedisPool pool = new JedisPool("localhost", 6379);
​
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
​
Because adding a `try-with-resources` block for each command can be cumbersome, consider using `JedisPooled` as an easier way to pool connections.
​
```
import redis.clients.jedis.JedisPooled;​
//...​
JedisPooled jedis = new JedisPooled("localhost", 6379);
jedis.set("foo", "bar");
System.out.println(jedis.get("foo")); // prints "bar"
```​
​
#### Connect to a Redis cluster
​
To connect to a Redis cluster, use `JedisCluster`. 
​
```
import redis.clients.jedis.JedisCluster;
import redis.clients.jedis.HostAndPort;​
//...​
Set<HostAndPort> jedisClusterNodes = new HashSet<HostAndPort>();
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7379));
jedisClusterNodes.add(new HostAndPort("127.0.0.1", 7380));
JedisCluster jedis = new JedisCluster(jedisClusterNodes);
```
​
#### Connect to your production Redis with TLS
​
When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.
​
Before connecting your application to the TLS-enabled Redis server, ensure that your certificates and private keys are in the correct format.

To convert user certificate and private key from the PEM format to `pkcs12`, use this command:
​
```
openssl pkcs12 -export -in ./redis_user.crt -inkey ./redis_user_private.key -out redis-user-keystore.p12 -name "redis"
```

Enter password to protect your `pkcs12` file.

Convert the server (CA) certificate to the JKS format using the [keytool](https://docs.oracle.com/en/java/javase/12/tools/keytool.html) shipped with JDK.
​
```
keytool -importcert -keystore truststore.jks \ 
  -storepass REPLACE_WITH_YOUR_PASSWORD \
  -file redis_ca.pem
```
​
Establish a secure connection with your Redis database using this snippet.
​
```java
package org.example;
​
import redis.clients.jedis.*;
​
import javax.net.ssl.*;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
​
public class Main {
​
    public static void main(String[] args) throws GeneralSecurityException, IOException {
        HostAndPort address = new HostAndPort("my-redis-instance.cloud.redislabs.com", 6379);
​
        SSLSocketFactory sslFactory = createSslSocketFactory(
                "./truststore.jks",
                "secret!", // use the password you specified for keytool command
                "./redis-user-keystore.p12",
                "secret!" // use the password you specified for openssl command
        );
​
        JedisClientConfig config = DefaultJedisClientConfig.builder()
                .ssl(true).sslSocketFactory(sslFactory)
                .user("default") // user your Redis user. More info https://redis.io/docs/management/security/acl/
                .password("secret!") // use your Redis password
                .build();
​
        JedisPooled jedis = new JedisPooled(address, config);
        jedis.set("foo", "bar");
        System.out.println(jedis.get("foo")); // prints bar
    }
​
    private static SSLSocketFactory createSslSocketFactory(
            String caCertPath, String caCertPassword, String userCertPath, String userCertPassword)
            throws IOException, GeneralSecurityException {
​
        KeyStore keyStore = KeyStore.getInstance("pkcs12");
        keyStore.load(new FileInputStream(userCertPath), userCertPassword.toCharArray());
​
        KeyStore trustStore = KeyStore.getInstance("jks");
        trustStore.load(new FileInputStream(caCertPath), caCertPassword.toCharArray());
​
        TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance("X509");
        trustManagerFactory.init(trustStore);
​
        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance("PKIX");
        keyManagerFactory.init(keyStore, userCertPassword.toCharArray());
​
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(keyManagerFactory.getKeyManagers(), trustManagerFactory.getTrustManagers(), null);
​
        return sslContext.getSocketFactory();
    }
}
```
​
### Example: Indexing and querying JSON documents
​
Make sure that you have Redis Stack and `Jedis` installed. 

Import dependencies and add a sample `User` class:
​
```java
import redis.clients.jedis.JedisPooled;
import redis.clients.jedis.search.*;
import redis.clients.jedis.search.aggr.*;
import redis.clients.jedis.search.schemafields.*;
​
class User {
    private String name;
    private String email;
    private int age;
    private String city;
​
    public User(String name, String email, int age, String city) {
        this.name = name;
        this.email = email;
        this.age = age;
        this.city = city;
    }
​
    //...
}
```
​
Connect to your Redis database with `JedisPooled`.
​
```java
JedisPooled jedis = new JedisPooled("localhost", 6379);
```
​
Let's create some test data to add to your database.
​
```java
User user1 = new User("Paul John", "paul.john@example.com", 42, "London");
User user2 = new User("Eden Zamir", "eden.zamir@example.com", 29, "Tel Aviv");
User user3 = new User("Paul Zamir", "paul.zamir@example.com", 35, "Tel Aviv");
```
​
Create an index. In this example, all JSON documents with the key prefix `user:` are indexed. For more information, see [Query syntax](https://redis.io/docs/stack/search/reference/query_syntax).
​
```java
jedis.ftCreate("idx:users",
    FTCreateParams.createParams()
            .on(IndexDataType.JSON)
            .addPrefix("user:"),
    TextField.of("$.name").as("name"),
    TagField.of("$.city").as("city"),
    NumericField.of("$.age").as("age")
);
```
​
Use `JSON.SET` to set each user value at the specified path.

```java
jedis.jsonSetWithEscape("user:1", user1);
jedis.jsonSetWithEscape("user:2", user2);
jedis.jsonSetWithEscape("user:3", user3);
```
​
Let's find user `Paul` and filter the results by age.
​
```java
var query = new Query("Paul @age:[30 40]");
var result = jedis.ftSearch("idx:users", query).getDocuments();
System.out.println(result);
// Prints: [id:user:3, score: 1.0, payload:null, properties:[$={"name":"Paul Zamir","email":"paul.zamir@example.com","age":35,"city":"Tel Aviv"}]]
```
​
Return only the `city` field.
​
```java
var city_query = new Query("Paul @age:[30 40]");
var city_result = jedis.ftSearch("idx:users", city_query.returnFields("city")).getDocuments();
System.out.println(city_result);
// Prints: [id:user:3, score: 1.0, payload:null, properties:[city=Tel Aviv]]
```
​
Count all users in the same city.
​
```java
AggregationBuilder ab = new AggregationBuilder("*")
        .groupBy("@city", Reducers.count().as("count"));
AggregationResult ar = jedis.ftAggregate("idx:users", ab);
​
for (int idx=0; idx < ar.getTotalResults(); idx++) {
    System.out.println(ar.getRow(idx).getString("city") + " - " + ar.getRow(idx).getString("count"));
}
// Prints:
// London - 1
// Tel Aviv - 2
```
​
### Learn more
​
* [Jedis API reference](https://www.javadoc.io/doc/redis.clients/jedis/latest/index.html)
* [GitHub](https://github.com/redis/jedis)
 
