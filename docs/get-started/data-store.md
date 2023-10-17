---
title: "Redis as an in-memory data store quick start guide"
linkTitle: "In-memory data store"
weight: 1
description: Understand how to use basic Redis data types
---

This quick start guide shows you how to:

1. Get started with Redis 
2. Store data under a key in Redis
3. Retrieve data with a key from Redis
4. Scan the keyspace for keys that match a specific key pattern

The examples in this article refer to a simple bicycle inventory.

## Setup

The easiest way to get started with Redis is to use Redis Cloud:

1. Create a [free account](https://redis.com/try-free?utm_source=redisio&utm_medium=referral&utm_campaign=2023-09-try_free&utm_content=cu-redis_cloud_users).
2. Follow the instructions to create a free database.
   
   <img src="../img/free-cloud-db.png" width="500px">

You can alternatively follow the [installation guides](/docs/install/) to install Redis on your local machine.

## Connect

The first step is to connect to Redis. You can find further details about the connection options in this documentation site's [connection section](/docs/connect).

{{< clients-example search_quickstart connect >}}
> redis-cli -h 127.0.0.1 -p 6379
{{< /clients-example>}}
<br/>
{{% alert title="Tip" color="warning" %}}
You can copy and paste the connection details from the Redis Cloud database configuration page. Here is an example connection string of a Cloud database that is hosted in the AWS region `us-east-1` and listens on port 16379: `redis-16379.c283.us-east-1-4.ec2.cloud.redislabs.com:16379`. The connection string has the format `host:port`.
{{% /alert  %}}

## Store and retrieve data

Redis stands for Remote Dictionary Server. You can use the same data types as in your local programming environment but on the server side within Redis.

Similar to byte arrays, Redis strings store sequences of bytes, including text, serialized objects, counter values, and binary arrays. The following example shows you how to set and get a string value:

{{< clients-example set_tutorial set_get >}}
    > SET bike:1 Deimos
    OK
    > GET bike:1
    "Deimos"
{{< /clients-example >}}

Hashes are the equivalent of dictionaries (dicts or hash maps). Among other things, you can use hashes to represent plain objects and to store groupings of counters. The following example explains how to set and access field values of an object:

{{< clients-example hash_tutorial set_get_all >}}
> HSET bike:1 model Deimos brand Ergonom type 'Enduro bikes' price 4972
(integer) 4
> HGET bike:1 model
"Deimos"
> HGET bike:1 price
"4972"
> HGETALL bike:1
1) "model"
2) "Deimos"
3) "brand"
4) "Ergonom"
5) "type"
6) "Enduro bikes"
7) "price"
8) "4972"
{{< /clients-example >}}

You can get a complete overview of available data types in this documentation site's [data types section](/docs/data-types/). Each data type has commands allowing you to manipulate or retrieve data. The [commands reference](/commands/) provides a sophisticated explanation.

## Scan the keyspace

Each item within Redis has a unique key. All items live within the Redis keyspace. You can scan the Redis keyspace via the [SCAN command](/commands/scan/). Here is an example that scans for the first 100 keys that have the prefix `bike:`:

{{< clients-example >}}
SCAN 0 MATCH "bike:*" COUNT 100
{{< /clients-example >}}

[SCAN](/commands/scan/) returns a cursor position, allowing you to scan iteratively for the next batch of keys until you reach the cursor value 0.

## Next steps

You can address more use cases with Redis by learning about Redis Stack. Here are two additional quick start guides:

* [Redis as a document database](/docs/get-started/document-database/)
* [Redis as a vector database](/docs/get-started/vector-database/)