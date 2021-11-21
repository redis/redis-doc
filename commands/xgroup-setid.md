Set the **last delivered ID** for a consumer group.

Normally, a consumer group's last delivered ID is set when the group is created with `XGROUP CREATE`.
The `XGROUP SETID` command allows modifying the group's last delivered ID, without having to delete and recreate the group.
For instance if you want the consumers in a consumer group to re-process all the messages in a stream, you may want to set its next ID to 0:

    XGROUP SETID mystream mygroup 0

@return

@simple-string-reply: `OK` on success.
