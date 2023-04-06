Returns the rank of _member_ in the sorted set stored at _key_, ordered by descending scores.

The rank (or index) is 0-based, which means that the member with the highest score has a rank of `0`.

The optional `WITHSCORE` argument supplements the command's reply with the member's score.

Use `ZRANK` to get the rank of a member by ascending score order.

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
ZREVRANK myzset "one"
ZREVRANK myzset "four"
ZREVRANK myzset "three" WITHSCORE
ZREVRANK myzset "four" WITHSCORE
```
