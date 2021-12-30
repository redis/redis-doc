# Lua API for Redis Scripts

Redis comes with 2 approaches to programability:

* [Redis Functions](/topics/function) (available on Redis 7 and above)
* [Redis Eval Scripts](/topics/evalintro)

Both approaches allows writing the scripts in [Lua](https://www.lua.org/).
Here we will describe the Lua API spacifications provided by Redis.

* [The Redis object](lua#the-redis-object)
  * [redis.call/pcall](lua#rediscallpcall)
  * [redis.error_reply](lua#rediserrorreply)
  * [redis.status_reply](lua#redisstatusreply)
  * [redis.sha1hex](lua#redissha1hex)
  * [redis.log](lua#redislog)
  * [redis.setresp](lua#redissetresp)
  * [redis.set_repl](lua#redissetrepl)
  * [redis.replicate_commands](lua#redisreplicatecommands)
* [Conversion between Lua and Redis data types](lua#conversion-between-lua-and-redis-data-types)
* [Global variables protection](lua#global-variables-protection)
* [Error handling](lua#error-handling)
* [Using SELECT inside scripts](lua#using-select-inside-scripts)
* [Available libraries](lua#available-libraries)
  * [struct](lua#struct)
  * [CJSON](lua#cjson)
  * [cmsgpack](lua#cmsgpack)
  * [bitop](lua#bitop)

## The Redis object

When running Lua code inside Redis there is a singleton `redis` object that is
embeded to the environment by default. All the inteructions with Redis is done
using this object. We will list the API provided with explainations and examples:

redis.call/pcall
---

It is possible to call Redis commands from a Lua script using two different Lua
functions:

* `redis.call()`
* `redis.pcall()`

`redis.call()` is similar to `redis.pcall()`, the only difference is that if a
Redis command call will result in an error, `redis.call()` will raise a Lua
error that in turn will force `EVAL` to return an error to the command caller,
while `redis.pcall` will trap the error and return a Lua table representing the
error.

The arguments of the `redis.call()` and `redis.pcall()` functions are all
the arguments of a well formed Redis command:

```
redis.call('set','foo','bar')" 0
```

The above script sets the key `foo` to the string `bar`.

redis.error_reply
---

returns an error reply. This function simply returns a single field table with the `err` field set to the specified string for you.

Example:

```
return {err="My Error"}
```

redis.status_reply
---

returns a status reply. This function simply returns a single field table with the `ok` field set to the specified string for you.

Example:

```
return redis.error_reply("My Error")
```

redis.sha1hex
---

Perform the SHA1 of the input string.

Example:

```
return redis.sha1hex('foo')'
```

redis.log
---

It is possible to write to the Redis log file from Lua scripts using the
`redis.log` function.

```
redis.log(loglevel,message)
```

`loglevel` is one of:

* `redis.LOG_DEBUG`
* `redis.LOG_VERBOSE`
* `redis.LOG_NOTICE`
* `redis.LOG_WARNING`

They correspond directly to the normal Redis log levels.
Only logs emitted by scripting using a log level that is equal or greater than
the currently configured Redis instance log level will be emitted.

The `message` argument is simply a string.
Example:

```
redis.log(redis.LOG_WARNING,"Something is wrong with this script.")
```

Will generate the following:

```
[32343] 22 Mar 15:21:39 # Something is wrong with this script.
```

redis.setresp
---

Available on Redis 6 and above and allows to get RESP 3 format replies from [redis.call](lua#rediscallpcall).
For more information please refer to [Conversion between Lua and Redis data types](lua#conversion-between-lua-and-redis-data-types) section


redis.set_repl
---

It is possible to have more control over the way commands are propagated to replicas and the AOF.
This is a very advanced feature since **a misuse can do damage** by breaking the contract that the master, replicas, and AOF must all contain the same logical content.

However this is a useful feature since, sometimes, we need to execute certain
commands only in the master in order to create, for example, intermediate
values.

Think of a Lua script where we perform an intersection between two sets.
We then pick five random elements from the intersection and create a new set
containing them.
Finally, we delete the temporary key representing the intersection
between the two original sets. What we want to replicate is only the creation
of the new set with the five elements. It's not useful to also replicate the
commands creating the temporary key.

For this reason, Redis 3.2 introduces a new command that only works when
script effects replication is enabled, and is able to control the scripting
replication engine. The command is called `redis.set_repl()` and fails raising
an error if called when script effects replication is disabled.

**Notice! On Redis 7 and above, script replication was drop and the only supported replication
is effects replication.**

The command can be called with four different arguments:

    redis.set_repl(redis.REPL_ALL) -- Replicate to the AOF and replicas.
    redis.set_repl(redis.REPL_AOF) -- Replicate only to the AOF.
    redis.set_repl(redis.REPL_REPLICA) -- Replicate only to replicas (Redis >= 5)
    redis.set_repl(redis.REPL_SLAVE) -- Used for backward compatibility, the same as REPL_REPLICA.
    redis.set_repl(redis.REPL_NONE) -- Don't replicate at all.

By default the scripting engine is set to `REPL_ALL`.
By calling this function the user can switch the replication mode on or off at any time.

A simple example follows:

    redis.replicate_commands() -- Enable effects replication.
    redis.call('set','A','1')
    redis.set_repl(redis.REPL_NONE)
    redis.call('set','B','2')
    redis.set_repl(redis.REPL_ALL)
    redis.call('set','C','3')

After running the above script, the result is that only the keys A and C will be created on the replicas and AOF.

redis.replicate_commands
---

enable script effects replication, must be called before the script performs any write.
Notice that this API only relevant to `EVAL` scripts and only when script replication is configured.
For further reader, please refer to [`Replicating commands instead of scripts`](evalintro#replicating-commands-instead-of-scripts)


## Conversion between Lua and Redis data types

Redis return values are converted into Lua data types when Lua calls a Redis
command using [`call()`](lua#rediscallpcall) or [`pcall()`](lua#rediscallpcall).
Similarly, Lua data types are converted into the Redis protocol when calling
a Redis command and when a Lua script returns a value, so that scripts can
control what `EVAL` will return to the client.

This conversion between data types is designed in a way that if a Redis type is
converted into a Lua type, and then the result is converted back into a Redis
type, the result is the same as the initial value.

In other words there is a one-to-one conversion between Lua and Redis types.
The following table shows you all the conversions rules:

**Redis to Lua** conversion table.

* Redis integer reply -> Lua number
* Redis bulk reply -> Lua string
* Redis multi bulk reply -> Lua table (may have other Redis data types nested)
* Redis status reply -> Lua table with a single `ok` field containing the status
* Redis error reply -> Lua table with a single `err` field containing the error
* Redis Nil bulk reply and Nil multi bulk reply -> Lua false boolean type

**Lua to Redis** conversion table.

* Lua number -> Redis integer reply (the number is converted into an integer)
* Lua string -> Redis bulk reply
* Lua table (array) -> Redis multi bulk reply (truncated to the first nil inside the Lua array if any)
* Lua table with a single `ok` field -> Redis status reply
* Lua table with a single `err` field -> Redis error reply
* Lua boolean false -> Redis Nil bulk reply.

There is an additional Lua-to-Redis conversion rule that has no corresponding
Redis to Lua conversion rule:

* Lua boolean true -> Redis integer reply with value of 1.

Lastly, there are three important rules to note:

* Lua has a single numerical type, Lua numbers. There is no distinction between integers and floats. So we always convert Lua numbers into integer replies, removing the decimal part of the number if any. **If you want to return a float from Lua you should return it as a string**, exactly like Redis itself does (see for instance the `ZSCORE` command).
* There is [no simple way to have nils inside Lua arrays](http://www.lua.org/pil/19.1.html), this is a result of Lua table semantics, so when Redis converts a Lua array into Redis protocol the conversion is stopped if a nil is encountered.
* When a Lua table contains keys (and their values), the converted Redis reply will **not** include them.

Here are a few conversion examples:

```
> eval "return 10" 0
(integer) 10

> eval "return {1,2,{3,'Hello World!'}}" 0
1) (integer) 1
2) (integer) 2
3) 1) (integer) 3
   2) "Hello World!"

> eval "return redis.call('get','foo')" 0
"bar"
```
The last example shows how it is possible to receive the exact return value of
`redis.call()` or `redis.pcall()` from Lua that would be returned if the command
was called directly.

In the following example we can see how floats and arrays containing nils and keys are handled:

```
> eval "return {1,2,3.3333,somekey='somevalue','foo',nil,'bar'}" 0
1) (integer) 1
2) (integer) 2
3) (integer) 3
4) "foo"
```

As you can see 3.333 is converted into 3, *somekey* is excluded, and the *bar* string is never returned as there is a nil before.

**RESP3 mode conversion rules**:

Starting with Redis version 6, the server supports two different protocols.
One is called RESP2, and is the old protocol: all the new connections to
the server start in this mode. However clients are able to negotiate the
new protocol using the `HELLO` command: this way the connection is put
in RESP3 mode. In this mode certain commands, like for instance `HGETALL`,
reply with a new data type (the Map data type in this specific case). The
RESP3 protocol is semantically more powerful, however most scripts are OK
with using just RESP2.

The Lua engine always assumes to run in RESP2 mode when talking with Redis,
so whatever the connection that is invoking the script 
(`FCALL` or `FCALL_RO`/`EVAL` or `EVALSHA` command
is in RESP2 or RESP3 mode, Lua scripts will, by default, still see the
same kind of replies they used to see in the past from Redis, when calling
commands using the [`redis.call()`](lua#rediscallpcall) built-in function.

However Lua scripts running in Redis 6 or greater, are able to switch to
RESP3 mode, and get the replies using the new available types. Similarly
Lua scripts are able to reply to clients using the new types. Please make
sure to understand
[the capabilities for RESP3](https://github.com/antirez/resp3)
before continuing reading this section.

In order to switch to RESP3 a script should call this function:

    redis.setresp(3)

Note that a script can switch back and forth from RESP3 and RESP2 by
calling the function with the argument '3' or '2'.

At this point the new conversions are available, specifically:

**Redis to Lua** conversion table specific to RESP3:

* Redis map reply -> Lua table with a single `map` field containing a Lua table representing the fields and values of the map.
* Redis set reply -> Lua table with a single `set` field containing a Lua table representing the elements of the set as fields, having as value just `true`.
* Redis new RESP3 single null value -> Lua nil.
* Redis true reply -> Lua true boolean value.
* Redis false reply -> Lua false boolean value.
* Redis double reply -> Lua table with a single `score` field containing a Lua number representing the double value.
* Redis big number reply -> Lua table with a single `big_number` field containing a Lua string representing the big number value.
* Redis verbatim string reply -> Lua table with a single `verbatim_string` field containing a Lua table with two fields, `string` and `format`, representing the verbatim string and verbatim format respectively.
* All the RESP2 old conversions still apply.

Note: the big number and verbatim replies are only available in Redis 7 or greater. Also, presently RESP3 attributes are not supported in Lua.

**Lua to Redis** conversion table specific for RESP3.

* Lua boolean -> Redis boolean true or false. **Note that this is a change compared to the RESP2 mode**, where returning true from Lua returned the number 1 to the Redis client, and returning false used to return NULL.
* Lua table with a single `map` field set to a field-value Lua table -> Redis map reply.
* Lua table with a single `set` field set to a field-value Lua table -> Redis set reply, the values are discarded and can be anything.
* Lua table with a single `double` field set to a field-value Lua table -> Redis double reply.
* Lua null -> Redis RESP3 new null reply (protocol `"_\r\n"`).
* All the RESP2 old conversions still apply unless specified above.

There is one key thing to understand: in case Lua replies with RESP3 types, but the connection calling Lua is in RESP2 mode, Redis will automatically convert the RESP3 protocol to RESP2 compatible protocol, as it happens for normal commands. For instance returning a map type to a connection in RESP2 mode will have the effect of returning a flat array of fields and values.

## Global variables protection

Redis scripts are not allowed to create global variables, in order to avoid
leaking data into the Lua state.
If a script needs to maintain state between calls (a pretty uncommon need) it
should use Redis keys instead.

When global variable access is attempted the script is terminated and
returns with an error:

```
redis 127.0.0.1:6379> eval 'a=10' 0
(error) ERR Error running script (call to f_933044db579a2f8fd45d8065f04a8d0249383e57): user_script:1: Script attempted to create global variable 'a'
```

Accessing a _non existing_ global variable generates a similar error.

Using Lua debugging functionality or other approaches like altering the meta
table used to implement global protections in order to circumvent globals
protection is not hard.
However it is difficult to do it accidentally.
If the user messes with the Lua global state, the consistency of AOF and
replication is not guaranteed: don't do it.

Note for Lua newbies: in order to avoid using global variables in your scripts
simply declare every variable you are going to use using the _local_ keyword.

## Error handling

As already stated, calls to [`redis.call()`](lua#rediscallpcall) resulting in a Redis command error
will stop the execution of the script and return an error, in a way that
makes it obvious that the error was generated by a script:

```
> del foo
(integer) 1
> lpush foo a
(integer) 1
> eval "return redis.call('get','foo')" 0
(error) ERR Error running script (call to f_6b1bf486c81ceb7edf3c093f4c48582e38c0e791): ERR Operation against a key holding the wrong kind of value
```

Using [`redis.pcall()`](lua#rediscallpcall) no error is raised, but an error object is
returned in the format specified above (as a Lua table with an `err` field).
The script can pass the exact error to the user by returning the error object
returned by [`redis.pcall()`](lua#rediscallpcall).

## Using SELECT inside scripts

It is possible to call `SELECT` inside Lua scripts like with normal clients,
However one subtle aspect of the behavior changes between Redis 2.8.11 and
Redis 2.8.12. Before the 2.8.12 release the database selected by the Lua
script was *transferred* to the calling script as current database.
Starting from Redis 2.8.12 the database selected by the Lua script only
affects the execution of the script itself, but does not modify the database
selected by the client calling the script.

The semantic change between patch level releases was needed since the old
behavior was inherently incompatible with the Redis replication layer and
was the cause of bugs.

## Available libraries

The Redis Lua interpreter loads the following Lua libraries:

* `base` lib.
* `table` lib.
* `string` lib.
* `math` lib.
* `struct` lib.
* `cjson` lib.
* `cmsgpack` lib.
* `bitop` lib.
* `redis.sha1hex` function.
* `redis.breakpoint and redis.debug` function in the context of the [Redis Lua debugger](/topics/ldb).

Every Redis instance is _guaranteed_ to have all the above libraries so you can
be sure that the environment for your Redis scripts is always the same.

struct, CJSON and cmsgpack are external libraries, all the other libraries are standard
Lua libraries.

struct
---

struct is a library for packing/unpacking structures within Lua.

```
Valid formats:
> - big endian
< - little endian
![num] - alignment
x - pading
b/B - signed/unsigned byte
h/H - signed/unsigned short
l/L - signed/unsigned long
T   - size_t
i/In - signed/unsigned integer with size `n' (default is size of int)
cn - sequence of `n' chars (from/to a string); when packing, n==0 means
     the whole string; when unpacking, n==0 means use the previous
     read number as the string length
s - zero-terminated string
f - float
d - double
' ' - ignored
```


Example (using eval script):

```
127.0.0.1:6379> eval 'return struct.pack("HH", 1, 2)' 0
"\x01\x00\x02\x00"
127.0.0.1:6379> eval 'return {struct.unpack("HH", ARGV[1])}' 0 "\x01\x00\x02\x00"
1) (integer) 1
2) (integer) 2
3) (integer) 5
127.0.0.1:6379> eval 'return struct.size("HH")' 0
(integer) 4
```

CJSON
---

The CJSON library provides extremely fast JSON manipulation within Lua.

Example (using eval script):

```
redis 127.0.0.1:6379> eval 'return cjson.encode({["foo"]= "bar"})' 0
"{\"foo\":\"bar\"}"
redis 127.0.0.1:6379> eval 'return cjson.decode(ARGV[1])["foo"]' 0 "{\"foo\":\"bar\"}"
"bar"
```

cmsgpack
---

The cmsgpack library provides simple and fast MessagePack manipulation within Lua.

Example (using eval script):

```
127.0.0.1:6379> eval 'return cmsgpack.pack({"foo", "bar", "baz"})' 0
"\x93\xa3foo\xa3bar\xa3baz"
127.0.0.1:6379> eval 'return cmsgpack.unpack(ARGV[1])' 0 "\x93\xa3foo\xa3bar\xa3baz"
1) "foo"
2) "bar"
3) "baz"
```

bitop
---

The Lua Bit Operations Module adds bitwise operations on numbers.
It is available for scripting in Redis since version 2.8.18.

Example (using eval script):

```
127.0.0.1:6379> eval 'return bit.tobit(1)' 0
(integer) 1
127.0.0.1:6379> eval 'return bit.bor(1,2,4,8,16,32,64,128)' 0
(integer) 255
127.0.0.1:6379> eval 'return bit.tohex(422342)' 0
"000671c6"
```

It supports several other functions:
`bit.tobit`, `bit.tohex`, `bit.bnot`, `bit.band`, `bit.bor`, `bit.bxor`,
`bit.lshift`, `bit.rshift`, `bit.arshift`, `bit.rol`, `bit.ror`, `bit.bswap`.
All available functions are documented in the [Lua BitOp documentation](http://bitop.luajit.org/api.html)
