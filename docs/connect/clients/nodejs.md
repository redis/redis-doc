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

### Production usage

#### Handling errors
Node-Redis provides [multiple events to handle various scenarios](https://github.com/redis/node-redis?tab=readme-ov-file#events), among which the most critical is the `error` event.

This event is triggered whenever an error occurs within the client.

**It is crucial to listen for error events.**

If a client does not register at least one error listener and an error occurs, the system will throw that error, potentially causing the Node.js process to exit unexpectedly.
See [the EventEmitter docs](https://nodejs.org/api/events.html#events_error_events) for more details.

```typescript
const client = createClient({
  // ... client options
});
// Always ensure there's a listener for errors in the client to prevent process crashes due to unhandled errors
client.on('error', error => {
    console.error(`Redis client error: ${error}`)
});
```


#### Handling reconnections

If the socket unexpectedly closes, such as due to network issues, the client rejects all commands already sent, as they might have been executed on the server.
The rest of pending commands will remain queued in memory until a new socket is established.  
The client uses `reconnectStrategy` to decide when to attempt to reconnect. 
The default strategy is to calculate delay before each attempt based on the attempt number `Math.min(retries * 50, 500)`. You can customize this strategy by passing a supported value to `reconnectStrategy` option:

1. Define a callback `(retries: number, cause: Error) => false | number | Error` **(recommended)**
```typescript
const client = createClient({
  socket: {
    reconnectStrategy: function(retries) {
        if (retries > 20) {
            console.log("Too many attempts to reconnect. Redis connection was terminated");
            return new Error("Too many retries.");
        } else {
            return retries * 500;
        }
    }
  }
});
client.on('error', error => {
    console.error(`Redis client error: ${error}`)
});
```
In the provided reconnection strategy callback, the client attempts to reconnect up to 20 times with a delay of `retries * 500` milliseconds between attempts. 
After approximately 2 minutes, the client logs an error message and terminates the connection if the maximum retry limit is exceeded.

2. Use a numerical value to set a fixed delay in milliseconds.
3. Use `false` to disable reconnection attempts. This option should only be used for testing purposes.

#### Timeout

To set a timeout for a connection, use the `connectTimeout` option:
```typescript
const client = createClient({
  // setting a 10-second timeout  
  connectTimeout: 10000 // in milliseconds
});
client.on('error', error => {
    console.error(`Redis client error: ${error}`)
});
```

### Learn more

* [Node-Redis Configuration Options](https://github.com/redis/node-redis/blob/master/docs/client-configuration.md)
* [Redis commands](https://redis.js.org/#node-redis-usage-redis-commands)
* [Programmability](https://redis.js.org/#node-redis-usage-programmability)
* [Clustering](https://redis.js.org/#node-redis-usage-clustering)
* [GitHub](https://github.com/redis/node-redis)
 
