Renames `key` to `newkey`.
It returns an error when the source and destination names are the same, or when
`key` does not exist.
If `newkey` already exists it is overwritten, when this happens `RENAME` executes an implicit `DEL` operation, so if the deleted key contains a very big value it may cause high latency even if `RENAME` itself is usually a constant-time operation.

@return

@simple-string-reply

@examples

```cli
SET mykey "Hello"
RENAME mykey myotherkey
GET myotherkey
```
