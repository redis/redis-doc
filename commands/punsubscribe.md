@complexity

O(N+M) where N is the number of patterns the client is already
subscribed and M is the number of total patterns subscribed in the
system (by any client).

Unsubscribes the client from the given patterns, or from all of them if
none is given.

When no patters are specified, the client is unsubscribed from all
the previously subscribed patterns. In this case, a message for every
unsubscribed pattern will be sent to the client.
