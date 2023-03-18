---
title: "Redis functions"
linkTitle: "Functions"
weight: 1
description: >
   Scripting with Redis 7 and beyond
aliases:
    - /topics/functions-intro
---

Redis Functions is an API for managing code to be executed on the server. This feature, which became available in Redis 7, supersedes the use of [EVAL](/docs/manual/programmability/eval-intro) in prior versions of Redis.

## Prologue (or, what's wrong with Eval Scripts?)

Prior versions of Redis made scripting available only via the `EVAL` command, which allows a Lua script to be sent for execution by the server.
The core use cases for [Eval Scripts](/topics/eval-intro) is executing part of your application logic inside Redis, efficiently and atomically.
Such script can perform conditional updates across multiple keys, possibly combining several different data types.

Using `EVAL` requires that the application sends the entire script for execution every time.
Because this results in network and script compilation overheads, Redis provides an optimization in the form of the `EVALSHA` command. By first calling `SCRIPT LOAD` to obtain the script's SHA1, the application can invoke it repeatedly afterward with its digest alone.

By design, Redis only caches the loaded scripts.
That means that the script cache can become lost at any time, such as after calling `SCRIPT FLUSH`, after restarting the server, or when failing over to a replica.
The application is responsible for reloading scripts during runtime if any are missing.
The underlying assumption is that scripts are a part of the application and not maintained by the Redis server.

This approach suits many light-weight scripting use cases, but introduces several difficulties once an application becomes complex and relies more heavily on scripting, namely:

1. All client application instances must maintain a copy of all scripts. That means having some mechanism that applies script updates to all of the application's instances.
1. Calling cached scripts within the context of a [transaction](/topics/transactions) increases the probability of the transaction failing because of a missing script. Being more likely to fail makes using cached scripts as building blocks of workflows less attractive.
1. SHA1 digests are meaningless, making debugging the system extremely hard (e.g., in a `MONITOR` session).
1. When used natively, `EVAL` promotes an anti-pattern in which scripts the client application renders verbatim scripts instead of responsibly using the [`!KEYS` and `ARGV` Lua APIs](/topics/lua-api#runtime-globals).
1. Because they are ephemeral, a script can't call another script. This makes sharing and reusing code between scripts nearly impossible, short of client-side preprocessing (see the first point).

To address these needs while avoiding breaking changes to already-established and well-liked ephemeral scripts, Redis v7.0 introduces Redis Functions.

## What are Redis Functions?

Redis functions are an evolutionary step from ephemeral scripting.

Functions provide the same core functionality as scripts but are first-class software artifacts of the database.
Redis manages functions as an integral part of the database and ensures their availability via data persistence and replication.
Because functions are part of the database and therefore declared before use, applications aren't required to load them during runtime nor risk aborted transactions.
An application that uses functions depends only on their APIs rather than on the embedded script logic in the database.

Whereas ephemeral scripts are considered a part of the application's domain, functions extend the database server itself with user-provided logic.
They can be used to expose a richer API composed of core Redis commands, similar to modules, developed once, loaded at startup, and used repeatedly by various applications / clients.
Every function has a unique user-defined name, making it much easier to call and trace its execution.

The design of Redis Functions also attempts to demarcate between the programming language used for writing functions and their management by the server.
Lua, the only language interpreter that Redis presently support as an embedded execution engine, is meant to be simple and easy to learn.
However, the choice of Lua as a language still presents many Redis users with a challenge.

The Redis Functions feature makes no assumptions about the implementation's language.
An execution engine that is part of the definition of the function handles running it.
An engine can theoretically execute functions in any language as long as it respects several rules (such as the ability to terminate an executing function).

Presently, as noted above, Redis ships with a single embedded [Lua 5.1](/topics/lua-api) engine.
There are plans to support additional engines in the future.
Redis functions can use all of Lua's available capabilities to ephemeral scripts,
with the only exception being the [Redis Lua scripts debugger](/topics/ldb).

Functions also simplify development by enabling code sharing.
Every function belongs to a single library, and any given library can consist of multiple functions.
The library's contents are immutable, and selective updates of its functions aren't allowed.
Instead, libraries are updated as a whole with all of their functions together in one operation.
This allows calling functions from other functions within the same library, or sharing code between functions by using a common code in library-internal methods, that can also take language native arguments.

Functions are intended to better support the use case of maintaining a consistent view for data entities through a logical schema, as mentioned above.
As such, functions are stored alongside the data itself.
Functions are also persisted to the AOF file and replicated from master to replicas, so they are as durable as the data itself.
When Redis is used as an ephemeral cache, additional mechanisms (described below) are required to make functions more durable.

Like all other operations in Redis, the execution of a function is atomic.
A function's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](/topics/transactions).
These semantics mean that all of the script's effects either have yet to happen or had already happened.
The blocking semantics of an executed function apply to all connected clients at all times.
Because running a function blocks the Redis server, functions are meant to finish executing quickly, so you should avoid using long-running functions.

## Loading libraries and functions

Let's explore Redis Functions via some tangible examples and Lua snippets.

At this point, if you're unfamiliar with Lua in general and specifically in Redis, you may benefit from reviewing some of the examples in [Introduction to Eval Scripts](/topics/eval-intro) and [Lua API](/topics/lua-api) pages for a better grasp of the language.

Every Redis function belongs to a single library that's loaded to Redis.
Loading a library to the database is done with the `FUNCTION LOAD` command.
The command gets the library payload as input,
the library payload must start with Shebang statement that provides a metadata about the library (like the engine to use and the library name).
The Shebang format is:
```
#!<engine name> name=<library name>
```

Let's try loading an empty library:

```
redis> FUNCTION LOAD "#!lua name=mylib\n"
(error) ERR No functions registered
```

The error is expected, as there are no functions in the loaded library. Every library needs to include at least one registered function to load successfully.
A registered function is named and acts as an entry point to the library.
When the target execution engine handles the `FUNCTION LOAD` command, it registers the library's functions.

The Lua engine compiles and evaluates the library source code when loaded, and expects functions to be registered by calling the `redis.register_function()` API.

The following snippet demonstrates a simple library registering a single function named _knockknock_, returning a string reply:

```lua
#!lua name=mylib
redis.register_function(
  'knockknock',
  function() return 'Who\'s there?' end
)
```

In the example above, we provide two arguments about the function to Lua's `redis.register_function()` API: its registered name and a callback.

We can load our library and use `FCALL` to call the registered function:

```
redis> FUNCTION LOAD "#!lua name=mylib\nredis.register_function('knockknock', function() return 'Who\\'s there?' end)"
mylib
redis> FCALL knockknock 0
"Who's there?"
```

Notice that the `FUNCTION LOAD` command returns the name of the loaded library, this name can later be used `FUNCTION LIST` and `FUNCTION DELETE`.

We've provided `FCALL` with two arguments: the function's registered name and the numeric value `0`. This numeric value indicates the number of key names that follow it (the same way `EVAL` and `EVALSHA` work).

We'll explain immediately how key names and additional arguments are available to the function. As this simple example doesn't involve keys, we simply use 0 for now.

## Input keys and regular arguments

Before we move to the following example, it is vital to understand the distinction Redis makes between arguments that are names of keys and those that aren't.

While key names in Redis are just strings, unlike any other string values, these represent keys in the database.
The name of a key is a fundamental concept in Redis and is the basis for operating the Redis Cluster.

**Important:**
To ensure the correct execution of Redis Functions, both in standalone and clustered deployments, all names of keys that a function accesses must be explicitly provided as input key arguments.

Any input to the function that isn't the name of a key is a regular input argument.

Now, let's pretend that our application stores some of its data in Redis Hashes.
We want an `HSET`-like way to set and update fields in said Hashes and store the last modification time in a new field named `_last_modified_`.
We can implement a function to do all that.

Our function will call `TIME` to get the server's clock reading and update the target Hash with the new fields' values and the modification's timestamp.
The function we'll implement accepts the following input arguments: the Hash's key name and the field-value pairs to update.

The Lua API for Redis Functions makes these inputs accessible as the first and second arguments to the function's callback.
The callback's first argument is a Lua table populated with all key names inputs to the function.
Similarly, the callback's second argument consists of all regular arguments.

The following is a possible implementation for our function and its library registration:

```lua
#!lua name=mylib

local function my_hset(keys, args)
  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

redis.register_function('my_hset', my_hset)
```

If we create a new file named _mylib.lua_ that consists of the library's definition, we can load it like so (without stripping the source code of helpful whitespaces):

```bash
$ cat mylib.lua | redis-cli -x FUNCTION LOAD REPLACE
```

We've added the `REPLACE` modifier to the call to `FUNCTION LOAD` to tell Redis that we want to overwrite the existing library definition.
Otherwise, we would have gotten an error from Redis complaining that the library already exists.

Now that the library's updated code is loaded to Redis, we can proceed and call our function:

```
redis> FCALL my_hset 1 myhash myfield "some value" another_field "another value"
(integer) 3
redis> HGETALL myhash
1) "_last_modified_"
2) "1640772721"
3) "myfield"
4) "some value"
5) "another_field"
6) "another value"
```

In this case, we had invoked `FCALL` with _1_ as the number of key name arguments.
That means that the function's first input argument is a name of a key (and is therefore included in the callback's `keys` table).
After that first argument, all following input arguments are considered regular arguments and constitute the `args` table passed to the callback as its second argument.

## Expanding the library

We can add more functions to our library to benefit our application.
The additional metadata field we've added to the Hash shouldn't be included in responses when accessing the Hash's data.
On the other hand, we do want to provide the means to obtain the modification timestamp for a given Hash key.

We'll add two new functions to our library to accomplish these objectives:

1. The `my_hgetall` Redis Function will return all fields and their respective values from a given Hash key name, excluding the metadata (i.e., the `_last_modified_` field).
1. The `my_hlastmodified` Redis Function will return the modification timestamp for a given Hash key name.

The library's source code could look something like the following:

```lua
#!lua name=mylib

local function my_hset(keys, args)
  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

local function my_hgetall(keys, args)
  redis.setresp(3)
  local hash = keys[1]
  local res = redis.call('HGETALL', hash)
  res['map']['_last_modified_'] = nil
  return res
end

local function my_hlastmodified(keys, args)
  local hash = keys[1]
  return redis.call('HGET', hash, '_last_modified_')
end

redis.register_function('my_hset', my_hset)
redis.register_function('my_hgetall', my_hgetall)
redis.register_function('my_hlastmodified', my_hlastmodified)
```

While all of the above should be straightforward, note that the `my_hgetall` also calls [`redis.setresp(3)`](/topics/lua-api#redis.setresp).
That means that the function expects [RESP3](https://github.com/redis/redis-specifications/blob/master/protocol/RESP3.md) replies after calling `redis.call()`, which, unlike the default RESP2 protocol, provides dictionary (associative arrays) replies.
Doing so allows the function to delete (or set to `nil` as is the case with Lua tables) specific fields from the reply, and in our case, the `_last_modified_` field.

Assuming you've saved the library's implementation in the _mylib.lua_ file, you can replace it with:

```bash
$ cat mylib.lua | redis-cli -x FUNCTION LOAD REPLACE
```

Once loaded, you can call the library's functions with `FCALL`:

```
redis> FCALL my_hgetall 1 myhash
1) "myfield"
2) "some value"
3) "another_field"
4) "another value"
redis> FCALL my_hlastmodified 1 myhash
"1640772721"
```

You can also get the library's details with the `FUNCTION LIST` command:

```
redis> FUNCTION LIST
1) 1) "library_name"
   2) "mylib"
   3) "engine"
   4) "LUA"
   5) "functions"
   6) 1) 1) "name"
         2) "my_hset"
         3) "description"
         4) (nil)
      2) 1) "name"
         2) "my_hgetall"
         3) "description"
         4) (nil)
      3) 1) "name"
         2) "my_hlastmodified"
         3) "description"
         4) (nil)
```

You can see that it is easy to update our library with new capabilities.

## Reusing code in the library

On top of bundling functions together into database-managed software artifacts, libraries also facilitate code sharing.
We can add to our library an error handling helper function called from other functions.
The helper function `check_keys()` verifies that the input _keys_ table has a single key.
Upon success it returns `nil`, otherwise it returns an [error reply](/topics/lua-api#redis.error_reply).

The updated library's source code would be:

```lua
#!lua name=mylib

local function check_keys(keys)
  local error = nil
  local nkeys = table.getn(keys)
  if nkeys == 0 then
    error = 'Hash key name not provided'
  elseif nkeys > 1 then
    error = 'Only one key name is allowed'
  end

  if error ~= nil then
    redis.log(redis.LOG_WARNING, error);
    return redis.error_reply(error)
  end
  return nil
end

local function my_hset(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

local function my_hgetall(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  redis.setresp(3)
  local hash = keys[1]
  local res = redis.call('HGETALL', hash)
  res['map']['_last_modified_'] = nil
  return res
end

local function my_hlastmodified(keys, args)
  local error = check_keys(keys)
  if error ~= nil then
    return error
  end

  local hash = keys[1]
  return redis.call('HGET', keys[1], '_last_modified_')
end

redis.register_function('my_hset', my_hset)
redis.register_function('my_hgetall', my_hgetall)
redis.register_function('my_hlastmodified', my_hlastmodified)
```

After you've replaced the library in Redis with the above, you can immediately try out the new error handling mechanism:

```
127.0.0.1:6379> FCALL my_hset 0 myhash nope nope
(error) Hash key name not provided
127.0.0.1:6379> FCALL my_hgetall 2 myhash anotherone
(error) Only one key name is allowed
```

And your Redis log file should have lines in it that are similar to:

```
...
20075:M 1 Jan 2022 16:53:57.688 # Hash key name not provided
20075:M 1 Jan 2022 16:54:01.309 # Only one key name is allowed
```

## Functions in cluster

As noted above, Redis automatically handles propagation of loaded functions to replicas.
In a Redis Cluster, it is also necessary to load functions to all cluster nodes. This is not handled automatically by Redis Cluster, and needs to be handled by the cluster administrator (like module loading, configuration setting, etc.).

As one of the goals of functions is to live separately from the client application, this should not be part of the Redis client library responsibilities. Instead, `redis-cli --cluster-only-masters --cluster call host:port FUNCTION LOAD ...` can be used to execute the load command on all master nodes.

Also, note that `redis-cli --cluster add-node` automatically takes care to propagate the loaded functions from one of the existing nodes to the new node.

## Functions and ephemeral Redis instances

In some cases there may be a need to start a fresh Redis server with a set of functions pre-loaded. Common reasons for that could be:

* Starting Redis in a new environment
* Re-starting an ephemeral (cache-only) Redis, that uses functions

In such cases, we need to make sure that the pre-loaded functions are available before Redis accepts inbound user connections and commands.

To do that, it is possible to use `redis-cli --functions-rdb` to extract the functions from an existing server. This generates an RDB file that can be loaded by Redis at startup.

## Function flags

Redis needs to have some information about how a function is going to behave when executed, in order to properly enforce resource usage policies and maintain data consistency.

For example, Redis needs to know that a certain function is read-only before permitting it to execute using `FCALL_RO` on a read-only replica.

By default, Redis assumes that all functions may perform arbitrary read or write operations. Function Flags make it possible to declare more specific function behavior at the time of registration. Let's see how this works.

In our previous example, we defined two functions that only read data. We can try executing them using `FCALL_RO` against a read-only replica.

```
redis > FCALL_RO my_hgetall 1 myhash
(error) ERR Can not execute a function with write flag using fcall_ro.
```

Redis returns this error because a function can, in theory, perform both read and write operations on the database.
As a safeguard and by default, Redis assumes that the function does both, so it blocks its execution.
The server will reply with this error in the following cases:

1. Executing a function with `FCALL` against a read-only replica.
2. Using `FCALL_RO` to execute a function.
3. A disk error was detected (Redis is unable to persist so it rejects writes).

In these cases, you can add the `no-writes` flag to the function's registration, disable the safeguard and allow them to run.
To register a function with flags use the [named arguments](/topics/lua-api#redis.register_function_named_args) variant of `redis.register_function`.

The updated registration code snippet from the library looks like this:

```lua
redis.register_function('my_hset', my_hset)
redis.register_function{
  function_name='my_hgetall',
  callback=my_hgetall,
  flags={ 'no-writes' }
}
redis.register_function{
  function_name='my_hlastmodified',
  callback=my_hlastmodified,
  flags={ 'no-writes' }
}
```

Once we've replaced the library, Redis allows running both `my_hgetall` and `my_hlastmodified` with `FCALL_RO` against a read-only replica:

```
redis> FCALL_RO my_hgetall 1 myhash
1) "myfield"
2) "some value"
3) "another_field"
4) "another value"
redis> FCALL_RO my_hlastmodified 1 myhash
"1640772721"
```

For the complete documentation flags, please refer to [Script flags](/topics/lua-api#script_flags).
