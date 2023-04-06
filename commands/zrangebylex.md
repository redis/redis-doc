When all the members in a sorted set are inserted with the same score, to force lexicographical ordering, this command returns the number of members in the sorted set at the _key_ with a value between _min_ and _max_.

If the members in the sorted set have different scores, the returned members are unspecified.

The members are considered to be ordered from lower to higher strings as compared byte-by-byte using the `memcmp()` C function.
Longer strings are considered greater than shorter strings if the common part is identical.

The optional `LIMIT` argument can be used to only get a range of the matching members (similar to _SELECT LIMIT offset, count_ in SQL).
A negative _count_ returns all members from the _offset_.
Keep in mind that if the _offset_ is large, the sorted set needs to be traversed for _offset_ members before getting to the members to return, which can add up to O(N) time complexity.

## Specifying intervals

Valid _start_ and _stop_ must start with `(` or `[`, to specify whether the range item is exclusive or inclusive, respectively.
The special values of `+` or `-` for _start_ and _stop_ have the special meaning or positively infinite and negatively infinite strings.
So, for instance, the command `ZRANGEBYLEX myzset - +` is guaranteed to return all the members in the sorted set, if all the members have the same score.

## Details on strings comparison

Strings are compared as arrays of bytes.
Because of how the ASCII character set is specified, this means that usually this also has the effect of comparing normal ASCII characters in an obvious dictionary way.
However, this isn't true if non-plain ASCII strings are used (for example utf8 strings).

However, the user can apply a transformation to the encoded string so that the first part of the member inserted in the sorted set will compare as the user requires for the specific application.
For example, if I want to add strings that will be compared in a case-insensitive way, but I still want to retrieve the real case when querying, I can add strings in the
following way:

    ZADD autocomplete 0 foo:Foo 0 bar:BAR 0 zap:zap

Because of the first *normalized* part in every member (before the colon character), we are forcing a given comparison, however after the range is queried using `ZRANGEBYLEX` the application can display to the user the second part of the string, after the colon.

The binary nature of the comparison allows the use of sorted sets as a general-purpose index, for example, the first part of the member can be a 64-bit big-endian number.
Since big-endian numbers have the most significant bytes in the initial positions, the binary comparison will match the numerical comparison of the numbers.
This can be used to implement range queries on 64-bit values.
As in the example below, after the first 8 bytes, we can store the value of the member we are indexing.

@return

@array-reply: list of members in the specified score range.

@examples

```cli
ZADD myzset 0 a 0 b 0 c 0 d 0 e 0 f 0 g
ZRANGEBYLEX myzset - [c
ZRANGEBYLEX myzset - (c
ZRANGEBYLEX myzset [aaa (g
```
