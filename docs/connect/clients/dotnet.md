---
title: "C#/.NET guide"
linkTitle: "C#/.NET"
description: Connect your .NET application to a Redis database
weight: 1
aliases:
  - /docs/clients/dotnet/
  - /docs/redis-clients/dotnet/
---

Install Redis and the Redis client, then connect your .NET application to a Redis database. 

## NRedisStack

[NRedisStack](https://github.com/redis/NRedisStack) is a .NET client for Redis.
`NredisStack` requires a running Redis or [Redis Stack](https://redis.io/docs/getting-started/install-stack/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

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

Store and retrieve a simple string.

```csharp
db.StringSet("foo", "bar");
Console.WriteLine(db.StringGet("foo")); // prints bar
```

Store and retrieve a HashMap.

```csharp
var hash = new HashEntry[] { 
    new HashEntry("name", "John"), 
    new HashEntry("surname", "Smith"),
    new HashEntry("company", "Redis"),
    new HashEntry("age", "29"),
    };
db.HashSet("user-session:123", hash);

var hashFields = db.HashGetAll("user-session:123");
Console.WriteLine(String.Join("; ", hashFields));
// Prints: 
// name: John; surname: Smith; company: Redis; age: 29
```

To access Redis Stack capabilities, you should use appropriate interface like this:

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

#### Connect to a Redis cluster

To connect to a Redis cluster, you just need to specify one or all cluster endpoints in the client configuration:

```csharp
ConfigurationOptions options = new ConfigurationOptions
{
    //list of available nodes of the cluster along with the endpoint port.
    EndPoints = {
        { "localhost", 16379 },
        { "localhost", 16380 },
        // ...
    },            
};

ConnectionMultiplexer cluster = ConnectionMultiplexer.Connect(options);
IDatabase db = cluster.GetDatabase();

db.StringSet("foo", "bar");
Console.WriteLine(db.StringGet("foo")); // prints bar
```

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

Before connecting your application to the TLS-enabled Redis server, ensure that your certificates and private keys are in the correct format.

To convert user certificate and private key from the PEM format to `pfx`, use this command:

```bash
openssl pkcs12 -inkey redis_user_private.key -in redis_user.crt -export -out redis.pfx
```

Enter password to protect your `pfx` file.

Establish a secure connection with your Redis database using this snippet.

```csharp
ConfigurationOptions options = new ConfigurationOptions
{
    EndPoints = { { "my-redis.cloud.redislabs.com", 6379 } },
    User = "default",  // use your Redis user. More info https://redis.io/docs/management/security/acl/
    Password = "secret", // use your Redis password
    Ssl = true,
    SslProtocols = System.Security.Authentication.SslProtocols.Tls12                
};

options.CertificateSelection += delegate
{
    return new X509Certificate2("redis.pfx", "secret"); // use the password you specified for pfx file
};
options.CertificateValidation += ValidateServerCertificate;

bool ValidateServerCertificate(
        object sender,
        X509Certificate? certificate,
        X509Chain? chain,
        SslPolicyErrors sslPolicyErrors)
{
    if (certificate == null) {
        return false;       
    }

    var ca = new X509Certificate2("redis_ca.pem");
    bool verdict = (certificate.Issuer == ca.Subject);
    if (verdict) {
        return true;
    }
    Console.WriteLine("Certificate error: {0}", sslPolicyErrors);
    return false;
}

ConnectionMultiplexer muxer = ConnectionMultiplexer.Connect(options);   
            
//Creation of the connection to the DB
IDatabase conn = muxer.GetDatabase();

//send SET command
conn.StringSet("foo", "bar");

//send GET command and print the value
Console.WriteLine(conn.StringGet("foo"));   
```

### Example: Indexing and querying JSON documents

This example shows how to convert Redis search results to JSON format using `NRedisStack`.

Make sure that you have Redis Stack and `NRedisStack` installed. 

Import dependencies and connect to the Redis server:

```csharp
using NRedisStack;
using NRedisStack.RedisStackCommands;
using NRedisStack.Search;
using NRedisStack.Search.Aggregation;
using NRedisStack.Search.Literals.Enums;
using StackExchange.Redis;

// ...

ConnectionMultiplexer redis = ConnectionMultiplexer.Connect("localhost");
```

Get a reference to the database and for search and JSON commands.

```csharp
var db = redis.GetDatabase();
var ft = db.FT();
var json = db.JSON();
```

Let's create some test data to add to your database.

```csharp
var user1 = new {
    name = "Paul John",
    email = "paul.john@example.com",
    age = 42,
    city = "London"
};

var user2 = new {
    name = "Eden Zamir",
    email = "eden.zamir@example.com",
    age = 29,
    city = "Tel Aviv"
};

var user3 = new {
    name = "Paul Zamir",
    email = "paul.zamir@example.com",
    age = 35,
    city = "Tel Aviv"
};
```

Create an index. In this example, all JSON documents with the key prefix `user:` are indexed. For more information, see [Query syntax](/docs/interact/search-and-query/query/).

```csharp
var schema = new Schema()
    .AddTextField(new FieldName("$.name", "name"))
    .AddTagField(new FieldName("$.city", "city"))
    .AddNumericField(new FieldName("$.age", "age"));

ft.Create(
    "idx:users",
    new FTCreateParams().On(IndexDataType.JSON).Prefix("user:"),
    schema);
```

Use `JSON.SET` to set each user value at the specified path.

```csharp
json.Set("user:1", "$", user1);
json.Set("user:2", "$", user2);
json.Set("user:3", "$", user3);
```

Let's find user `Paul` and filter the results by age.

```csharp
var res = ft.Search("idx:users", new Query("Paul @age:[30 40]")).Documents.Select(x => x["json"]);
Console.WriteLine(string.Join("\n", res)); 
// Prints: {"name":"Paul Zamir","email":"paul.zamir@example.com","age":35,"city":"Tel Aviv"}
```

Return only the `city` field.

```csharp
var res_cities = ft.Search("idx:users", new Query("Paul").ReturnFields(new FieldName("$.city", "city"))).Documents.Select(x => x["city"]);
Console.WriteLine(string.Join(", ", res_cities)); 
// Prints: London, Tel Aviv
```

Count all users in the same city.

```csharp
var request = new AggregationRequest("*").GroupBy("@city", Reducers.Count().As("count"));
var result = ft.Aggregate("idx:users", request);

for (var i=0; i<result.TotalResults; i++)
{
    var row = result.GetRow(i);
    Console.WriteLine($"{row["city"]} - {row["count"]}");
}
// Prints:
// London - 1
// Tel Aviv - 2
```

### Learn more

* [GitHub](https://github.com/redis/NRedisStack)
 
