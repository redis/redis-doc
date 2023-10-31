Returns the number of keys in the specified Redis Cluster hash slot. The
command only queries the local data set, so contacting a node
that is not serving the specified hash slot will always result in a count of
zero being returned.

```
> CLUSTER COUNTKEYSINSLOT 7000
(integer) 50341
```
