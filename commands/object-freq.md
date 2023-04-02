This command returns the logarithmic access frequency counter of a Redis object stored at _key_.

The command is only available when the `maxmemory-policy` configuration directive is set to one of the LFU policies.

@return

@integer-reply: the counter's value, or @nil-reply if _key_ doesn't exist.
