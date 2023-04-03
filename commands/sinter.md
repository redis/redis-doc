Returns the members of the set resulting from the intersection of all the given sets.

For example:

```
key1 = {a,b,c,d}
key2 = {c}
key3 = {a,c,e}
SINTER key1 key2 key3 = {c}
```

Keys that don't exist are considered to be empty sets.
Therefore, if even one of the keys doesn't exist, the resulting set is also empty, since the intersection with an empty set always results in an empty set.

@return

@array-reply: list of the members in the resulting set.

@examples

```cli
SADD key1 "a"
SADD key1 "b"
SADD key1 "c"
SADD key2 "c"
SADD key2 "d"
SADD key2 "e"
SINTER key1 key2
```
