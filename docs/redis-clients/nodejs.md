---
title: "Node.js guide"
linkTitle: "Node.js"
description: Connect your Node.js application to a Redis database
weight: 2

---

Install Redis and the Redis client, then connect your Node.js application to a Redis database. 

## node-redis

[node-redis](https://github.com/redis/node-redis) is a modern, high-performance Redis client for Node.js.
`node-redis` requires a running Redis server a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

Start Redis via Docker:

```
docker run -p 6379:6379 -it redis/redis-stack-server:latest
```

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

await client.set('key', 'value');
const value = await client.get('key');
await client.disconnect();
```

To connect to a different host or port, use a connection string in the format `redis[s]://[[username][:password]@][host][:port][/db-number]`:

```js
createClient({
  url: 'redis://alice:foobared@awesome.redis.server:6380'
});
```
You can also use discrete parameters, UNIX sockets, and even TLS to connect. Details can be found in the [client configuration guide](https://redis.js.org/docs/client-configuration.md).

To check if the client is connected and ready to send commands, use `client.isReady`, which returns a Boolean. `client.isOpen` is also available. This returns `true` when the client's underlying socket is open, and `false` when it isn't (for example, when the client is still connecting or reconnecting after a network error).

### Example: Indexing and querying JSON documents

```js
import {AggregateSteps, AggregateGroupByReducers, createClient, SchemaFieldTypes} from 'redis';
const client = createClient();
await client.connect();

try {
    await client.ft.create('idx:users', {
        '$.name': {
            type: SchemaFieldTypes.TEXT,
            sortable: true
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

// Return only the city field
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

// Count all users in the same city
result = await client.ft.aggregate('idx:users', '*', {
    STEPS: [
        {
            type: AggregateSteps.GROUPBY,
            properties: ['@city'],
            REDUCE: [
                {
                    type: AggregateGroupByReducers.COUNT,
                    property: '@name',
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
 
