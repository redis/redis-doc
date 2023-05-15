Removes and returns up to _count_ members with the lowest scores in the [Redis sorted set](/docs/data-types/sorted-sets) stored at _key_.

If unspecified, the default value for _count_ is 1. 
Specifying a _count_ value that is higher than the sorted set's cardinality will not produce an
error.
When returning multiple members, the one with the lowest score will be the first, followed by the members with greater scores.

{{% alert title="Note" color="info" %}}
A Redis sorted set always consists of at least one member.
When the last member is popped, the sorted set is automatically deleted from the database.
{{% /alert %}}

@return

@array-reply: list of popped members and scores.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZPOPMIN myzset
```
