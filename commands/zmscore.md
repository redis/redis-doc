Returns the score of multiple `members` in the sorted set at `key`.

If the `key` does not exist,
`nil` is
returned.

If some `member` does not exist,
his value in the response array will be `nil`.

@return

@array-reply: list of scores for the specified members

@examples

```cli
ZADD myzset 10 "one"
ZADD myzset 20 "two"
ZMSCORE myzset "one" "two"
```
