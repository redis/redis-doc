Set `key` to hold the string `value`. If `key` already holds a value, it is
overwritten, regardless of its type.

@return

@status-reply: always `OK` since `SET` can't fail.

@examples

    @cli
    SET mykey "Hello"
    GET mykey
