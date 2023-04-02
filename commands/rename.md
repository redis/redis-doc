Renames _key_ to _newkey_.
The command returns an error when _key_ doesn't exist.

If _newkey_ already exists, it is overwritten.
When this happens, `RENAME` executes an implicit `DEL` operation, so if the deleted key contains a very big value it may cause high latency even if `RENAME` itself is usually a constant-time operation.

In Cluster mode, both _key_ and _newkey_ must be in the same **hash slot**, meaning that in practice only keys that have the same hashtag can be reliably renamed in the cluster.

@return

@simple-string-reply: `OK`.

@examples

```cli
SET mykey "Hello"
RENAME mykey myotherkey
GET myotherkey
```

## Behavior change history

*   `>= 3.2.0`: The command no longer returns an error when source and destination names are the same.
