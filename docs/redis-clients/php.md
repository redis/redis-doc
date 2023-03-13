---
title: "PHP guide"
linkTitle: "PHP"
description: Connect your PHP application to a Redis database
weight: 5

---

Install Redis and the Redis client, then connect your PHP application to a Redis database. 

## Predis

[Predis](https://github.com/predis/predis) is a .PHP Client for Redis.
`Predis` requires a running Redis server a running Redis or [Redis Stack](https://redis.io/docs/stack/get-started/install/) server. See [Getting started](/docs/getting-started/) for Redis installation instructions.

### Install

To manage projects dependencies more easily using [Composer](http://packagist.org/about-composer), get the [Packagist](http://packagist.org/packages/predis/predis) library.
Compressed archives of each release are available on [GitHub](https://github.com/predis/predis/releases).

```shell
composer require predis/predis
```

To load its files, `Predis` relies on the PHP autoloading features and complies with the
[PSR-4 standard](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-4-autoloader.md).
Autoloading is handled automatically when dependencies are managed through Composer, but it is also
possible to leverage its own autoloader in projects or scripts lacking any autoload facility:

Prepend a base path if Predis is not available in your `include_path`.

```php
require 'Predis/Autoloader.php';
Predis\Autoloader::register();
```

### Connect

When creating a client instance without passing any connection parameter, Predis assumes `127.0.0.1`
and `6379` as default host and port. The default timeout for the `connect()` operation is 5 seconds:

```php
$client = new Predis\Client();
$client->set('foo', 'bar');
$value = $client->get('foo');
```

Connection parameters can be supplied either in the form of URI strings or named arrays. The latter
is the preferred way to supply parameters, but URI strings can be useful when parameters are read
from non-structured or partially-structured sources:

To pass parameters using a named array:

```php
$client = new Predis\Client([
    'scheme' => 'tcp',
    'host'   => '10.0.0.1',
    'port'   => 6379,
]);
```

To pass the same set of parameters using an URI string:

```php
$client = new Predis\Client('tcp://10.0.0.1:6379');
```

Password-protected servers can be accessed by adding `password` to the parameters set. When ACLs are
enabled on Redis >= 6.0, both `username` and `password` are required for user authentication.

It is also possible to connect to local instances of Redis using UNIX domain sockets. In this case,
the parameters must use the `unix` scheme and specify a path for the socket file:

```php
$client = new Predis\Client(['scheme' => 'unix', 'path' => '/path/to/redis.sock']);
$client = new Predis\Client('unix:/path/to/redis.sock');
```

The client can leverage TLS/SSL encryption to connect to secured remote Redis instances without the
need to configure an SSL proxy like stunnel. This can be useful when connecting to nodes running on
various cloud hosting providers. Encryption can be enabled with using the `tls` scheme and an array
of suitable [options](http://php.net/manual/context.ssl.php) passed via the `ssl` parameter:

```php
// Named array of connection parameters:
$client = new Predis\Client([
  'scheme' => 'tls',
  'ssl'    => ['cafile' => 'private.pem', 'verify_peer' => true],
]);
// Same set of parameters, but using an URI string:
$client = new Predis\Client('tls://127.0.0.1?ssl[cafile]=private.pem&ssl[verify_peer]=1');
```

The connection schemes [`redis`](http://www.iana.org/assignments/uri-schemes/prov/redis) (alias of
`tcp`) and [`rediss`](http://www.iana.org/assignments/uri-schemes/prov/rediss) (alias of `tls`) are
also supported, with the difference that URI strings containing these schemes are parsed following
the rules described on their respective IANA provisional registration documents.

The actual list of supported connection parameters can vary depending on each connection backend so
it is recommended to refer to their specific documentation or implementation for details.

Predis can aggregate multiple connections when providing an array of connection parameters and the
appropriate option to instruct the client about how to aggregate them (clustering, replication or a
custom aggregation logic). Named arrays and URI strings can be mixed when providing configurations
for each node:

```php
$client = new Predis\Client([
    'tcp://10.0.0.1?alias=first-node', ['host' => '10.0.0.2', 'alias' => 'second-node'],
], [
    'cluster' => 'predis',
]);
```

For more information, see [Aggregate connections](https://github.com/predis/predis#aggregate-connections).

Connections to Redis are lazy meaning that the client connects to a server only if and when needed.
While it is recommended to let the client do its own stuff under the hood, there may be times when
it is still desired to have control of when the connection is opened or closed: this can easily be
achieved by invoking `$client->connect()` and `$client->disconnect()`. Please note that the effect
of these methods on aggregate connections may differ depending on each specific implementation.

### Learn more

* [GitHub](https://github.com/redis/NRedisStack)
 