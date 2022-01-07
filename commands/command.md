Returns @array-reply of details about all Redis commands.

Cluster clients must be aware of key positions in commands so commands can go to matching instances, but Redis commands vary between accepting one key, multiple keys, or even multiple keys separated by other data.

Starting from Redis 7.0.0 a more flexible mechanism was introduced in order to help clients finding the key positions.
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

You can use `COMMAND` to cache a mapping between commands and key positions for
each command to enable exact routing of commands to cluster instances.

`COMMAND` has several subcommands:

 - `COMMAND INFO`
 - `COMMAND COUNT`
 - `COMMAND GETKEYS`
 - `COMMAND LIST`
 - `COMMAND DETAILS`

`COMMAND`'s reply is an @array-reply, where each element is an @array-reply by itself, containing the following elements:

 - command name
 - command arity specification
 - nested @array-reply of command flags
 - position of first key in argument list
 - position of last key in argument list
 - step count for locating repeating keys
 - nested @array-reply of [ACL categories][ta]
 - nested @array-reply of [command hints][tb]
 - nested @array-reply of [key-specs][td]
 - nested @array-reply of subcommands
[ta]: /topics/acl
[tb]: /topics/command-hints
[td]: /topics/key-specs

The three elements responsible for determining the position of the keys are referred to as (`first-key`, `last-key`, `key-step`)

## Example
```
1)  1) "get"
    2) (integer) 2
    3) 1) readonly
       2) fast
    4) (integer) 1
    5) (integer) 1
    6) (integer) 1
    7) 1) @read
       2) @string
       3) @fast
    8) (empty array)
    9) 1) 1) "flags"
          2) 1) read
          3) "begin_search"
          4) 1) "type"
             2) "index"
             3) "spec"
             4) 1) "index"
                2) (integer) 1
          5) "find_keys"
          6) 1) "type"
             2) "range"
             3) "spec"
             4) 1) "lastkey"
                2) (integer) 0
                3) "keystep"
                4) (integer) 1
                5) "limit"
                6) (integer) 0
   10) (empty array)
```

## name

Command name is the command returned as a lowercase string.

## arity

Command arity follows a simple pattern:

  - positive if command has fixed number of required arguments.
  - negative if command has minimum number of required arguments, but may have more.

Command arity _includes_ counting the command name itself.

Examples:

  - `GET` arity is 2 since the command only accepts one argument and always has the format `GET _key_`.
  - `MGET` arity is -2 since the command accepts at a minimum one argument, but up to an unlimited number: `MGET _key1_ [key2] [key3] ...`.

Also note with `MGET`, the -1 value for "last key position" means the list
of keys may have unlimited length.

## flags

Command flags is @array-reply containing one or more status replies:
  - `write`: command may result in modifications
  - `readonly`: command will never modify keys
  - `denyoom`: reject command if currently out of memory
  - `admin`: server admin command
  - `pubsub`: pubsub-related command
  - `noscript`: deny this command from scripts
  - `random`: command has random results, dangerous for scripts
  - `sort_for_script`: if called from script, sort output (Deprecated since 7.0.0)
  - `loading`: allow command while database is loading
  - `stale`: allow command while replica has stale data
  - `skip_monitor`: do not show this command in `MONITOR`
  - `skip_monitor`: do not show this command in `SLOWLOG`
  - `asking`: cluster related - accept even if importing
  - `fast`: command operates in constant or log(N) time. Used for latency monitoring.
  - `no_auth`: command does not require authentication
  - `may_replicate`: command may replicate to replicas/AOF
  - `no_mandatory_keys`: command may take key arguments, but none of them is mandatory
  - `no_multi`: command is not allowed inside `MULTI`/`EXEC`
  - `movablekeys`: The (`first-key`, `last-key`, `key-step`) scheme cannot determine all key positions. Client needs to use `COMMAND GETKEYS` or [key-specs][td] (starting from Redis 7.0.0).

### movablekeys

```
1) 1) "sort"
   2) (integer) -2
   3) 1) write
      2) denyoom
      3) movablekeys
   4) (integer) 1
   5) (integer) 1
   6) (integer) 1
   ...
```

Some Redis commands have no predetermined key locations.
For those commands, the `movablekeys` flag is added to the command flags @array-reply,
which denotes that the (`first-key`, `last-key`, `key-step`) fields are insufficient to find all the keys,
and Cluster clients needs to user other measures which are described below to locate them.

Here are a few examples of commands that are marked with `movablekeys`:
  - `SORT` - optional `STORE` key, optional `BY` weights, optional `GET` keys
  - `ZUNION` -  keys stop after `numkeys` count arguments
  - `ZUNIONSTORE` -  keys stop after `numkeys` count arguments
  - `ZINTER` - keys stop after `numkeys` count arguments
  - `ZINTERSTORE` -  keys stop after `numkeys` count arguments
  - `MIGRATE` - keys start after the `KEYS` keyword (if the second argument is en empty string)
  - `EVAL` - keys stop after `numkeys` count arguments
  - `EVALSHA` - keys stop after `numkeys` count arguments

Also see `COMMAND GETKEYS` for getting your Redis server tell you where keys
are in any given command.

Starting from redis 7.0 clients can use the `key-specs` section in the additional information section in order to deduce key positions.
The only two commands which still require using `COMMAND GETKEYS` are `SORT` and `MIGRATE` (assuming the client can parse and uses the `key-specs` section).

For more information please check the [key-specs page][tr].

## first-key

For most commands the first key is position 1.  Position 0 is
always the command name itself.

## last-key

Redis commands usually accept one key, two keys, or an unlimited number of keys.

If a command accepts one key, the first key and last key positions is 1.

If a command accepts two keys (e.g. `BRPOPLPUSH`, `SMOVE`, `RENAME`, ...) then the
last key position is the location of the last key in the argument list.

If a command accepts an unlimited number of keys, the last key position is -1.

## key-step

<table style="width:50%">
<tr><td>
<pre>
<code>1) 1) "mset"
   2) (integer) -3
   3) 1) write
      2) denyoom
   4) (integer) 1
   5) (integer) -1
   6) (integer) 2
   ...
</code>
</pre>
</td>
<td>
<pre>
<code>1) 1) "mget"
   2) (integer) -2
   3) 1) readonly
      2) fast
   4) (integer) 1
   5) (integer) -1
   6) (integer) 1
   ...
</code>
</pre>
</td></tr>
</table>

Key step count allows us to find key positions in commands
like `MSET` where the format is `MSET _key1_ _val1_ [key2] [val2] [key3] [val3]...`.

In the case of `MSET`, keys are every other position so the step value is 2.  Compare
with `MGET` above where the step value is just 1.

## ACL Categories

Available starting from Redis 6.0.0

For more information please check the [ACL page][ta].

## Command hints

Available starting from Redis 7.0.0

Helpful information about the command, to be used by clients/proxies.

For more information please check the [command hints page][tb].

## Key specs

Available starting from Redis 7.0.0

An @array-reply, where each element is a @map-reply describing a method to locate keys within the arguments.

For more information please check the [key-specs page][td].

## Subcommands

Some commands have subcommands (Example: `REWRITE` is a subcommand of `CONFIG`).
This is an @array-reply, with the same format and specification of `COMMAND`'s reply.

@return

@array-reply: nested list of command details. Commands are returned
in random order.

@examples

```cli
COMMAND
```
