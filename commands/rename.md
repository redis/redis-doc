Renames `key` to `newkey`. It returns an error when the source and destination
names are the same, or when `key` does not exist. If `newkey` already exists it
is overwritten.

@return

@status-reply

@examples

    @cli
    SET mykey "Hello"
    RENAME mykey myotherkey
    GET myotherkey
