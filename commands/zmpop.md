Pops one or more elements(member / score pair) from the first non-empty sorted set key from the list of provided key names.

`ZMPOP` and `BZMPOP` are similar to the following, more limited, commands:
- `ZPOPMIN` or `ZPOPMAX` which take only one key, and can return multiple elements.
- `BZPOPMIN` or `BZPOPMAX` which take multiple keys, but return only one element from just one key.

See `BZMPOP` for the blocking variant of this command.

Elements are popped from either the min or max of the first non-empty sorted set based on the passed argument.
The number of returned elements is limited to the lower between the non-empty sorted set's length, and the count argument (which defaults to 1).

@return

@array-reply: specifically:

* A `nil` when no element could be popped.
* A two-element array with the first element being the name of the key from which elements were popped, and the second element is an array of elements, and each element is also an array that contains the member and score.

@examples

```cli
ZMPOP 2 non1 non2 MIN COUNT 10
ZADD myzset 1 "one" 2 "two" 3 "three"
ZMPOP 1 myzset MIN
ZRANGE myzset 0 -1 WITHSCORES
ZMPOP 1 myzset MAX COUNT 10
ZADD myzset2 4 "four" 5 "five" 6 "six"
ZMPOP 2 myzset myzset2 MIN COUNT 10
ZRANGE myzset 0 -1 WITHSCORES
ZMPOP 2 myzset myzset2 MAX count 10
ZRANGE myzset2 0 -1 WITHSCORES
EXISTS myzset myzset2
```
