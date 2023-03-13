---
title: ".NET guide"
linkTitle: ".NET"
description: Connect your .NET application to a Redis database
weight: 5

---

Install Redis and the Redis client, then connect your .NET application to a Redis database. 

## NRedisStack

[NRedisStack](https://github.com/redis/NRedisStack) is a .NET client for Redis.
`NredisStack` requires a running Redis server a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

Using the `dotnet` CLI, run:

```
dotnet add package NRedisStack
```

### Connect

Connect to localhost on port 6379.

```
using NRedisStack;
using NRedisStack.RedisStackCommands;
using StackExchange.Redis;
//...
ConnectionMultiplexer redis = ConnectionMultiplexer.Connect("localhost");
IDatabase db = redis.GetDatabase();
```

Now you can create a variable from any type of module like this:

```
IBloomCommands bf = db.BF();
ICuckooCommands cf = db.CF();
ICmsCommands cms = db.CMS();
IGraphCommands graph = db.GRAPH();
ITopKCommands topk = db.TOPK();
ITdigestCommands tdigest = db.TDIGEST();
ISearchCommands ft = db.FT();
IJsonCommands json = db.JSON();
ITimeSeriesCommands ts = db.TS();
```

Then, that variable will allow you to call all the commands of that module.

### Example: Convert search results to JSON

This example shows how to convert Redis search results to JSON format using `NRedisStack`.

Connect to the Redis server:

```csharp
var redis = ConnectionMultiplexer.Connect("localhost");
```

Get a reference to the database and for search and JSON commands.

```csharp
var db = redis.GetDatabase();
var ft = db.FT();
var json = db.JSON();
```

Create a search index with a JSON field.

```csharp
ft.Create("test", new FTCreateParams().On(IndexDataType.JSON).Prefix("doc:"),
            new Schema().AddTagField(new FieldName("$.name", "name")));
```

Insert 10 JSON documents into the index.

```csharp
for (int i = 0; i < 10; i++)
{
    json.Set("doc:" + i, "$", "{\"name\":\"foo\"}");
}
```

Execute a search query and convert the results to JSON.

```csharp
var res = ft.Search("test", new Query("@name:{foo}"));
var docs = res.ToJson();
```

Now the `docs` variable contains a JSON list (IEnumerable) of the search results.

### Learn more

* [GitHub](https://github.com/redis/NRedisStack)
 
