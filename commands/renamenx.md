Renames _key_ to _newkey_ if and only if _newkey_ doesn't exist.
The command returns an error when the _key_ doesn't exist.

In Cluster mode, both the _key_ and the _newkey_ must be in the same **hash slot**, meaning that in practice only keys that have the same hashtag can be reliably renamed in the cluster.

@return

@integer-reply, specifically:

* `1` if the _key_ was renamed to _newkey_.
* `0` if the _newkey_ already exists.

@examples

```cli
SET mykey "Hello"
SET myotherkey "World"
RENAMENX mykey myotherkey
GET myotherkey
```
