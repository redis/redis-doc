This command is used for automatic claiming of entries, without needing to specify their IDs
It is the equivalent of `XPENDING` + `XCLAIM`

The `COUNT` argument limits the amount of entries to claim. Default value is 10.
The `<start>` argument specifies the minimal ID for claiming (see comment below). 

This command returns, apart from the array of claimed entries, a stream ID which should be used as a cursor (like `SCAN`) in the succeeding call to `XAUTOCLAIM`. When `0-0` is returned it means the scan is complete. The user may want to continue calling `XAUTOCLAIM` even after a scan is complete, because entries from the beginning of stream could be idle enough for claiming.

Note that the message is claimed only if its idle time is greater the minimum idle time we specify when calling `XAUTOCLAIM`. Because as a side effect `XAUTOCLAIM` will also reset the idle time (since this is a new attempt at processing the message), two consumers trying to claim a message at the same time will never both succeed: only one will successfully claim the message. This avoids that we process a given message multiple times in a trivial way (yet multiple processing is possible and unavoidable in the general case).

Moreover, as a side effect, `XAUTOCLAIM` will increment the count of attempted deliveries of the message. In this way messages that cannot be processed for some reason, for instance because the consumers crash attempting to process them, will start to have a larger counter and can be detected inside the system.

@return

@array-reply, specifically:

An array with two elements:
The first element is an array of all the messages successfully claimed, in the same format as `XRANGE`.
The second element is a stream ID to be used as `<start>` in the next call to `XAUTOCLAIM`

Example:

```
> XAUTOCLAIM mystream mygroup Alice 3600000 0-0 COUNT 25
1) 1) 1) "1609338752495-0"
      2) 1) "field"
         2) "value"
2) "0-0"
```

In the above example we claim a maximum of 25 entries, starting from the beginning of the stream, only if the message is idle for at least one hour without the original consumer or some other consumer making progresses (acknowledging or claiming it), and assigns the ownership to the consumer `Alice`. Note that the cursor returned is `0-0` meaning we scanned the entire stream.
