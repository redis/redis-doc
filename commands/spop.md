Removes and returns one or more random elements from the set value store at `key`.

This operation is similar to `SRANDMEMBER`, that returns one or more random elements from a set but does not remove it.

@return

@bulk-string-reply: the removed element, or `nil` when `key` does not exist.

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


## Specification of the behavior when count is passed

If count is bigger than the number of elements inside the Set, the command will only return the whole set without additional elements.

## Distribution of returned elements

Note that this command is not suitable when you need a guaranteed uniform distribution of the returned elements. For more information about the algorithms used for SPOP, look up both the Knuth sampling and Floyd sampling algorithms.