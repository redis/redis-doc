Removes and returns one or more random members from the set value store at _key_.

This operation is similar to `SRANDMEMBER` which returns one or more random elements from a set but doesn't remove them.

By default, the command pops a single member from the set.
When provided with the optional _count_ argument, the reply will consist of up to _count_ members, depending on the set's cardinality.

{{% alert title="Note" color="info" %}}
A Redis set always consists of at least one member.
When the last member is popped, the set is automatically deleted from the database.
{{% /alert %}}

@return

When called without the _count_ argument:

@bulk-string-reply: the removed member, or @nil-reply when _key_ doesn't exist.

When called with the `count` argument:

@array-reply: the removed members, or an empty array when _key_ doesn't exist.

@examples

```cli
SADD myset "one"
SADD myset "two"
SADD myset "three"
SPOP myset
SMEMBERS myset
SADD myset "four"
SADD myset "five"
SPOP myset 3
SMEMBERS myset
```
## Distribution of returned elements

Note that this command isn't suitable if you need a guaranteed uniform distribution of the returned elements.
For more information about the algorithms used for `SPOP`, look up both the Knuth sampling and Floyd sampling algorithms.
