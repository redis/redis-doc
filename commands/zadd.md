Adds all the specified members with the specified scores to the sorted set stored at _key_.
It is possible to specify multiple score/member pairs.
If a specified _member_ is already a member of the sorted set, the score is updated and the member is reinserted at the right position to ensure the correct ordering.

If the _key_ doesn't exist, a new sorted set with the specified members is created.
If the _key_ exists but doesn't store a sorted set, an error is returned.

The score values should be the string representation of a double-precision floating point number.
`+inf` and `-inf` values are valid values as well.

## Options

`ZADD` supports a list of options, specified after the name of the key and before the first score argument.
These options are:

* `XX`: only update members that already exist. Don't add new members.
* `NX`: only add new members. Don't update already existing members.
* `LT`: only update existing members if the new score is **less than** the current score. This flag doesn't prevent adding new members.
* `GT`: only update existing members if the new score is **greater than** the current score. This flag doesn't prevent adding new members.
* `CH`: modify the return value from the number of new members added, to the total number of members changed (CH is an abbreviation of *changed*). Changed members are **new members added** and members already existing for which **the score was updated**. So members specified in the command line having the same score as they had in the past are not counted. Note: normally the return value of `ZADD` only counts the number of new members added.
* `INCR`: when this option is specified `ZADD` acts like `ZINCRBY`. Only one score-member pair can be specified in this mode.

Note: The `GT`, `LT` and `NX` options are mutually exclusive.

## Range of integer scores that can be expressed precisely

Redis sorted sets use a *double 64-bit floating point number* to represent the score.
In all the architectures we support, this is represented as an **IEEE 754 floating point number, that can represent precisely integer numbers between `-(2^53)` and `+(2^53)` included.
In more practical terms, all the integers between -9007199254740992 and 9007199254740992 are perfectly representable.
Larger integers, or fractions, are internally represented in exponential form, so you may get only an approximation of the decimal number, or the very big integer, that you set as a score.

## Sorted sets 101

Sorted sets are sorted by their score in an ascending way.
The same member only exists a single time, no repeated members are permitted.
The score can be modified both by `ZADD` that will update the member score, and as a side effect, its position on the sorted set, and by `ZINCRBY` which can be used to update the score relative to its previous value.

The current score of an member can be retrieved using the `ZSCORE` command, which can also be used to verify if an member already exists or not.

For an introduction to sorted sets, see the data types page on [sorted sets][tdtss].

[tdtss]: /topics/data-types#sorted-sets

## members with the same score

While the same member can't be repeated in a sorted set since every member
is unique, it is possible to add multiple different members *having the same score*.
When multiple members have the same score, they are *ordered lexicographically* (they are still ordered by score as a first key, however, locally, all the members with the same score are relatively ordered lexicographically).

The lexicographic ordering used is binary, it compares strings as an array of bytes.

If the user inserts all the members in a sorted set with the same score (for example 0), all the members of the sorted set are sorted lexicographically, and range queries on members are possible using the command `ZRANGEBYLEX` (note: it is also possible to query sorted sets by a range of scores using `ZRANGEBYSCORE`).

@return

@integer-reply, specifically:

* When used without optional arguments, the number of members added to the sorted set (excluding score updates).
* If the `CH` option is specified, the number of members that were changed (added or updated).

If the `INCR` option is specified, the return value will be @bulk-string-reply:

* The new score of the _member_ (a double-precision floating point number) represented as string, or @nil-reply if the operation was aborted (when called with either the `XX` or the `NX` option).

@examples

```cli
ZADD myzset 1 "one"
ZADD myzset 1 "uno"
ZADD myzset 2 "two" 3 "three"
ZRANGE myzset 0 -1 WITHSCORES
```
