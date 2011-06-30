@complexity

O(N) where N is the number of fields that will be removed.

Removes the specified fields from the hash stored at `key`. Non-existing fields
are ignored. Non-existing keys are treated as empty hashes and this command
returns `0`.

For Redis versions 2.2 and below, this command is only available as a
non-variadic variant. To remove multiple fields from a hash in an atomic
fashion for those versions, use a `MULTI`/`EXEC` block.

@return

@integer-reply: The number of fields that were removed.

@examples

    @cli
    HSET myhash field1 "foo"
    HDEL myhash field1
    HDEL myhash field2

