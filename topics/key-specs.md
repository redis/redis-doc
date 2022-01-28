# Command key specifications

Many of the commands in Redis accept key names as input arguments.
The 8th element in the reply of `COMMAND` (and `COMMAND INFO`) is an array that consists of the command's key specifications.

A _key specification_ describes a rule for extracting the names of one or more keys from the arguments of a given command.
Key specifications provide a robust and flexible mechanism, compared to the _first key_, _last key_ and _step_ scheme employed until Redis 7.0.
Before introducing these specifications, Redis clients had no trivial programmatic means to extract key names for all commands.

Cluster-aware Redis clients had to have the keys' extraction logic hard-coded in the cases of commands such as `EVAL` and `ZUNIONSTORE` that rely on a _numkeys_ argument or `SORT` and its many clauses.
Alternatively, the `COMMAND GETKEYS` can be used to achieve a similar extraction effect but at a higher latency.

A Redis client isn't obligated to support key specifications.
It can continue using the legacy _first key_, _last key_ and _step_ scheme along with the [_movablekeys_ flag](/commands/command#flags) that remain unchanged.

However, a Redis client that implements key specifications support can consolidate most of its keys' extraction logic.
Even if the client encounters an unfamiliar type of key specification, it can always revert to the `COMMAND GETKEYS` command.

That said, most cluster-aware clients only require a single key name to perform correct command routing, so it is possible that although a command features one unfamiliar specification, its other specification may still be usable by the client.

Key specifications are maps with three keys:

1. **begin_search:**: the starting index for keys' extraction.
2. **find_keys:** the rule for identifying the keys relative to the BS.
3. **notes**: notes about this key spec, if there are any.
4. **flags**: indicate the type of data access.

## begin_search

The _begin\_search_ value of a specification informs the client of the extraction's beginning.
The value is a map.
There are three types of `begin_search`:

1. **index:** key name arguments begin at a constant index.
2. **keyword:** key names start after a specific keyword (token).
3. **unknown:** an unknown type of specification - see the [incomplete flag section](#incomplete-flag) for more details.

### index

The _index_ type of `begin_search` indicates that input keys appear at a constant index.
It is a map under the _spec_ key with a single key:

1. **index:** the 0-based index from which the client should start extracting key names.

### keyword

The _keyword_ type of `begin_search` means a literal token precedes key name arguments.
It is a map under the _spec_ with two keys:

1. **keyword:** the keyword (token) that marks the beginning of key name arguments.
2. **startfrom:** an index to the arguments array from which the client should begin searching. 
  This can be a negative value, which means the search should start from the end of the arguments' array, in reverse order.
  For example, _-2_'s meaning is to search reverse from the penultimate argument.

More examples of the _keyword_ search type include:

* `SET` has a `begin_search` specification of type _index_ with a value of _1_.
* `XREAD` has a `begin_search` specification of type _keyword_ with the values _"STREAMS"_ and _1_ as _keyword_ and _startfrom_, respectively.
* `MIGRATE` has a _start_search_ specification of type _keyword_ with the values of _"KEYS"_ and _-2_.

## find_keys

The `find_keys` value of a key specification tells the client how to continue the search for key names.
`find_keys` has three possible types:

1. **range:** keys stop at a specific index or relative to the last argument.
2. **keynum:** an additional argument specifies the number of input keys.
3. **unknown:** an unknown type of specification - see the [incomplete flag section](#incomplete-flag) for more details.

### range

The _range_ type of `find_keys` is a map under the _spec_ key with three keys:

1. **lastkey:** the index, relative to `begin_search`, of the last key argument.
  This can be a negative value, in which case it isn't relative.
  For example, _-1_ indicates to keep extracting keys until the last argument, _-2_ until one before the last, and so on.
2. **keystep:** the number of arguments that should be skipped, after finding a key, to find the next one.
3. **limit:** if _lastkey_ is has the value of _-1_, we use the _limit_ to stop the search by a factor.
  _0_ and _1_ mean no limit.
  _2_ means half of the remaining arguments, 3 means a third, and so on.

### keynum

The _keynum_ type of `find_keys` is a map under the _spec_ key with three keys:

* **keynumidx:** the index, relative to `begin_search`, of the argument containing the number of keys.
* **firstkey:** the index, relative to `begin_search`, of the first key.
  This is usually the next argument after _keynumidx_, and its value, in this case, is greater by one.
* **keystep:** Tthe number of arguments that should be skipped, after finding a key, to find the next one.

Examples:

* The `SET` command has a _range_ of _0_, _1_ and _0_.
* The `MSET` command has a _range_ of _-1_, _2_ and _0_.
* The `XREAD` command has a _range_ of _-1_, _1_ and _2_.
* The `ZUNION` command has a _start_search_ type _index_ with the value _1_, and `find_keys` of type _keynum_ with values of _0_, _1_ and _1_.
* The [`AI.DAGRUN`](https://oss.redislabs.com/redisai/master/commands/#aidagrun) command has a _start_search_ of type _keyword_ with values of _"LOAD"_ and _1_, and `find_keys` of type _keynum_ with values of _0_, _1_ and _1_.

**Note:**
this isn't a perfect solution as the module writers can come up with anything.
However, this mechanism should allow the extraction of key name arguments for the vast majority of commands.

## notes

Some key specs have some non-obvious considerations, in which case they'l contain a short text describing them.

## flags

A key specification can have additional flags that provide more details about the key.
These flags are divided into three groups, as described below.

### Access type flags

The following flags declare the type of access the command uses to a key's value or its metadata.
A key's metadata includes LRU/LFU counters, type, and cardinality.
These flags do not relate to the reply sent back to the client.

Every key specification has precisely one of the following flags:

* **RW:** the read-write flag.
  The command modifies the data stored in the value of the key or its metadata.
  This flag marks every operation that isn't distinctly a delete, an overwrite, or read-only.
* **RO:** the read-only flag.
  The command only reads the value of the key (although it doesn't necessarily return it).
* **OW:** the overwrite flag.
  The command overwrites the data stored in the value of the key.
* **RM:** the remove flag.
  The command deletes the key.
 
### Logical operation flags

The following flags declare the type of operations performed on the data stored as the key's value and its TTL (if any), not the metadata.
These flags describe the logical operation that the command executes on data, driven by the input arguments.
The flags do not relate to modifying or returning metadata (such as a key's type, cardinality, or existence).

Every key specification may include the following flag:

* **access:** the access flag.
  This flag indicates that the command returns, copies, or somehow uses the user's data that's stored in the key.

In addition, the specification may include precisely one of the following:

* **update:** the update flag.
  The command updates the data stored in the key's value.
  The new value may depend on the old value.
  This flag marks every operation that isn't distinctly an insert or a delete.
* **insert:** the insert flag.
  The command only adds data to the value; existing data isn't modified or deleted.
* **delete:** the delete flag.
  The command explicitly deletes data from the value stored at the key.

### Miscellaneous flags

Key specifications may have the following flags:

* **channel:** this flag indicates that the specification isn't about keys at all.
  Instead, the specification relates to the name of a sharded Pub/Sub channel.
  Please refer to the `SPUBLISH` command for further details about sharded Pub/Sub.
* **incomplete:** this flag is explained in the following section.

### incomplete

Some commands feature exotic approaches when it comes to specifying their keys, which makes extraction difficult.
Consider, for example, what would happen with a call to `MIGRATE` that includes the literal string _"KEYS"_ as an argument to its _AUTH_ clause.
Our key specifications would miss the mark, and extraction would begin at the wrong index.

Thus, we recognize that key specifications are incomplete and may fail to extract all keys.
However, we assure that even incomplete specifications never yield the wrong names of keys, providing that the command is syntactically correct.

In the case of `MIGRATE`, the search begins at the end (_startfrom_ has the value of _-1_).
If and when we encounter a key named _"KEYS"_, we'll only extract the subset of the key name arguments after it.
That's why `MIGRATE` has the _incomplete_ flag in its key specification.

Another case of incompleteness is the `SORT` command.
Here, the `begin_search` and `find_keys` are of type _unknown_.
The client should revert to calling the `COMMAND GETKEYS` command to extract key names from the arguments, short of implementing it natively.
The difficulty arises, for example, because the string _"STORE"_ is both a keyword (token) and a valid literal argument for `SORT`.

**Note:**
the only commands with _incomplete_ key specifications are `SORT` and `MIGRATE`.
We don't expect the addition of such commands in the future.

## Examples

### `SET`'s key specifications

```
  1) 1) "flags"
     2) 1) RW
        2) access
        3) update
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
           2) (integer) 0
           3) "keystep"
           4) (integer) 1
           5) "limit"
           6) (integer) 0
```

### `ZUNION`'s key specifications

```
  1) 1) "flags"
     2) 1) RO
        2) access
     3) "begin-search"
     4) 1) "type"
        2) "index"
        3) "spec"
        4) 1) "index"
           2) (integer) 1
     5) "find-keys"
     6) 1) "type"
        2) "keynum"
        3) "spec"
        4) 1) "keynumidx"
           2) (integer) 0
           3) "firstkey"
           4) (integer) 1
           5) "keystep"
           6) (integer) 1
```
