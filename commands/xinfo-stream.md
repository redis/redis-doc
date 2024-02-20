This command returns information about the stream stored at `<key>`.

The informative details provided by this command are:

* **length**: the number of entries in the stream (see `XLEN`)
* **radix-tree-keys**: the number of keys in the underlying radix data structure
* **radix-tree-nodes**: the number of nodes in the underlying radix data structure
* **groups**: the number of consumer groups defined for the stream
* **last-generated-id**: the ID of the least-recently entry that was added to the stream
* **max-deleted-entry-id**: the maximal entry ID that was deleted from the stream
* **entries-added**: the count of all entries added to the stream during its lifetime
* **first-entry**: the ID and field-value tuples of the first entry in the stream
* **last-entry**: the ID and field-value tuples of the last entry in the stream

### The `FULL` modifier

The optional `FULL` modifier provides a more verbose reply.
When provided, the `FULL` reply includes an **entries** array that consists of the stream entries (ID and field-value tuples) in ascending order.
Furthermore, **groups** is also an array, and for each of the consumer groups it consists of the information reported by `XINFO GROUPS` and `XINFO CONSUMERS`.

The following information is provided for each of the groups:

* **name**: the consumer group's name
* **last-delivered-id**: the ID of the last entry delivered to the group's consumers
* **entries-read**: the logical "read counter" of the last entry delivered to the group's consumers
* **lag**: the number of entries in the stream that are still waiting to be delivered to the group's consumers, or a NULL when that number can't be determined.
* **pel-count**: the length of the group's pending entries list (PEL), which are messages that were delivered but are yet to be acknowledged
* **pending**: an array with pending entries information (see below)
* **consumers**: an array with consumers information (see below)

The following information is provided for each pending entry:

1. The ID of the message.
2. The name of the consumer that fetched the message and has still to acknowledge it. We call it the current *owner* of the message.
3. The UNIX timestamp of when the message was delivered to this consumer.
4. The number of times this message was delivered.

The following information is provided for each consumer:

* **name**: the consumer's name
* **seen-time**: the UNIX timestamp of the last attempted interaction (Examples: `XREADGROUP`, `XCLAIM`, `XAUTOCLAIM`)
* **active-time**: the UNIX timestamp of the last successful interaction (Examples: `XREADGROUP` that actually read some entries into the PEL, `XCLAIM`/`XAUTOCLAIM` that actually claimed some entries)
* **pel-count**: the number of entries in the PEL: pending messages for the consumer, which are messages that were delivered but are yet to be acknowledged
* **pending**: an array with pending entries information, has the same structure as described above, except the consumer name is omitted (redundant, since anyway we are in a specific consumer context)

Note that before Redis 7.2.0 **seen-time** used to denote the last successful interaction.
In 7.2.0 **active-time** was added and **seen-time** was changed to denote the last attempted interaction.

The `COUNT` option can be used to limit the number of stream and PEL entries that are returned (The first `<count>` entries are returned).
The default `COUNT` is 10 and a `COUNT` of 0 means that all entries will be returned (execution time may be long if the stream has a lot of entries).

@examples

Default reply:

```
> XINFO STREAM mystream
 1) "length"
 2) (integer) 2
 3) "radix-tree-keys"
 4) (integer) 1
 5) "radix-tree-nodes"
 6) (integer) 2
 7) "last-generated-id"
 8) "1638125141232-0"
 9) "max-deleted-entry-id"
10) "0-0"
11) "entries-added"
12) (integer) 2
13) "groups"
14) (integer) 1
15) "first-entry"
16) 1) "1638125133432-0"
    2) 1) "message"
       2) "apple"
17) "last-entry"
18) 1) "1638125141232-0"
    2) 1) "message"
       2) "banana"
```

Full reply:

```
> XADD mystream * foo bar
"1638125133432-0"
> XADD mystream * foo bar2
"1638125141232-0"
> XGROUP CREATE mystream mygroup 0-0
OK
> XREADGROUP GROUP mygroup Alice COUNT 1 STREAMS mystream >
1) 1) "mystream"
   2) 1) 1) "1638125133432-0"
         2) 1) "foo"
            2) "bar"
> XINFO STREAM mystream FULL
 1) "length"
 2) (integer) 2
 3) "radix-tree-keys"
 4) (integer) 1
 5) "radix-tree-nodes"
 6) (integer) 2
 7) "last-generated-id"
 8) "1638125141232-0"
 9) "max-deleted-entry-id"
10) "0-0"
11) "entries-added"
12) (integer) 2
13) "entries"
14) 1) 1) "1638125133432-0"
       2) 1) "foo"
          2) "bar"
    2) 1) "1638125141232-0"
       2) 1) "foo"
          2) "bar2"
15) "groups"
16) 1)  1) "name"
        2) "mygroup"
        3) "last-delivered-id"
        4) "1638125133432-0"
        5) "entries-read"
        6) (integer) 1
        7) "lag"
        8) (integer) 1
        9) "pel-count"
       10) (integer) 1
       11) "pending"
       12) 1) 1) "1638125133432-0"
              2) "Alice"
              3) (integer) 1638125153423
              4) (integer) 1
       13) "consumers"
       14) 1) 1) "name"
              2) "Alice"
              3) "seen-time"
              4) (integer) 1638125133422
              5) "active-time"
              6) (integer) 1638125133432
              7) "pel-count"
              8) (integer) 1
              9) "pending"
              10) 1) 1) "1638125133432-0"
                     2) (integer) 1638125133432
                     3) (integer) 1
```
