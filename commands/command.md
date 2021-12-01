Returns @array-reply of details about all Redis commands.

Cluster clients must be aware of key positions in commands so commands can go to matching instances, but Redis commands vary between accepting one key, multiple keys, or even multiple keys separated by other data.

Starting from Redis 7.0 a more flexible mechanism was introduced in order to help clients finding the key positions.
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

You can use `COMMAND` to cache a mapping between commands and key positions for
each command to enable exact routing of commands to cluster instances.

`COMMAND`'s reply is an @array-reply, where each element is an @array-reply by itself, containing the following elements:

 - command name
 - command arity specification
 - nested @array-reply of command flags
 - position of first key in argument list
 - position of last key in argument list
 - step count for locating repeating keys
 - nested @array-reply of ACL categories
 - nested @map-reply of additional information

## Example
```
1) 1) "mget"
   2) (integer) -2
   3) 1) readonly
      2) fast
   4) (integer) 1
   5) (integer) -1
   6) (integer) 1
   7) 1) @read
      2) @string
      3) @fast
   8)  1) "summary"
       2) "Get the values of all the given keys"
       3) "since"
       4) "1.0.0"
       5) "group"
       6) "string"
       7) "complexity"
       8) "O(N) where N is the number of keys to retrieve."
       9) "arguments"
      10) 1) 1) "name"
             2) "key"
             3) "type"
             4) "key"
             5) "flags"
             6) 1) multiple
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
                4) 1) "lastkey"
                   2) (integer) -1
                   3) "keystep"
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
  - `movablekeys`: keys have no pre-determined position. You must discover keys yourself or use `key-specs` (starting from Redis 7.0).

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

Some Redis commands have no predetermined key locations. For those commands,
flag `movablekeys` is added to the command flags @array-reply. Your Redis
Cluster client needs to parse commands marked `movablekeys` to locate all relevant key positions.

Partial list of commands currently requiring key location parsing:

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
[tr]: /topics/key-specs

## firstkey

For most commands the first key is position 1.  Position 0 is
always the command name itself.


## lastkey

Redis commands usually accept one key, two keys, or an unlimited number of keys.

If a command accepts one key, the first key and last key positions is 1.

If a command accepts two keys (e.g. `BRPOPLPUSH`, `SMOVE`, `RENAME`, ...) then the
last key position is the location of the last key in the argument list.

If a command accepts an unlimited number of keys, the last key position is -1.

## step

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

## acl categories

Available starting from Redis 6.0

For more information please check the [acl page][tr].
[tr]: /topics/acl

## additional information

Available starting from Redis 7.0

The last element of each element in `COMMAND`s reply is a a map with the following fields:

 - `summary`
 - `since`
 - `group`
 - `complexity`
 - `doc-flags`
 - `deprecated-since`
 - `replaced-by`
 - `history`
 - `hints`
 - `arguments`
 - `key-specs`
 - `subcommands`

Only `summary`, `since`, and `group` are mandatory, the rest may be absent.

### summary

Short command description

### since

Debut Redis version of the command

### group

Group of the command. Possible values:
 - generic
 - string
 - list
 - set
 - sorted-set
 - hash
 - pubsub
 - transactions
 - connection
 - server
 - scripting
 - hyperloglog
 - cluster
 - sentinel
 - geo
 - stream
 - bitmap
 - module

### complexity

A short explantion about the command's time complexity

### doc-flags

An @array-reply of flgas that are relevant for documentation purposes. Possible values:
 - deprecated: The command is deprecated
 - syscmd: System command, not meant to be executed by normal users

### deprecated-since

If deprecated, from which version?

### replaced-by

If deprecated, which command replaced it?

### history

An @array-reply, where each element is also an @array-reply with two elements:
1. The version when something changed about the command interface
2. A short description of the changes

### hints

An @array-reply of hints that are meant to help clients/proxies know how to behave with this command

### arguments

An @array-reply, where each element is a @map-reply describing a command argument.
For more information please check the [command-arguments page][tr].
[tr]: /topics/command-arguments

### key-specs

An @array-reply, where each element is a @map-reply describing a method to locate keys within the arguments.
For more information please check the [key-specs page][tr].
[tr]: /topics/key-specs

### subcommands

Some commands have subcommands (Example: `REWRITE` is a subcommand of `CONFIG`).
This is an @array-reply, with the same format and specification of `COMMAND`'s reply.

@return

@array-reply: nested list of command details. Commands are returned
in random order.

@examples

```cli
COMMAND
```
