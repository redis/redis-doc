Return the position of the first bit set to 1 or 0 in a string.

The position is returned, thinking of the string as an array of bits from left to
right, where the first byte's most significant bit is at position 0, the second
byte's most significant bit is at position 8, and so forth.

The same bit position convention is followed by `GETBIT` and `SETBIT`.

By default, all the bytes contained in the string are examined.
It is possible to look for bits only in a specified interval passing the additional arguments _start_ and _end_ (it is possible to just pass _start_, the operation will assume that the end is the last byte of the string. However there are semantic differences as explained later).
By default, the range is interpreted as a range of bytes and not a range of bits, so `start=0` and `end=2` means to look at the first three bytes.

You can use the optional `BIT` modifier to specify that the range should be interpreted as a range of bits.
So `start=0` and `end=2` means to look at the first three bits.

Note that bit positions are returned always as absolute values starting from bit zero even when _start_ and _end_ are used to specify a range.

Like for the `GETRANGE` command start and end can contain negative values in
order to index bytes starting from the end of the string, where -1 is the last
byte, -2 is the penultimate, and so forth. When `BIT` is specified, -1 is the last
bit, -2 is the penultimate, and so forth.

Non-existent keys are treated as empty strings.

@examples

```cli
SET mykey "\xff\xf0\x00"
BITPOS mykey 0
SET mykey "\x00\xff\xf0"
BITPOS mykey 1 0
BITPOS mykey 1 2
BITPOS mykey 1 2 -1 BYTE
BITPOS mykey 1 7 15 BIT
set mykey "\x00\x00\x00"
BITPOS mykey 1
BITPOS mykey 1 7 -3 BIT
```
