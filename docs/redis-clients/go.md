---
title: "Go guide"
linkTitle: "Go"
description: Connect your Go application to a Redis database
weight: 4

---

Install Redis and the Redis client, then connect your Go application to a Redis database. 

## go-redis

[go-redis](https://github.com/redis/go-redis) provides Go clients for various flavors of Redis and a type-safe API for each Redis command.

### Install

`go-redis` supports last two Go versions and only works with Go modules. 
So, first, you need to initialize a Go module:

```
go mod init github.com/my/repo
```

To install go-redis/v9:

```
go get github.com/redis/go-redis/v9
```

### Connect

To connect to a Redis server:

```go
import (
	"context"
	"fmt"
	"github.com/redis/go-redis/v9"
)

client := redis.NewClient(&redis.Options{
	Addr:	  "localhost:6379",
	Password: "", // no password set
	DB:		  0,  // use default DB
})
```

Another way to connect is using a connection string.

```go
opt, err := redis.ParseURL("redis://<user>:<pass>@localhost:6379/<db>")
if err != nil {
	panic(err)
}

client := redis.NewClient(opt)
```

Store and retrieve a simple string.

```go
err := client.Set(ctx, "foo", "bar", 0).Err()
if err != nil {
    panic(err)
}

val, err := client.Get(ctx, "foo").Result()
if err != nil {
    panic(err)
}
fmt.Println("foo", val)
```

Store and retrieve a map.

```go
session := map[string]string{"name": "John", "surname": "Smith", "company": "Redis", "age": "29"}
for k, v := range session {
    err := client.HSet(ctx, "user-session:123", k, v).Err()
    if err != nil {
        panic(err)
    }
}

userSession := client.HGetAll(ctx, "user-session:123").Val()
fmt.Println(userSession)
 ```

#### Connect to a Redis cluster

To connect to a Redis cluster, use `NewClusterClient`. 

```go
client := redis.NewClusterClient(&redis.ClusterOptions{
    Addrs: []string{":16379", ":16380", ":16381", ":16382", ":16383", ":16384"},

    // To route commands by latency or randomly, enable one of the following.
    //RouteByLatency: true,
    //RouteRandomly: true,
})
```

#### Connect to your production Redis with TLS

When you deploy your application, use TLS and follow the [Redis security](/docs/management/security/) guidelines.

Establish a secure connection with your Redis database using this snippet.

```go
// Load client cert
cert, err := tls.LoadX509KeyPair("redis_user.crt", "redis_user_private.key")
if err != nil {
    log.Fatal(err)
}

// Load CA cert
caCert, err := os.ReadFile("redis_ca.pem")
if err != nil {
    log.Fatal(err)
}
caCertPool := x509.NewCertPool()
caCertPool.AppendCertsFromPEM(caCert)

client := redis.NewClient(&redis.Options{
    Addr:     "my-redis.cloud.redislabs.com:6379",
    Username: "default", // use your Redis user. More info https://redis.io/docs/management/security/acl/
    Password: "secret", // use your Redis password
    TLSConfig: &tls.Config{
        MinVersion:   tls.VersionTLS12,
        Certificates: []tls.Certificate{cert},
        RootCAs:      caCertPool,
    },
})

//send SET command
err = client.Set(ctx, "foo", "bar", 0).Err()
if err != nil {
    panic(err)
}

//send GET command and print the value
val, err := client.Get(ctx, "foo").Result()
if err != nil {
    panic(err)
}
fmt.Println("foo", val)
```


#### dial tcp: i/o timeout

You get a `dial tcp: i/o timeout` error when `go-redis` can't connect to the Redis Server, for example, when the server is down or the port is protected by a firewall. To check if Redis Server is listening on the port, run telnet command on the host where the `go-redis` client is running.

```go
telnet localhost 6379
Trying 127.0.0.1...
telnet: Unable to connect to remote host: Connection refused
```

If you use Docker, Istio, or any other service mesh/sidecar, make sure the app starts after the container is fully available, for example, by configuring healthchecks with Docker and holdApplicationUntilProxyStarts with Istio. 
For more information, see [Healthcheck](https://docs.docker.com/engine/reference/run/#healthcheck).

### Learn more

* [Documentation](https://redis.uptrace.dev/guide/)
* [GitHub](https://github.com/redis/go-redis)
 
