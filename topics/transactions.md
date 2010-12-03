Transactions
============

`MULTI`, `EXEC`, `DISCARD` and `WATCH` are the foundation of
transactions in Redis.  They allow the execution of a group of commands
in a single step, with two important guarantees:

* All the commands in a transaction are serialized and executed
sequentially. It can never happen that a request issued by another
client is served **in the middle** of the execution of a Redis
transaction. This guarantees that the commands are executed as a single
atomic operation.

* Either all of the commands or none are processed. The `EXEC` command
triggers the execution of all the commands in the transaction, so
if a client loses the connection to the server in the context of a
transaction before calling the `MULTI` command none of the operations
are performed, instead if the `EXEC` command is called, all the
operations are performed. An exception to this rule is when the
@append-only-file is enabled: every command that is part of a Redis
transaction will log in the AOF as long as the operation is completed,
so if the Redis server crashes or is killed by the system administrator
in some hard way it is possible that only a partial number of operations
are registered.

Redis 2.2 allows for an extra guarantee to the above two, in the form
of optimistic locking in a way very similar to a check-and-set (CAS)
operation. This is documented [later](#cas) on this page.

## Usage

A Redis transaction is entered using the `MULTI` command. The command
always replies with `OK`. At this point the user can issue multiple
commands. Instead of executing these commands, Redis will queue
them. All the commands are executed once `EXEC` is called.

Calling `DISCARD` instead will flush the transaction queue and will exit
the transaction.

The following example increments keys `foo` and `bar` atomically.

    > MULTI
    OK
    > INCR foo
    QUEUED
    > INCR bar
    QUEUED
    > EXEC
    1) (integer) 1
    2) (integer) 1

As it is possible to see from the session above, `MULTI` returns an
array of replies, where every element is the reply of a single command
in the transaction, in the same order the commands were issued.

When a Redis connection is in the context of a `MULTI` request,
all commands will reply with the string `QUEUED` unless they are
syntactically incorrect. Some commands are still allowed to fail during
execution time.

This is more clear on the protocol level. In the following example one
command will fail when executed even if the syntax is right:

    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    MULTI
    +OK
    SET a 3
    abc
    +QUEUED
    LPOP a
    +QUEUED
    EXEC
    *2
    +OK
    -ERR Operation against a key holding the wrong kind of value

`MULTI` returned two-element @bulk-reply where one is an `OK` code and
the other an `-ERR` reply. It's up to the client library to find a
sensible way to provide the error to the user.

It's important to note that **even when a command fails, all the other
commands in the queue are processed** – Redis will _not_ stop the
processing of commands.

Another example, again using the wire protocol with `telnet`, shows how
syntax errors are reported ASAP instead:

    MULTI
    +OK
    INCR a b c
    -ERR wrong number of arguments for 'incr' command

This time due to the syntax error the bad `INCR` command is not queued
at all.

## Discarding the command queue

`DISCARD` can be used in order to abort a transaction. In this case, no
commands are executed and the state of the connection is restored to
normal.

    > SET foo 1
    OK
    > MULTI
    OK
    > INCR foo
    QUEUED
    > DISCARD
    OK
    > GET foo
    "1"

<a name="cas"></a>

## Optimistic locking using check-and-set

`WATCH` is used to provide a check-and-set (CAS) behavior to Redis
transactions.

`WATCH`ed keys are monitored in order to detect changes against them. If
at least one watched key is modified before the `EXEC` command, the
whole transaction aborts, and `EXEC` returns a @nil-reply to notify that
the transaction failed.

For example, imagine we have the need to atomically increment the value
of a key by 1 (let's suppose Redis doesn't have `INCR`).

The first try may be the following:

    val = GET mykey
    val = val + 1
    SET mykey $val

This will work reliably only if we have a single client performing the
operation in a given time. If multiple clients try to increment the key
at about the same time there will be a race condition. For instance,
client A and B will read the old value, for instance, 10. The value will
be incremented to 11 by both the clients, and finally `SET` as the value
of the key. So the final value will be 11 instead of 12.

Thanks to `WATCH` we are able to model the problem very well:

    WATCH mykey
    val = GET mykey
    val = val + 1
    MULTI
    SET mykey $val
    EXEC

Using the above code, if there are race conditions and another client
modifies the result of `val` in the time between our call to `WATCH` and
our call to `EXEC`, the transaction will fail.

We just have to repeat the operation hoping this time we'll not get a
new race. This form of locking is called _optimistic locking_ and is
a very powerful form of locking. In many use cases, multiple clients
will be accessing different keys, so collisions are unlikely – usually
there's no need to repeat the operation.

## `WATCH` explained

So what is `WATCH` really about? It is a command that will
make the `EXEC` conditional: we are asking Redis to perform
the transaction only if no other client modified any of the
`WATCH`ed keys. Otherwise the transaction is not entered at
all. (Note that if you `WATCH` a volatile key and Redis expires
the key after you `WATCH`ed it, `EXEC` will still work. [More on
this](http://code.google.com/p/redis/issues/detail?id=270).)

`WATCH` can be called multiple times. Simply all the `WATCH` calls will
have the effects to watch for changes starting from the call, up to
the moment `EXEC` is called. You can also send any number of keys to a
single `WATCH` call.

When `EXEC` is called, all keys are `UNWATCH`ed, regardless of whether
the transaction was aborted or not.  Also when a client connection is
closed, everything gets `UNWATCH`ed.

It is also possible to use the `UNWATCH` command (without arguments)
in order to flush all the watched keys. Sometimes this is useful as we
optimistically lock a few keys, since possibly we need to perform a
transaction to alter those keys, but after reading the current content
of the keys we don't want to proceed.  When this happens we just call
`UNWATCH` so that the connection can already be used freely for new
transactions.

### Using `WATCH` to implement ZPOP

A good example to illustrate how `WATCH` can be used to create new
atomic operations otherwise not supported by Redis is to implement ZPOP,
that is a command that pops the element with the lower score from a
sorted set in an atomic way. This is the simplest implementation:

    WATCH zse
    ele = ZRANGE zset 0 0
    MULTI
    ZREM zset ele
    EXEC

If `EXEC` fails (ie returns a @nil-reply) we just repeat the operation.
