The `XGROUP DESTROY` command completely destroys a consumer group.

The consumer group will be destroyed even if there are active consumers, and pending messages, so make sure to call this command only when really needed.
