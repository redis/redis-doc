Returns all the members of the [Redis set](/docs/data-types/sets) value stored at _key_.

This has the same effect as running `SINTER` with a single _key_ argument.

{{% alert title="Warning" color="warning" %}}
This command requires space and time that are proportional to the set's cardinality.
Given this command's complexity, you should use caution when calling it in production.
Prefer using `SSCAN` for iterating over sets with a large number of members.
{{% /alert %}}

@return

@array-reply: all members in the set.

@examples

```cli
SADD myset "Hello"
SADD myset "World"
SMEMBERS myset
```
