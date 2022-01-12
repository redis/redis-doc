# Command tips

An @array-reply of strings, command tips are meant to provide additional information about commands for clients and proxies.
This infromation should help clients and proxies to determine how to handle this command when Redis is in clustering mode.
Unlike the command flags (the thirds elemnts in `COMMAND`'s reply), which are internal in nature (Redis itself uses them internally), command tips are just exposed via `COMMAND` and Redis does not use them.

The tips are arbirary strings, but in order to create some sort of concensus, here is a list of suggested tips:

## Boolean tips

Tips that either exist or not, no value is associated with them.

- **blocking**
- **random-output**
- **random-order-output**

### blocking

If present, this command has the potential to block (but not always, see `block_keyword` below)

### random-output

The output of the command is random (e.g. `RANDOMKEY`, `SPOP`)

### random-order-output

The output is deterministic, but comes in random order (e.g. `HGETALL`, `SMEMBERS`)

## Key-value tips

Tips that are associated with a value.

- **block_keyword** 
- **request_policy**
- **reply_policy**

### block_keyword

Identify commands which the potential to block, only is a specific arguement was given: For example, `XREAD` and `XREADGROUP` have the `vlocking` tip, but they will only block if `BLOCK` was given. We will add the `block_keyword:<word>` tip, and the proxy should search `<word>` search in `argv` to determine if the command may indeed block.
This could result in false-positive if that keyword is a keyname or some other form of free-text, but this tip best-effort: there's little harm in mistaking a non-blocking command with a blocking one (but mistaking in the other direction is unacceptable).

### request_policy

This tip should help proxies/client to determine to which shard(s) to send the command.
The default behavior (i.e. if the `request_policy` tip is absent) devides into two cases:
1. The command has key(s). In this case the command goes to a single shard, sdetemined by the hslot(s) of the key(s)
2. The command doesn't have key(s). In this case the command goes to an arbitrary shard (usually the one with the lowest hash slot).

If the proxy/client need to behave differently we must specify an option for `request_policy`:
- **ALL_SHARDS** - Forward to all shards (`PING`). Usualt used on key-less command. The operation is atomic on all shards.
- **FEW_SHARDS** - Forward to several shards, used by multi-key commands (`MSET`, `MGET`, `DEL`, etc.). The operation is atomic on relevant shards only.


### reply_policy

This tip should help clients/proxies to know how to aggregate the replies of a command that was sent to multiple shards.
The default behavior (i.e. if the `request_policy` tip is absent) applies only when the reply is some sort of collection (array, set, map) and it devides into two cases:
1. The command has key(s). In this case we append the array replies in random order (e.g. `KEYS`)
2. The command doesn't have key(s).  In this case we append the array replies in the origianl order of the request's keys (e.g. `MGET`, but not `MSET` and `DEL` which don't return an array)

If the reply is not a collection, or if the proxy/client need to behave differently we must specify an option for `reply_policy`:
- **ALL_SUCCEEDED** - Return OK if all shards didn't reply with an error. All the replies should be identical and the proxy replies back to client with one of them. Examples: `CONFIG SET`, `SCRIPT FLUSH`, `SCRIPT LOAD`
- **ONE_SUCCEEDED** - Return OK if at least one shard didn't reply with an error. The proxy should reply with the first reply it gets which isn't an error. Example: `SCRIPT KILL` (usually the script is loaded to all shards, but runs only on one. `SCRIPT KILL` is sent to all shards)
- **AGG_LOGICAL_AND** - Preform a logical AND on the replies (replies must be numerical, usually just 0/1). Example: `SCRIPT EXISTS`, which returns an array of 0/1 indicating which of the provided scripts exist. The aggregated response will be 1 iff all shards have the script.
- **AGG_LOGICAL_OR** - Preform a logical OR on the replies (replies must be numerical, usually just 0/1).
- **AGG_MIN** - Perform a minimum on replies (replies must be numerical). Example: `WAIT` (returns the lowest number among the ones the shards` replies).
- **AGG_MAX** - Perform a maximum on replies (replies must be numerical).
- **AGG_SUM** - Sums the integer values returned by the shards. Example: `DBSIZE`

