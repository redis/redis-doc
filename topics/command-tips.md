# Command tips

An @array-reply of strings, command tips are meant to provide additional information about commands for clients and proxies.
This infromation should help clients to determine how to handle this command when Redis is in clustering mode.
Unlike the command flags (the third element in `COMMAND`'s reply), which are internal in nature (Redis itself uses them internally), command tips are just exposed via `COMMAND` and Redis does not use them.

The tips are arbitrary strings, but in order to create common conventions, here is a list of suggested tips:

- **nondeterministic-output**
- **nondeterministic-output-order**
- **request_policy:<policy>**
- **response_policy:<policy>**

### nondeterministic-output

The output is not deterministic, that is, the same command with the same arguments, with the same key-space, may have different results.
The different results may be caused by the random nature of the command  (e.g. `RANDOMKEY`, `SPOP`), timing of the command (e.g. `TTL`) or general non-keyspace differences in the server state (e.g. `INFO`, `CLIENT LIST`).

Before Redis 7.0 this tip was the command flag `random`.

### nondeterministic-output-order

The output is deterministic, but comes in nondeterministic order (e.g. `HGETALL`, `SMEMBERS`)

Before Redis 7.0 this tip was the command flag `sort_for_script`.

### request_policy

This tip should help clients to determine to which shard(s) to send the command in clustering mode.
The default behavior (i.e. if the `request_policy` tip is absent) devides into two cases:
1. The command has key(s). In this case the command goes to a single shard, determined by the hslot(s) of the key(s)
2. The command doesn't have key(s). In this case the command can be sent to any arbitrary shard.

If the client needs to behave differently we must specify an option for `request_policy`:
- **all_shards** - Forward to all master shards (e.g. `DBSIZE`). Usually used on key-less command. The operation is atomic on all shards.
- **all_nodes** - Forward to all nodes, masters and replicas, (e.g. `CONFIG SET`). Usually used on key-less command. The operation is atomic on all shards.
- **multi_shard** - Forward to several shards, used by multi-key commands where each key is handled separately (`MSET`, `MGET`, `DEL`, etc.). i.e. unlike `SUNIONSTORE` which must be sent to one shard.
- **special** - Indicates a non-trivial form of request policy. Example: `SCAN`

### response_policy

This tip should help clients to know how to aggregate the replies of a command that was sent to multiple shards in clustering mode.
The default behavior (i.e. if the `request_policy` tip is absent) applies only when the reply is some sort of collection (array, set, map) and it devides into two cases:
1. The command doesn't have key(s). In this case we append the array replies in random order (e.g. `KEYS`)
2. The command has key(s).  In this case we append the array replies in the original order of the request's keys (e.g. `MGET`, but not `MSET` and `DEL` which don't return an array)

If the reply is not a collection, or if the client need to behave differently we must specify an option for `response_policy`:
- **one_succeeded** - Return success if at least one shard didn't reply with an error. The client should reply with the first reply it gets which isn't an error, or with any of the errors, if they all responded with errors. Example: `SCRIPT KILL` (usually the script is loaded to all shards, but runs only on one. `SCRIPT KILL` is sent to all shards)
- **all_succeeded** - Return success if none of the shards replied with an error. if one replied with an error, return that error (either one of the errors), if they all succeeded, return the successful reply (either one). Examples: `CONFIG SET`, `SCRIPT FLUSH`, `SCRIPT LOAD`
- **agg_logical_and** - Preform a logical AND on the replies (replies must be numerical, usually just 0/1). Example: `SCRIPT EXISTS`, which returns an array of 0/1 indicating which of the provided scripts exist. The aggregated response will be 1 iff all shards have the script.
- **agg_logical_or** - Preform a logical OR on the replies (replies must be numerical, usually just 0/1).
- **agg_min** - Perform a minimum on replies (replies must be numerical). Example: `WAIT` (returns the lowest number among the ones the shards' replies).
- **agg_max** - Perform a maximum on replies (replies must be numerical).
- **agg_sum** - Sums the integer values returned by the shards. Example: `DBSIZE`
- **spceial** - Indicates a non-trivial form of reply policy. Example: `INFO`


## Example

```
127.0.0.1:6379> command info ping
1)  1) "ping"
    2) (integer) -1
    3) 1) fast
    4) (integer) 0
    5) (integer) 0
    6) (integer) 0
    7) 1) @fast
       2) @connection
    8) 1) "request_policy:all_shards"
       2) "response_policy:all_succeeded"
    9) (empty array)
   10) (empty array)

```
