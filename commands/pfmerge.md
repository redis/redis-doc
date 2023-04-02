Merge multiple HyperLogLog values into a unique value that will approximate the cardinality of the union of the observed Sets of the source HyperLogLog structures.

The computed merged HyperLogLog is written to the _destkey_, which is created if doesn't exist (defaulting to an empty HyperLogLog).

If _destkey_ exists, it is treated as one of the source keys and its cardinality will be included in the cardinality of the computed HyperLogLog.

@return

@simple-string-reply: The command just returns `OK`.

@examples

```cli
PFADD hll1 foo bar zap a
PFADD hll2 a b c foo
PFMERGE hll3 hll1 hll2
PFCOUNT hll3
```
