Returns @array-reply of details about all Redis commands.

Cluster clients must be aware of key positions in commands so commands can go to matching instances, but Redis commands vary between accepting one key, multiple keys, or even multiple keys separated by other data.

Starting from Redis 7.0 a more flexible mechanism was introduced in order to help clients finding the key positions.
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

You can use `COMMAND` to cache a mapping between commands and key positions for
each command to enable exact routing of commands to cluster instances.

`COMMAND` has several subcommands:
 - `COMMAND INFO`
 - `COMMAND COUNT`
 - `COMMAND GETKEYS`
 - `COMMAND LIST`

`COMMAND`'s reply is an @array-reply, where each element is an @array-reply by itself, containing the following elements:
 - command name
 - command arity specification
 - nested @array-reply of command flags
 - position of first key in argument list
 - position of last key in argument list
 - step count for locating repeating keys
 - nested @array-reply of ACL categories
 - nested @array-reply of additional information as a map

The three elements responsible for determining the position of the keys are referred to as (`first-key`, `last-key`, `key-step`)

## Example
```
1) 1) "get"
   2) (integer) 2
   3) 1) readonly
      2) fast
   4) (integer) 1
   5) (integer) 1
   6) (integer) 1
   7) 1) @read
      2) @string
      3) @fast
   8)  1) "summary"
       2) "Get the value of a key"
       3) "since"
       4) "1.0.0"
       5) "group"
       6) "string"
       7) "complexity"
       8) "O(1)"
       9) "arguments"
      10) 1) 1) "name"
             2) "key"
             3) "type"
             4) "key"
             5) "key-spec-index"
             6) (integer) 0
             7) "value"
             8) "key"
      11) "key-specs"
      12) 1) 1) "flags"
             2) 1) read
             3) "begin-search"
             4) 1) "type"
                2) "index"
                3) "spec"
                4) 1) "index"
                   2) (integer) 1
             5) "find-keys"
             6) 1) "type"
                2) "range"
                3) "spec"
                4) 1) "last-key"
                   2) (integer) 0
                   3) "key-step"
                   4) (integer) 1
                   5) "limit"
                   6) (integer) 0
```

## name

Command name is the command returned as a lowercase string.

## arity

Command arity follows a simple pattern:

  - positive if command has fixed number of required arguments.
  - negative if command has minimum number of required arguments, but may have more.

Command arity _includes_ counting the command name itself.

Examples:

  - `GET` arity is 2 since the command only accepts one
argument and always has the format `GET _key_`.
  - `MGET` arity is -2 since the command accepts at a minimum
one argument, but up to an unlimited number: `MGET _key1_ [key2] [key3] ...`.

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
  - `sort_for_script`: if called from script, sort output
  - `loading`: allow command while database is loading
  - `stale`: allow command while replica has stale data
  - `skip_monitor`: do not show this command in MONITOR
  - `asking`: cluster related - accept even if importing
  - `fast`: command operates in constant or log(N) time. Used for latency monitoring.
  - `movablekeys`: The (`first-key`, `last-key`, `key-step`) scheme cannot determine all key positions. Client needs to use `COMMAND GETKEYS` or `key-specs` (starting from Redis 7.0).

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

Available starting from Redis 6.0

For more information please check the [ACL page][ta].
[ta]: /topics/acl

## Additional Information

Available starting from Redis 7.0

The element at index 7 (zero-based) of each element in `COMMAND`s reply is a a map with additional information.

For the complete structure of that map please check the [command-info page][tb].
[tb]: /topics/command-info

@return

@array-reply: nested list of command details. Commands are returned
in random order.

@examples

```cli
COMMAND
```
