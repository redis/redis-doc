

`MULTI`, `EXEC`, `DISCARD` and `WATCH` commands are the foundation of Redis Transactions.
A Redis Transaction allows the execution of a group of Redis commands in a
single step, with two important guarantees:

* All the commands in a transaction are serialized and executed sequentially. It can never happen that a request issued by another client is served **in the middle** of the execution of a Redis transaction. This guarantees that the commands are executed as a single atomic operation.
* Either all of the commands or none are processed. The `EXEC` command triggers the execution of all the commands in the transaction, so if a client loses the connection to the server in the context of a transaction before calling the `MULTI` command none of the operations are performed, instead if the `EXEC` command is called, all the operations are performed. An exception to this rule is when the Append Only File is enabled: every command that is part of a Redis transaction will log in the AOF as long as the operation is completed, so if the Redis server crashes or is killed by the system administrator in some hard way it is possible that only a partial number of operations are registered.

Since Redis 2.1.0, it's also possible to add a further guarantee to the above
two, in the form of optimistic locking of a set of keys in a way very similar
to a CAS (check and set) operation. This is documented later in this manual
page.

## Usage

A Redis transaction is entered using the `MULTI` command. The command always
replies with OK. At this point the user can issue multiple commands. Instead
of executing these commands, Redis will queue them. All the commands are executed
once `EXEC` is called.

Calling `DISCARD` instead will flush the transaction queue and will exit the
transaction.

The following is an example using the Ruby client:

    ? r.multi
    = OK
     r.incr foo
    = QUEUED
     r.incr bar
    = QUEUED
     r.incr bar
    = QUEUED
     r.exec
    = [1, 1, 2]

As it is possible to see from the session above, `MULTI` returns an array of
replies, where every element is the reply of a single command in the transaction,
in the same order the commands were queued.

When a Redis connection is in the context of a `MULTI` request, all the commands
will reply with a simple string QUEUED if they are correct from the point of
view of the syntax and arity (number of arguments) of the commaand. Some commands
are still allowed to fail during execution time.

This is more clear on the protocol level; In the following example one command
will fail when executed even if the syntax is right:

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

`MULTI` returned a two elements bulk reply where one is an +OK code and one is
a -ERR reply. It's up to the client lib to find a sensible way to provide the
error to the user.

IMPORTANT: even when a command will raise an error, all the other commands
in the queue will be processed. Redis will NOT stop the processing of
commands once an error is found.

Another example, again using the write protocol with telnet, shows how syntax
errors are reported ASAP instead:

    MULTI
    +OK
    INCR a b c
    -ERR wrong number of arguments for 'incr' command

This time due to the syntax error the bad `INCR` command is not queued at all.


## The `DISCARD` command

`DISCARD` can be used in order to abort a transaction. No command will be executed,
and the state of the client is again the normal one, outside of a transaction.
Example using the Ruby client:

    ? r.set(foo,1)
    = true
     r.multi
    = OK
     r.incr(foo)
    = QUEUED
     r.discard
    = OK
     r.get(foo)
    = 1

## Check and Set (CAS) transactions using `WATCH`

`WATCH` is used in order to provide a CAS (Check and Set) behavior to Redis Transactions.


`WATCH`ed keys are monitored in order to detect changes against this keys. If
at least a watched key will be modified before the `EXEC` call, the whole transaction
will abort, and `EXEC` will return a nil object (A Null Multi Bulk reply) to
notify that the transaction failed.

For example imagine we have the need to atomically increment the value of a
key by 1 (I know we have `INCR`, let's suppose we don't have it).

The first try may be the following:

    val = GET mykey
    val = val + 1
    SET mykey $val

This will work reliably only if we have a single client performing the operation
in a given time. If multiple clients will try to increment the key about a
the same time there will be a race condition. For instance client A and B will
read the old value, for instance, 10. The value will be incremented to 11 by
both the clients, and finally `SET` as the value of the key. So the final value
will be 11 instead of 12.

Thanks to `WATCH` we are able to model the problem very well:

    WATCH mykey
    val = GET mykey
    val = val + 1
    MULTI
    SET mykey $val
    EXEC

Using the above code, if there are race conditions and another client modified
the result of _val_ in the time between our call to `WATCH` and our call to `EXEC`,
the transaction will fail.

We'll have just to re-iterate the operation hoping this time we'll not ge
a new race. This form of locking is called **optimistic locking** and is a
very powerful form of locking as in many problems there are multiple clients
accessing a much bigger number of keys, so it's very unlikely that there are
collisions: usually operations don't need to be performed multiple times.

## `WATCH` explained

So what is `WATCH` really about? It is a command that will make the `EXEC` conditional:
we are asking Redis to perform the transaction only if no other client modified
any of the `WATCH`ed keys. Otherwise the transaction is not entered at all. (Note
that if you `WATCH` a volatile key and Redis expires the key after you `WATCH`ed
it, `EXEC` will still work. [More](http://code.google.com/p/redis/issues/detail?id=270).)

`WATCH` can be called multiple times. Simply all the `WATCH` calls will have the
effects to watch for changes starting from the call, up to the moment `EXEC`
is called.

When `EXEC` is called, either if it will fail or succeed, all keys are `UNWATCH`ed.
Also when a client connection is closed, everything gets `UNWATCH`ed.

It is also possible to use the `UNWATCH` command (without arguments) in order
to flush all the watched keys. Sometimes this is useful as we optimistically
lock a few keys, since possibly we need to perform a transaction to alter those
keys, but after reading the current content of the keys we don't want to proceed.
When this happens we just call `UNWATCH` so that the connection can already be
used freely for new transactions.

## `WATCH` used to implement ZPOP

A good example to illustrate how `WATCH` can be used to create new atomic operations
otherwise not supported by Redis is to implement ZPOP, that is a command tha
pops the element with the lower score from a sorted set in an atomic way. This
is the simplest implementation:

    WATCH zse
    ele = ZRANGE zset 0 0
    MULTI
    ZREM zset ele
    EXEC

If `EXEC` fails (returns a nil value) we just re-iterate the operation.

@return

@multi-bulk-reply, specifically:

    The result of a MULTI/EXEC command is a multi bulk reply where every elemen
    is the return value of every command in the atomic transaction.

If a `MULTI`/`EXEC` transaction is aborted because of `WATCH` detected modified keys,
a @nil-reply is returned.
