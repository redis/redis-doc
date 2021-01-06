`XTRIM` trims the stream to according the the **trim-strategy**, evicting older items
(items with lower IDs) if needed. The command is conceived to accept multiple
trimming strategies, however currently only two strategies is implemented:
`MAXLEN`: Trim the strim so that its length doesn't exceed `threshold`
`MINID`: Trim the stream so that the minimal ID is `threshold` (supported since 6.2.0)
So `threshold` can represent either the maximal stream length or the
minimal stream ID

For example the following command will trim the stream to exactly
the latest 1000 items:

```
XTRIM mystream MAXLEN 1000
```

To give another exmaple, the following command will trim the stream
so that it won't contain entries with IDs smaller than 649085820:

```
XTRIM mystream MINID 649085820-0
```

By default, or when provided with the optional `=` argument, the command
performs exact trimming.
If one uses the `MAXLEN` strategy, that means that the trimmed stream's length will be
exactly the minimum between its original length and the specified maximum
length.
If one uses the `MINID` strategy, that means that the oldest ID in the stream will be
exactly the minimum between its original oldest ID and the specified `threshold`.

It is possible to give the command in the following special form in
order to make it more efficient:

```
XTRIM mystream MAXLEN ~ 1000
```

The `~` argument between the **trim-strategy** option and the actual count means that
the user is not really requesting that the stream is trimmed exactly at the `threshold`,
but instead it could be a few tens of entries more, but never less than the `threshold`.
When this option modifier is used, the trimming is performed only when
Redis is able to remove a whole macro node. This makes it much more efficient,
and it is usually what you want.

The `LIMIT` option represents the maximum number of entries to trim, and so offers
another way to cap the trimming, making it more efficient on the expense of accuracy.
This option is only valid with the `~` modifier and its default is (100 * the number
of entries per macro node).
`LIMIT` of 0 means no limit on the number of trimmed entries.

@return

@integer-reply, specifically:

The command returns the number of entries deleted from the stream.

@history

* `>= 6.2`: Added the `MINID` trim strategy and the `LIMIT` option.

@examples

```cli
XADD mystream * field1 A field2 B field3 C field4 D
XTRIM mystream MAXLEN 2
XRANGE mystream - +
```
