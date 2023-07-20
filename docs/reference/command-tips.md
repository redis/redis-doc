---
title: "Redis command tips"
linkTitle: "Command tips"
weight: 1
description: Get additional information about a command
aliases:
    - /topics/command-tips
---

Command tips are an array of strings.
These provide Redis clients with additional information about the command.
The information can instruct Redis Cluster clients as to how the command should be executed and its output processed in a clustered deployment.

Unlike the command's flags (see the 3rd element of `COMMAND`'s reply), which are strictly internal to the server's operation, tips don't serve any purpose other than being reported to clients.

Command tips are arbitrary strings.
However, the following sections describe proposed tips and demonstrate the conventions they are likely to adhere to.

## nondeterministic_output

This tip indicates that the command's output isn't deterministic.
That means that calls to the command may yield different results with the same arguments and data.
That difference could be the result of the command's random nature (e.g., `RANDOMKEY` and `SPOP`); the call's timing (e.g., `TTL`); or generic differences that relate to the server's state (e.g., `INFO` and `CLIENT LIST`).

**Note:**
Prior to Redis 7.0, this tip was the _random_ command flag.

## nondeterministic_output_order

The existence of this tip indicates that the command's output is deterministic, but its ordering is random (e.g., `HGETALL` and `SMEMBERS`).

**Note:**
Prior to Redis 7.0, this tip was the _sort_\__for_\__script_ flag.

## request_policy

This tip can help clients determine the shards to send the command in clustering mode.
The default behavior a client should implement for commands without the _request_policy_ tip is as follows:

1. The command doesn't accept key name arguments: the client can execute the command on an arbitrary shard.
1. For commands that accept one or more key name arguments: the client should route the command to a single shard, as determined by the hash slot of the input keys.

In cases where the client should adopt a behavior different than the default, the _request_policy_ tip can be one of:

- **all_nodes:** the client should execute the command on all nodes - masters and replicas alike.
  An example is the `CONFIG SET` command. 
  This tip is in-use by commands that don't accept key name arguments.
  The command operates atomically per shard.
* **all_shards:** the client should execute the command on all master shards (e.g., the `DBSIZE` command).
  This tip is in-use by commands that don't accept key name arguments.
  The command operates atomically per shard.
- **multi_shard:** the client should execute the command on several shards.
  The client should split the inputs according to the hash slots of its input key name arguments. For example, the command `DEL {foo} {foo}1 bar` should be split to `DEL {foo} {foo}1` and `DEL bar`. If the keys are hashed to more than a single slot, the command must be split even if all the slots are managed by the same shard.
  Examples for such commands include `MSET`, `MGET` and `DEL`.
  However, note that `SUNIONSTORE` isn't considered as _multi_shard_ because all of its keys must belong to the same hash slot.
- **special:** indicates a non-trivial form of the client's request policy, such as the `SCAN` command.

## response_policy

This tip can help clients determine the aggregate they need to compute from the replies of multiple shards in a cluster.
The default behavior for commands without a _request_policy_ tip only applies to replies with of nested types (i.e., an array, a set, or a map).
The client's implementation for the default behavior should be as follows:

1. The command doesn't accept key name arguments: the client can aggregate all replies within a single nested data structure.
For example, the array replies we get from calling `KEYS` against all shards.
These should be packed in a single in no particular order.
1. For commands that accept one or more key name arguments: the client needs to retain the same order of replies as the input key names.
For example, `MGET`'s aggregated reply.

The _response_policy_ tip is set for commands that reply with scalar data types, or when it's expected that clients implement a non-default aggregate.
This tip can be one of:

* **one_succeeded:** the clients should return success if at least one shard didn't reply with an error.
  The client should reply with the first non-error reply it obtains.
  If all shards return an error, the client can reply with any one of these.
  For example, consider a `SCRIPT KILL` command that's sent to all shards.
  Although the script should be loaded in all of the cluster's shards, the `SCRIPT KILL` will typically run only on one at a given time.
* **all_succeeded:** the client should return successfully only if there are no error replies.
  Even a single error reply should disqualify the aggregate and be returned.
  Otherwise, the client should return one of the non-error replies.
  As an example, consider the `CONFIG SET`, `SCRIPT FLUSH` and `SCRIPT LOAD` commands.
* **agg_logical_and:** the client should return the result of a logical _AND_ operation on all replies (only applies to integer replies, usually from commands that return either _0_ or _1_).
  Consider the `SCRIPT EXISTS` command as an example.
  It returns an array of _0_'s and _1_'s that denote the existence of its given SHA1 sums in the script cache.
  The aggregated response should be _1_ only when all shards had reported that a given script SHA1 sum is in their respective cache.
* **agg_logical_or:** the client should return the result of a logical _AND_ operation on all replies (only applies to integer replies, usually from commands that return either _0_ or _1_).
* **agg_min:** the client should return the minimal value from the replies (only applies to numerical replies).
  The aggregate reply from a cluster-wide `WAIT` command, for example, should be the minimal value (number of synchronized replicas) from all shards.
* **agg_max:** the client should return the maximal value from the replies (only applies to numerical replies).
* **agg_sum:** the client should return the sum of replies (only applies to numerical replies).
  Example: `DBSIZE`.
* **special:** this type of tip indicates a non-trivial form of reply policy.
  `INFO` is an excellent example of that.

## Example

```
redis> command info ping
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
