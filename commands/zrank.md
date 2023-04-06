Returns the rank of _member_ in the sorted set stored at _key_, ordered by ascending scores.
The rank (or index) is 0-based, which means that the member with the lowest score has rank `0`.

The optional `WITHSCORE` argument supplements the command's reply with the score of the member returned.

Use `ZREVRANK` to get the rank of a member in descending score order.

@return

* If _member_ exists in the sorted set:
  * using `WITHSCORE`, @array-reply: an array containing the rank and score of _member_.
  * without using `WITHSCORE`, @integer-reply: the rank of _member_.
* If _member_ doesn't exist in the sorted set or _key_ doesn't exist:
  * using `WITHSCORE`, array @nil-reply.
  * without using `WITHSCORE`, @nil-reply.
  
Note that in RESP3 there's only one null reply, but RESP2 has both a regular null and a null array.

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 2 "two"
ZADD myzset 3 "three"
ZRANK myzset "three"
ZRANK myzset "four"
ZRANK myzset "three" WITHSCORE
ZRANK myzset "four" WITHSCORE
```
