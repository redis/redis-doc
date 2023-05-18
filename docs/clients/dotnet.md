---
title: "C#/.NET guide"
linkTitle: "C#/.NET"
description: Connect your .NET application to a Redis database
weight: 1

---

Install Redis and the Redis client, then connect your .NET application to a Redis database. 

## NRedisStack

[NRedisStack](https://github.com/redis/NRedisStack) is a .NET client for Redis.
`NredisStack` requires a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

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

Make sure that you have Redis Stack and `NRedisStack` installed. 

Connect to your Redis database and get a reference to the database and for search and JSON commands.

{{< clients-example search_quickstart connect "C#" />}}

Let's create some test data to add to your database.

{{< clients-example search_quickstart data_sample "C#" />}}

Define indexed fields and their data types using `schema`. Use JSON path expressions to map specific JSON elements to the schema fields.

{{< clients-example search_quickstart define_index "C#" />}}

Create an index. In this example, all JSON documents with the key prefix `bicycle:` will be indexed.

{{< clients-example search_quickstart create_index "C#" />}}

Use `JSON.SET` to add bicycle data to the database.

{{< clients-example search_quickstart add_documents "C#" />}}

Let's find a folding bicycle and filter the results by price range. For more information, see [Query syntax](/docs/stack/search/reference/query_syntax).

{{< clients-example search_quickstart query_single_term_and_num_range "C#" />}}

Return only the `price` field.

{{< clients-example search_quickstart query_single_term_limit_fields "C#" />}}

Count all bicycles based on their condition with `FT.AGGREGATE`.

{{< clients-example search_quickstart simple_aggregation "C#" />}}

### Learn more

* [GitHub](https://github.com/redis/NRedisStack)
 
