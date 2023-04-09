Pops one or more members from the first non-empty [Redis sorted set](/docs/data-types/sorted-sets) in the provided list of _key_ names.

`ZMPOP` and `BZMPOP` are similar to the following, more limited, commands:

- `ZPOPMIN` or `ZPOPMAX`, which take a single key, and can return multiple members.
- `BZPOPMIN` or `BZPOPMAX`, which take multiple keys, but return only one member from just one key.

See `BZMPOP` for the blocking variant of this command.

When the `MIN` modifier is used, the members popped are those with the lowest scores from the first non-empty sorted set.
The `MAX` modifier causes members with the highest scores to be popped.
The optional `COUNT` can be used to specify the number of members to pop and is set to 1 by default.

The number of popped members is the minimum from the sorted set's cardinality and `COUNT`'s value.

{{% alert title="Note" color="info" %}}
A Redis sorted set always consists of at least one member.
When the last member is popped, the sorted set is automatically deleted from the database.
{{% /alert %}}

@return

@array-reply: specifically:

* A @nil-reply when no member could be popped.
* A two-member array with the first member being the name of the key from which members were popped, and the second member is an array of the popped members.
  Every entry in the members array is also an array that contains the member and its score.

@examples

```cli
ZMPOP 1 notsuchkey MIN
ZADD myzset 1 "one" 2 "two" 3 "three"
ZMPOP 1 myzset MIN
ZRANGE myzset 0 -1 WITHSCORES
ZMPOP 1 myzset MAX COUNT 10
ZADD myzset2 4 "four" 5 "five" 6 "six"
ZMPOP 2 myzset myzset2 MIN COUNT 10
ZRANGE myzset 0 -1 WITHSCORES
ZMPOP 2 myzset myzset2 MAX COUNT 10
ZRANGE myzset2 0 -1 WITHSCORES
EXISTS myzset myzset2
```
