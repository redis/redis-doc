# Key specifications

A key spec a a map, coanting information about the indices of keys within the argument array.
It is a more flexible and powerful tool to descibe key postions than the old (first-key, last-key, key-step) schme.
Before key-specs, there was no way for a client library or application to know the key  indices for commands such as ZUNIONSTORE/EVAL and others with "numkeys", since COMMAND INFO returns no useful info for them.
For cluster-aware redis clients, this requires to 'patch' the client library code specifically for each of these commands or to resolve each execution of these commands with COMMAND GETKEYS.

The field "key-specs", found inside the 8th element of the command info array, if exists, holds an array of key specs. The array may be empty, which indicates the command doesn't take any key arguments. Otherwise, it contains one or more key-specs, each one may leads to the discovery of 0 or more key arguments.

A client library that doesn't support this feature will keep using the (first-key, last-key, key-step) and `movablekeys` flag which remain unchanged.

A client library that supports this feature needs only to look at the key-specs array. If it finds an unrecognized spec, it must resort to using COMMAND GETKEYS if it wishes to get all key name arguments, but if all it needs is one key in order to know which cluster node to use, then maybe another spec (if the command has several) can supply that, and there's no need to use GETKEYS.

There are two steps to retrieve the key arguments:
 - `begin_search` (BS): in which index should we start seacrhing for keys?
 - `find_keys` (FK): relative to the output of BS, how can we will which args are keys?

In addition to the two steps, each key-spec has a list of flags.

## begin_search (BS)

There are two types of BS:

 - `index`: key args start at a constant index
 - `keyword`: key args start just after a specific keyword

Each has one or more nested fields

### index

`index` has only one nested field, called `index` as well.
 - `index`: The index from which we start the search for keys.

### keyword

`keyword` has two nested fields.
 - `keyword`: The keyword that indicates the beginning of key args.
 - `startfrom`: An index in argv from which to start searching. 
                Can be negative, which means start search from the end, in reverse
                (Example: -2 means to start in reverse from the panultimate arg)

Examples:
- `SET` has start_search of type `index` with value `1`
- `XREAD` has start_search of type `keyword` with value `[“STREAMS”,1]`
- `MIGRATE` has start_search of type `keyword` with value `[“KEYS”,-2]`

## find_keys (FK)

There are two kinds of FK:

 - `range`: keys end at a specific index (or relative to the last argument)
 - `keynum`: there's an arg that contains the number of key args somewhere before the keys themselves

### range

`range` has three nested fields:
 - `lastkey`: Relative index (to the result of the `begin_search` step) where the last key is.
              Can be negative, in which case it's not relative. -1 indicating till the last argument,
              -2 one before the last and so on.
 - `keystep`: Amount of arguments should we skip after finding a key, in order to find the next one.
 - `limit`: If lastkey is -1, we use limit to stop the search by a factor. 0 and 1 mean no limit.
            2 means 1/2 of the remaining args, 3 means 1/3, and so on.

### keynum

`keynum` has three nested fields:

 - `keynumidx`: Relative index (to the result of the begin_search step) where the arguments that
                contains the number of keys is.
 - `firstkey`: Relative index (to the result of the begin_search step) where the first key is
               found (Usually it's just after keynumidx, so it should be keynumidx+1)
 - `keystep`: How many args should we skip after finding a key, in order to find the next one.

Examples:
- `SET` has `range` of `[0,1,0]`
- `MSET` has `range` of `[-1,2,0]`
- `XREAD` has `range` of `[-1,1,2]`
- `ZUNION` has `start_search` of type `index` with value `1` and `find_keys` of type `keynum` with value `[0,1,1]`
- `AI.DAGRUN` has `start_search` of type `keyword` with value `[“LOAD“,1]` and `find_keys` of type `keynum` with value `[0,1,1]` (see https://oss.redislabs.com/redisai/master/commands/#aidagrun)

Note: this solution is not perfect as the module writers can come up with anything, but at least we will be able to find the key args of the vast majority of commands.
If one of the above specs can’t describe the key positions, the module writer can always fall back to the `getkeys-api` option.

## flags

Additional information regarding the keys found using a key-spec.

 - `write`: Keys may be modified.
 - `read`: Key will not be modified.
 - `incomplete`: Explained below.

### The `incomplete` flag

Some keys cannot be found easily (`KEYS` in `MIGRATE`: Imagine the argument for `AUTH` is the string "KEYS" - we will start searching in the wrong index). 
Key-specs may be incomplete (`incomplete` flag) but we never report false information (assuming the command syntax is correct). 
For `MIGRATE` we start searching from the end - `startfrom=-1` - and if one of the keys is actually called "keys" we will report only a subset of all keys - hence the `incomplete` flag.
Some `incomplete` specs can be completely empty (i.e. UNKNOWN `begin_search`) which should tell the client that `COMMAND GETKEYS` (or any other way to get the keys) must be used (Example: For `SORT` there is no way to describe the `STORE` keyword spec, because the word "STORE" can appear anywhere in the command).

The only commands with `incomplete` specs are `SORT` and `MIGRATE`

## Examples

### SET

```
  1) 1) "flags"
     2) 1) write
        2) read
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

### ZUNION

```
  1) 1) "flags"
     2) 1) read
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

### GEORADIUS

```
  1) 1) "flags"
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
           2) (integer) 0
           3) "keystep"
           4) (integer) 1
           5) "limit"
           6) (integer) 0
  2) 1) "flags"
     2) 1) write
     3) "begin-search"
     4) 1) "type"
        2) "keyword"
        3) "spec"
        4) 1) "keyword"
           2) "STORE"
           3) "startfrom"
           4) (integer) 6
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
  3) 1) "flags"
     2) 1) write
     3) "begin-search"
     4) 1) "type"
        2) "keyword"
        3) "spec"
        4) 1) "keyword"
           2) "STOREDIST"
           3) "startfrom"
           4) (integer) 6
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

