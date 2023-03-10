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

`go-redis` supports last two Go versions and only works with Go modules. So, first, you need to initialize a Go module:

```
go mod init github.com/my/repo
```

To install go-redis/v9 (currently in beta):

```
go get github.com/redis/go-redis/v9
```

### Connect

To connect to a Redis Server:

```go
import "github.com/redis/go-redis/v9"

rdb := redis.NewClient(&redis.Options{
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

rdb := redis.NewClient(opt)
```

#### Using TLS

To enable TLS/SSL, you need to provide an empty `tls.Config`. If you're using private certs, you need to specify them in the `tls.Config`. For more information, see [func LoadX509KeyPair](https://pkg.go.dev/crypto/tls#example-LoadX509KeyPair).

```go
rdb := redis.NewClient(&redis.Options{
	TLSConfig: &tls.Config{
		MinVersion: tls.VersionTLS12,
		//Certificates: []tls.Certificate{cert}
	},
})
```

If you are getting `x509: cannot validate certificate for xxx.xxx.xxx.xxx because it doesn't contain any IP SANs`, try to set `ServerName` option.

```go
rdb := redis.NewClient(&redis.Options{
	TLSConfig: &tls.Config{
		MinVersion: tls.VersionTLS12,
		ServerName: "your.domain.com",
	},
})
```

#### Over SSH

To connect over SSH channel:

```go
sshConfig := &ssh.ClientConfig{
	User:			 "root",
	Auth:			 []ssh.AuthMethod{ssh.Password("password")},
	HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	Timeout:		 15 * time.Second,
}

sshClient, err := ssh.Dial("tcp", "remoteIP:22", sshConfig)
if err != nil {
	panic(err)
}

rdb := redis.NewClient(&redis.Options{
	Addr: net.JoinHostPort("127.0.0.1", "6379"),
	Dialer: func(ctx context.Context, network, addr string) (net.Conn, error) {
		return sshClient.Dial(network, addr)
	},
	// Disable timeouts, because SSH does not support deadlines.
	ReadTimeout:  -1,
	WriteTimeout: -1,
})
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

### Context

Every Redis command accepts a context that you can use to set timeouts or propagate some information, for example, tracing context.

```go
ctx := context.Background()
```

### Executing commands

To execute a command:

```go
val, err := rdb.Get(ctx, "key").Result()
fmt.Println(val)
```

Alternatively, you can save the command and later access the value and the error separately.

```go
get := rdb.Get(ctx, "key")
fmt.Println(get.Val(), get.Err())
```

### Executing unsupported commands

To execute an arbitrary/custom command:

```go
val, err := rdb.Do(ctx, "get", "key").Result()
if err != nil {
	if err == redis.Nil {
		fmt.Println("key does not exists")
		return
	}
	panic(err)
}
fmt.Println(val.(string))
```

`Do` returns a [Cmd](https://pkg.go.dev/github.com/redis/go-redis/v9#Cmd) that has helpers to work with the `interface{}` value.

```go
// Text is a shortcut for get.Val().(string) with proper error handling.
val, err := rdb.Do(ctx, "get", "key").Text()
fmt.Println(val, err)
```

Here is the full list of helpers.

```go
s, err := cmd.Text()
flag, err := cmd.Bool()

num, err := cmd.Int()
num, err := cmd.Int64()
num, err := cmd.Uint64()
num, err := cmd.Float32()
num, err := cmd.Float64()

ss, err := cmd.StringSlice()
ns, err := cmd.Int64Slice()
ns, err := cmd.Uint64Slice()
fs, err := cmd.Float32Slice()
fs, err := cmd.Float64Slice()
bs, err := cmd.BoolSlice()
```

### redis.Nil

go-redis exports the redis.Nil error and returns it whenever the Redis server responds with `(nil)`. You can use `redis-cli` to check what response Redis returns.

This example uses `redis.Nil` to distinguish an empty string reply and a `nil` reply (`key does not exist`).

```go
val, err := rdb.Get(ctx, "key").Result()
switch {
case err == redis.Nil:
	fmt.Println("key does not exist")
case err != nil:
	fmt.Println("Get failed", err)
case val == "":
	fmt.Println("value is empty")
}
```

`GET` is not the only command that returns nil reply. For example, `BLPOP` and `ZSCORE` can also return `redis.Nil`.

### Conn

`Conn` represents a single Redis connection rather than a pool of connections. Run commands from the client unless there is a specific need for a continuous single Redis connection.

```go
cn := rdb.Conn(ctx)
defer cn.Close()

if err := cn.ClientSetName(ctx, "myclient").Err(); err != nil {
	panic(err)
}

name, err := cn.ClientGetName(ctx).Result()
if err != nil {
	panic(err)
}
fmt.Println("client name", name)
```

### Example: Scan hash fields into a struct

Commands that return multiple keys and values provide a helper to scan results into a struct, for example, commands like `HGETALL`, `HMGET`, and `MGET`.

You can use redis struct field tag to change field names or completely ignore some fields:

```go
type Model struct {
	Str1    string   `redis:"str1"`
	Str2    string   `redis:"str2"`
	Int     int      `redis:"int"`
	Bool    bool     `redis:"bool"`
	Ignored struct{} `redis:"-"`
}
```

Because `go-redis` does not provide a helper to save structs in Redis, you can use a pipeline to load some data into your database.

```go
rdb := redis.NewClient(&redis.Options{
	Addr: ":6379",
})

if _, err := rdb.Pipelined(ctx, func(rdb redis.Pipeliner) error {
	rdb.HSet(ctx, "key", "str1", "hello")
	rdb.HSet(ctx, "key", "str2", "world")
	rdb.HSet(ctx, "key", "int", 123)
	rdb.HSet(ctx, "key", "bool", 1)
	return nil
}); err != nil {
	panic(err)
_}
```

After that, you can scan the data using `HGETALL`.

```go
var model1 Model
// Scan all fields into the model.
if err := rdb.HGetAll(ctx, "key").Scan(&model1); err != nil {
	panic(err)
}
```

Or by using `HMGET`:

```go
var model2 Model
// Scan a subset of the fields.
if err := rdb.HMGet(ctx, "key", "str1", "int").Scan(&model2); err != nil {
	panic(err)
}
```

### Learn more

* [Documentation](https://redis.uptrace.dev/guide/)
* [GitHub](https://github.com/redis/go-redis)
 
