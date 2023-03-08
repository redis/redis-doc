---
title: "Node.js guide"
linkTitle: "Node.js"
description: Connect your Node.js application to a Redis database
weight: 2

---

Install Redis and the Redis client, then connect your Node.js application to a Redis database. 

## node-redis

[node-redis](https://github.com/redis/node-redis) is a modern, high-performance Redis client for Node.js.

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
You can also use discrete parameters, UNIX sockets, and even TLS to connect. Details can be found in the client configuration guide.

To check if the client is connected and ready to send commands, use `client.isReady`, which returns a Boolean. `client.isOpen` is also available. This returns `true` when the client's underlying socket is open, and `false` when it isn't (for example, when the client is still connecting or reconnecting after a network error).

### Example: Index and query data stored in Redis hashes using node-redis

This example demonstrates how to index and query data stored in Redis hashes. 

```js
import { createClient, SchemaFieldTypes } from 'redis';

const client = createClient();

await client.connect();
```

Create an index using `FT.CREATE`.

```js
try {
  await client.ft.create('idx:animals', {
    name: {
      type: SchemaFieldTypes.TEXT,
      sortable: true
    },
    species: SchemaFieldTypes.TAG,
    age: SchemaFieldTypes.NUMERIC
  }, {
    ON: 'HASH',
    PREFIX: 'noderedis:animals'
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

Add some sample data using `HSET`.

```js
await Promise.all([
  client.hSet('noderedis:animals:1', {name: 'Fluffy', species: 'cat', age: 3}),
  client.hSet('noderedis:animals:2', {name: 'Ginger', species: 'cat', age: 4}),
  client.hSet('noderedis:animals:3', {name: 'Rover', species: 'dog', age: 9}),
  client.hSet('noderedis:animals:4', {name: 'Fido', species: 'dog', age: 7})
]);
```

Perform a search query using `FT.SEARCH` to find all the dogs, then sort the search results by age in descending order. For more information, see [Query syntax](https://redis.io/docs/stack/search/reference/query_syntax/).

```js
const results = await client.ft.search(
  'idx:animals', 
  '@species:{dog}',
  {
    SORTBY: {
      BY: 'age',
      DIRECTION: 'DESC' // or 'ASC (default if DIRECTION is not present)
    }
  }
);

 results:
 {
   total: 2,
   documents: [
     { 
       id: 'noderedis:animals:3',
       value: {
         name: 'Rover',
         species: 'dog',
         age: '9'
       }
     },
     {
       id: 'noderedis:animals:4',
       value: {
         name: 'Fido',
         species: 'dog',
         age: '7'
       }
     }
   ]
 }

console.log(`Results found: ${results.total}.`);

for (const doc of results.documents) {
  // noderedis:animals:3: Rover, 9 years old.
  // noderedis:animals:4: Fido, 7 years old.
  console.log(`${doc.id}: ${doc.value.name}, ${doc.value.age} years old.`);
}

await client.quit();
```

### Learn more

* [Redis commands](https://redis.js.org/#node-redis-usage-redis-commands)
* [Programmability](https://redis.js.org/#node-redis-usage-programmability)
* [Clustering](https://redis.js.org/#node-redis-usage-clustering)
* [GitHub](https://github.com/redis/node-redis)
 
