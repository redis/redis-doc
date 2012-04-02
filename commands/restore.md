Create a key assosicated with a value that is obtained unserializing the provided serialized value (obtained via `DUMP`).

If `ttl` is 0 the key is created without any expire, otherwise the specified expire time (in milliseconds) is set.

`RESTORE` checks the RDB version and data checksum. If they don't match an error is returned.

@return

@status-reply: The command returns OK on success.

@examples

    @cli
    DEL mykey
    RESTORE mykey "\n\x17\x17\x00\x00\x00\x12\x00\x00\x00\x03\x00\x00\xc0\x01\x00\x04\xc0\x02\x00\x04\xc0\x03\x00\xff\x04\x00u#<\xc0;.\xe9\xdd"
    TYPE mykey
    LRANGE mykey 0 -1
