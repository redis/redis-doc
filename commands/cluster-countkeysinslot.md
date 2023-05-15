The command queries only the node's data set.
The reply of this command, when executed against a node that isn't serving the specified hash slot, is always zero (0).

```
> CLUSTER COUNTKEYSINSLOT 7000
(integer) 50341
```

@return

@integer-reply: The number of keys in the specified hash slot, or an error if the hash slot is invalid.
