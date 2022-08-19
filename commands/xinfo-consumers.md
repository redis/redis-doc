Returns the list of consumers that belong to the `groupname` consumer group of the stream stored at `key`.

[Examples](#examples)

## Required parameters

<details open>
<summary><code>key</code></summary>

is name of the stream.
</details>

<details open>
<summary><code>groupname</code></summary>

is name of the consumer group.
</details>

## Return

XINFO CONSUMERS returns an @array-reply of consumers, with these elements:

- `name` - Consumer's name
- `pending` - Number of pending messages for the client, which are messages that were delivered but are yet to be acknowledged.
- `idle` - Number of milliseconds that have passed since the consumer last interacted with the server and read an entry from the stream.

## Examples

<details open>
<summary><b>Return the list of consumers</b></summary>

Return the list of consumers from `mygroup`.

{{< highlight bash >}}
127.0.0.1:6379> XINFO CONSUMERS mystream mygroup
1) 1) name
   2) "Alice"
   3) pending
   4) (integer) 1
   5) idle
   6) (integer) 83841983
{{< / highlight >}}

## See also

`XINFO` | `XINFO GROUPS` | `XINFO STREAM` | `XINFO HELP`

## Related topics

[Redis streams tutorial](docs/data-types/streams-tutorial)