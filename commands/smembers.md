Returns all the members of the set value stored at `key`.

This has the same effect as running `SINTER` with one argument `key`.

@return

@array-reply: all elements of the set.

@examples

```cli
SADD myset "Hello"
SADD myset "World"
SMEMBERS myset
```

If all the members of the set have the same type of integers, returned array will be sorted automatically in ascending order 

@example 
```cli
SADD myset1 9 10 2 6 20
SMEMBERS myset1
```
