---
title: "Node.js guide"
linkTitle: "Node.js"
description: Connect your Node.js application to a Redis database
weight: 4
aliases:
  - /docs/clients/nodejs/
  - /docs/redis-clients/nodejs/
---

Install Redis and the Redis client, then connect your Node.js application to a Redis database. 

## node-redis

[node-redis](https://github.com/redis/node-redis) is a modern, high-performance Redis client for Node.js.
`node-redis` requires a running Redis or [Redis Stack](https://redis.io/docs/getting-started/install-stack/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

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
const value = await cluster.get('foo');
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

Make sure that you have Redis Stack and `node-redis` installed. Import dependencies:

```js
import {AggregateSteps, AggregateGroupByReducers, createClient, SchemaFieldTypes} from 'redis';
const client = createClient();
await client.connect();
```

Create an index.

```js
try {
    await client.ft.create('idx:users', {
        '$.name': {
            type: SchemaFieldTypes.TEXT,
            SORTABLE: true
        },
        '$.city': {
            type: SchemaFieldTypes.TEXT,
            AS: 'city'
        },
        '$.age': {
            type: SchemaFieldTypes.NUMERIC,
            AS: 'age'
        }
    }, {
        ON: 'JSON',
        PREFIX: 'user:'
    });
} catch (e) {
    if (e.message === 'Index already exists') {
        console.log('Index exists already, skipped creation.');
    } else {
        // Something went wrong, perhaps RediSearch isn't installed...
        console.error(e);
        process.exit(1);
    }
}
```

Create JSON documents to add to your database.

```js
await Promise.all([
    client.json.set('user:1', '$', {
        "name": "Paul John",
        "email": "paul.john@example.com",
        "age": 42,
        "city": "London"
    }),
    client.json.set('user:2', '$', {
        "name": "Eden Zamir",
        "email": "eden.zamir@example.com",
        "age": 29,
        "city": "Tel Aviv"
    }),
    client.json.set('user:3', '$', {
        "name": "Paul Zamir",
        "email": "paul.zamir@example.com",
        "age": 35,
        "city": "Tel Aviv"
    }),
]);
```

Let's find user 'Paul` and filter the results by age.

```js
let result = await client.ft.search(
    'idx:users',
    'Paul @age:[30 40]'
);
console.log(JSON.stringify(result, null, 2));
/*
{
  "total": 1,
  "documents": [
    {
      "id": "user:3",
      "value": {
        "name": "Paul Zamir",
        "email": "paul.zamir@example.com",
        "age": 35,
        "city": "Tel Aviv"
      }
    }
  ]
}
 */
```

Return only the city field.

```js
result = await client.ft.search(
    'idx:users',
    'Paul @age:[30 40]',
    {
        RETURN: ['$.city']
    }
);
console.log(JSON.stringify(result, null, 2));

/*
{
  "total": 1,
  "documents": [
    {
      "id": "user:3",
      "value": {
        "$.city": "Tel Aviv"
      }
    }
  ]
}
 */
```
 
Count all users in the same city.

```js
result = await client.ft.aggregate('idx:users', '*', {
    STEPS: [
        {
            type: AggregateSteps.GROUPBY,
            properties: ['@city'],
            REDUCE: [
                {
                    type: AggregateGroupByReducers.COUNT,
                    AS: 'count'
                }
            ]
        }
    ]
})
console.log(JSON.stringify(result, null, 2));

/*
{
  "total": 2,
  "results": [
    {
      "city": "London",
      "count": "1"
    },
    {
      "city": "Tel Aviv",
      "count": "2"
    }
  ]
}
 */

await client.quit();
```

### Learn more

* [Redis commands](https://redis.js.org/#node-redis-usage-redis-commands)
* [Programmability](https://redis.js.org/#node-redis-usage-programmability)
* [Clustering](https://redis.js.org/#node-redis-usage-clustering)
* [GitHub](https://github.com/redis/node-redis)
 
