# Introduction to Redis Functions
 
As of Redis 7.0, functions offer a new programmability approach.
Functions have evolved from the [Eval Scripts](/topics/eval-intro) feature that was, in turn, added in version 2.6.

You can skip the following prologue if you're new to Redis or want to jump right into the action.

## Prologue (or what's wrong with Eval Scripts?)

Prior versions of Redis made scripting available only via the `EVAL` command, which allows a Lua script to be sent for execution by the server.
One of the core use cases for [Eval Scripts](/topics/eval-intro) is implementing and exposing a richer API composed of core Redis commands and workflow logic.
Such APIs can perform conditional updates across multiple keys, possibly combining several different data types, to maintain a consistent view of entities (e.g., user profiles) somewhat like schemas in traditional databases.

Using `EVAL` requires that the application sends the entire script for execution every time.
Because this modus operandi results in network and script compilation overheads, Redis provides the `EVALSHA` command that avoids that. By first calling `SCRIPT LOAD` to obtain the script's SHA1, the application can invoke it repeatedly afterward with its digest alone.

By design, Redis only caches the loaded scripts.
That means that the script cache can become lost at any time, such as after calling `SCRIPT FLUSH` or a server restart.
The application is responsible for reloading scripts during runtime if any are missing.
The underlying assumption is that scripts are a part of the application and not maintained by the Redis server.

This approach suits many light-weight scripting use cases but introduces several difficulties once an application becomes complex and relies more heavily on scripting, namely:

1. All client application instances must maintain a copy of all scripts. That means having some mechanism that applies script updates to all of the application's instances.
1. Calling cached scripts within the context of a [transaction](/topics/transactions) increases the probability of the transaction failing because of a missing script. Being more likely to fail makes using cached scripts as building blocks of workflows less attractive.
1. SHA1 digests are meaningless, making debugging the system extremely hard (e.g., in a `MONITOR` session).
1. When used naively, `EVAL` promotes an anti-pattern in which scripts the client application renders verbatim scripts instead of responsibly using the [`!KEYS` and `ARGV` Lua APIs](/topics/lua-api#runtime-globals).
1. Because they are ephemeral, a script can't call another script. This makes sharing and reusing code between scripts nearly impossible, short of client-side preprocessing (see the first point).

To address these needs while avoiding breaking changes to already-established and well-liked ephemeral scripts, Redis v7.0 introduces Redis Functions.

## What are Redis Functions?

Redis functions are an evolutionary step from ephemeral scripting.

Functions provide the same core functionality as scripts but are first-class software artifacts citizens of the database.
Redis manages functions as an integral part of the database and ensures their availability via data persistence and replication.
Because functions are part of the database and therefore declared before use, applications aren't required to load them during runtime nor risk aborted transactions.
An application that uses functions depends only on their APIs rather than on the embedded script logic in the database.

Whereas ephemeral scripts are considered a part of the application's domain, functions extend the database server itself with user-provided logic.
Every function has a unique user-provided name, making it much easier to call and trace its execution.

The design of Redis Functions also attempts to demarcate between the programming language used for writing functions and their management by the server.
Lua, the only language interpreter that Redis presently support as an embedded execution engine, is meant to be simple and easy to learn.
However, the choice of Lua as a language still presents many Redis users with an obstacle. 

The Redis Functions feature makes no assumptions regarding the implementation's language.
An execution engine that is part of the definition of the function handles running it.
An engine can theoretically execute functions in any language as long as it respects several rules (such as the ability to terminate an inflight function's execution).

Presently, as noted above, Redis ships with a single embedded [Lua 5.1](/topics/lua-api) engine.
There are plans to support additional engines in the future.
Redis functions can use all of Lua's available capabilities to ephemeral scripts,
with the only exception being the [Redis Lua scripts debugger](/topics/ldb).

Functions also simplify development by enabling code sharing.
Every function belongs to a single library, and any given library can consist of multiple functions.
The library's contents are immutable, and selective updates of its functions aren't allowed.
Instead, libraries are updated as a whole with all of their functions together in one operation.
This allows calling functions from other functions within the same library.

Functions are intended to support better the use case of maintaining a consistent view for data entities through a logical schema, as mentioned above.
As such, functions are stored alongside the data itself.
Functions are also persisted to the AOF file and synchronized from master to replicas.
Because of that, data loss also implies losing functions stored in the database, so using functions without data persistence or high availability requires special handling that will be presented later on.

Like all other operations in Redis, the execution of a function is atomic.
A function's execution blocks all server activities during its entire time, similarly to the semantics of [transactions](/topics/transactions).
These semantics mean that all of the script's effects either have yet to happen or had already happened.
The blocking semantics of an executed function apply to all connected clients at all times.
Because running a function block the Redis server, functions are meant to finish executing quickly, so you should avoid using long-running functions.

## Loading libraries and functions

Let's explore Redis Functions via tangible examples and Lua snippets.
At this point, if you're unfamiliar with Lua in general and specifically in Redis, you may benefit from reviewing some of the examples in [Introduction to Eval Scripts](/topics/eval-intro) and [Lua API](/topics/lua-api) pages for a better grasp of the language.

Every Redis function belongs to a single library that's loaded to Redis.
Loading a library to the database is done with the `FUNCTION LOAD` command.
Let's try loading an empty library:

```
redis> FUNCTION LOAD Lua mylib ""
(error) ERR No functions registered
```

The error is by design, and it complains that there are no functions in the library.
Despite the error, we can see that the basic form of invoking `FUNCTION LOAD` requires three arguments: the engine's identifier (_Lua_), the library's name (_mylib_), and the library's source code.

Every library needs to include at least one registered function to load successfully.
A registered function is named and acts as an entry point to the library.
When the target execution engine handles the `FUNCTION LOAD` command, it registers the library's functions.
The Lua engine registers the functions in a library by running its source code upon loading it.
You need instruct the Lua engine explicity about registered functions to the `redis.register_function()` API.

The following snippet demonstrates a simple library.
It registers a single Redis function named _knockknock_ that returns a string reply:

```lua
redis.register_function(
  'knockknock',
  function() return 'Who\'s there?' end
)
```

In the example above, we provide two arguments about the function to Lua's `redis.register_function()` API: its registered name and callback.

We can load our now library and use `FCALL` to call the function.
Because _redis-cli_ doesn't play nicely with newlines, we'll just strip these from the code:

```
redis> FUNCTION LOAD Lua mylib "redis.register_function('knockknock', function() return 'Who\\'s there?' end)"
OK
redis> FCALL knockknock 0
"Who's there?"
```

Note that we've provided `FCALL`  with two arguments: the function's registered name and the numerical value of 0.
While the first argument's purpose is obvious, the cryptic numerical value tells Redis the number of key names that follow it.
We'll explain immediately how key names and additional arguments are made accessible to the function. Still, this synthetic example doesn't touch any keys, so simply use 0 to run it.

## Input keys and regular arguments

Before we move to the following example, it is vital to understand the distinction Redis makes between arguments that are names of keys and those that aren't.

While key names in Redis are just strings, unlike any other string values, these represent keys in the database.
The name of a key is a fundamental concept in Redis and is the basis for operating the Redis Cluster.

**Important:**
to ensure the correct execution of Redis Functions, both in standalone and clustered deployments, all names of keys that a function accesses must be explicitly provided as input key arguments.

Any input to the function that isn't the name of a key is a regular input argument.

Now, let's pretend that our application stores some of its data in Redis Hashes.
We want an `HSET`-like way to set and update fields in said Hashes and store the last modification time in a new field named _\_last_update\__.
We can implement a function to do all that.

Our function will call `TIME` to get the server's clock reading and update the target Hash with the new fields' values and the modification's timestamp.
The function we'll implement accepts the following input arguments: the Hash's key name and the field-value pairs to update.

The Lua API for Redis Functions makes these inputs accessible as the first and second arguments to the function's callback.
The callback's first argument is a Lua table populated with all key names inputs to the function.
Similarly, the callback's second argument consists of all regular arguments.

The following is a possible implementation for our function and its library registration:

```lua
local function my_hset(keys, args)
  local hash = keys[1]
  local time = redis.call('TIME')[1]
  return redis.call('HSET', hash, '_last_modified_', time, unpack(args))
end

redis.register_function('my_hset', my_hset)
```

If we create a new file named _mylib.lua_ that consists of the library's definition, we can load it like so (without stripping the source code of helpful whitespaces):

```bash
$ cat mylib.lua | redis-cli -x FUNCTION LOAD Lua mylib REPLACE
```

We've added the `REPLACE` modifier to the call to `FUNCTION LOAD` to tell Redis that we want to overwrite the existing library definition.
Otherwise, we would have gotten an error from Redis complaining that the library already exists).

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

1. The `my_hgetall` Redis Function will return all fields and their respective values from a given Hash key name, excluding the metadata (i.e., the _\_last_updated\__ field).
1. The `my_hlastmodified` Redis Function will return the modification timestamp for a given Hash key name.

The library's source code could look something like the following:

```lua
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
  return redis.call('HGET', keys[1], '_last_modified_')
end

redis.register_function('my_hset', my_hset)
redis.register_function('my_hgetall', my_hgetall)
redis.register_function('my_hlastmodified', my_hlastmodified)
```

While all of the above should straightforward, note that the `my_hgetall` also calls [`redis.setresp(3)`](/topics/lua-api#redis.setresp).
That means that the function expects [RESP3](https://github.com/redis/redis-specifications/blob/master/protocol/RESP3) replies after calling `redis.call()`, which, unlike the default RESP2 protocol, provides dictionary (associative arrays) replies.
Doing so allows the function to delete (or set to `nil` as is the case with Lua tables) specific fields from the reply, and in our case, the _\_last_modified\__ field.

Assuming you've saved the library's implementation in the _mylib.lua_ file, you can replace it with its (optional) description with:

```bash
$ cat mylib.lua | redis-cli -x FUNCTION LOAD Lua mylib REPLACE DESCRIPTION "My application's Hash data type enhancements"
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
   5) "description"
   6) "My application's Hash data type enhancements"
   7) "functions"
   8) 1) 1) "name"
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

