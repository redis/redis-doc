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

To install go-redis/v9 (currently in beta):

```
go get github.com/redis/go-redis/v9
```

### Connect

To connect to a Redis server:

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

### Learn more

* [Documentation](https://redis.uptrace.dev/guide/)
* [GitHub](https://github.com/redis/go-redis)
 
