This command creates a new consumer group uniquely identified by `<groupname>` for the stream stored at `<key>`.

Every group has a unique name in a given stream. When a consumer group with the same name already exists, the command returns a `-BUSYGROUP` error.

The command's `<id>` argument specifies the last delivered entry in the stream from the new group's perspective.
The special ID `$` means the ID of the last entry in the stream, but you can provide any valid ID instead.
For example, if you want the group's consumers to fetch the entire stream from the beginning, use zero as the starting ID for the consumer group:

    XGROUP CREATE mystream mygroup 0

By default, the `XGROUP CREATE` command insists that the target stream exists and returns an error when it doesn't.
However, you can use the optional `MKSTREAM` subcommand as the last argument after the `<id>` to automatically create the stream (with length of 0) if it doesn't exist:

    XGROUP CREATE mystream mygroup $ MKSTREAM

@return

@simple-string-reply: `OK` on success.
