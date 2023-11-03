This command is like `ZRANGE`, but stores the result in the `<dst>` destination key.

@examples

```cli
ZADD srczset 1 "one" 2 "two" 3 "three" 4 "four"
ZRANGESTORE dstzset srczset 2 -1
ZRANGE dstzset 0 -1
```
