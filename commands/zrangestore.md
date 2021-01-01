This command is like `ZRANGE`, but stores the result in destination key.

@return

@integer-reply: the number of elements in the resulting sorted set.

@examples

```cli
ZADD key1 1 "one" 2 "two" 3 "three" 4 "four"
ZRANGESTORE key2 key1 2 -1
ZRANGE key2
```
