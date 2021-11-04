This command returns the time in milliseconds since the last acces to the value stored at `<key>`.

The command is only available when the `maxmemory-policy` configuration directive is set to one of the LRU policies.

@return

@integer-reply

The idle time in milliseconds.