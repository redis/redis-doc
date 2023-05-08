---
title: "Node.js guide"
linkTitle: "Node.js"
description: Connect your Node.js application to a Redis database
weight: 4

---

Install Redis and the Redis client, then connect your Node.js application to a Redis database. 

## node-redis

[node-redis](https://github.com/redis/node-redis) is a modern, high-performance Redis client for Node.js.
`node-redis` requires a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

To install node-redis, run:

```
npm install redis
```

### Connect

Connect to localhost on port 6379. 

```js
import { createClient } from 'redis';

const client = createClient();

client.on('error', err => console.log('Redis Client Error', err));

await client.connect();
```

Store and retrieve a simple string.

```js
await client.set('key', 'value');
const value = await client.get('key');
```

Store and retrieve a map.

```js
await client.hSet('user-session:123', {
    name: 'John',
    surname: 'Smith',
    company: 'Redis',
    age: 29
})

let userSession = await client.hGetAll('user-session:123');
console.log(JSON.stringify(userSession, null, 2));
/*
{
  "surname": "Smith",
  "name": "John",
  "company": "Redis",
  "age": "29"
}
 */
```

To connect to a different host or port, use a connection string in the format `redis[s]://[[username][:password]@][host][:port][/db-number]`:

```js
createClient({
  url: 'redis://alice:foobared@awesome.redis.server:6380'
});
```
To check if the client is connected and ready to send commands, use `client.isReady`, which returns a Boolean. `client.isOpen` is also available. This returns `true` when the client's underlying socket is open, and `false` when it isn't (for example, when the client is still connecting or reconnecting after a network error).

#### Connect to a Redis cluster

To connect to a Redis cluster, use `createCluster`.

```js
import { createCluster } from 'redis';

const cluster = createCluster({
    rootNodes: [
        {
            url: 'redis://127.0.0.1:16379'
        },
        {
            url: 'redis://127.0.0.1:16380'
        },
        // ...
    ]
});

cluster.on('error', (err) => console.log('Redis Cluster Error', err));

await cluster.connect();

await cluster.set('foo', 'bar');
const value = await cluster.get('bar');
console.log(value); // returns 'bar'

await cluster.quit();
```

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

```js
const client = createClient({
    username: 'default', // use your Redis user. More info https://redis.io/docs/management/security/acl/
    password: 'secret', // use your password here
    socket: {
        host: 'my-redis.cloud.redislabs.com',
        port: 6379,
        tls: true,
        key: readFileSync('./redis_user_private.key'),
        cert: readFileSync('./redis_user.crt'),
        ca: [readFileSync('./redis_ca.pem')]
    }
});

client.on('error', (err) => console.log('Redis Client Error', err));

await client.connect();

await client.set('foo', 'bar');
const value = await client.get('foo');
console.log(value) // returns 'bar'

await client.disconnect();
```

You can also use discrete parameters and UNIX sockets. Details can be found in the [client configuration guide](https://github.com/redis/node-redis/blob/master/docs/client-configuration.md).

### Example: Indexing and querying JSON documents

Make sure that you have Redis Stack and `node-redis` installed.

Connect to your Redis database.

{{< clients-example search_quickstart connect Node.js />}}

Let's create some test data to add to your database.

{{< clients-example search_quickstart data_sample Node.js />}}

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

{{< clients-example search_quickstart define_index Node.js />}}

Create an index. In this example, all JSON documents with the key prefix `bicycle:` will be indexed.

{{< clients-example search_quickstart create_index Node.js />}}

Use `JSON.SET` to add bicycle data to the database.

{{< clients-example search_quickstart add_documents Node.js />}}

Let's find a folding bicycle and filter the results by price range. For more information, see [Query syntax](/docs/stack/search/reference/query_syntax).

{{< clients-example search_quickstart query_single_term_and_num_range Node.js />}}

Return only the `price` field.

{{< clients-example search_quickstart query_single_term_limit_fields Node.js />}}
 
Count all bicycles based on their condition with `FT.AGGREGATE`.

{{< clients-example search_quickstart simple_aggregation Node.js />}}

### Learn more

* [Redis commands](https://redis.js.org/#node-redis-usage-redis-commands)
* [Programmability](https://redis.js.org/#node-redis-usage-programmability)
* [Clustering](https://redis.js.org/#node-redis-usage-clustering)
* [GitHub](https://github.com/redis/node-redis)
 
