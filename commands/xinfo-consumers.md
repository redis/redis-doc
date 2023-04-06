This command returns the list of consumers that belong to the consumer group _groupname_ of the stream stored at _key_.

The following information is provided for each consumer in the group:

* **name**: the consumer's name.
* **pending**: the number of pending messages for the client, which are messages that were delivered but are yet to be acknowledged.
* **idle**: the number of milliseconds that have passed since the consumer last interacted with the server (with `XREADGROUP`, `XCLAIM` or `XAUTOCLAIM`).
* **inactive**: the number of milliseconds that have passed since the consumer's last successful interaction (for example, `XREADGROUP` that actually read some entries into the PEL, or `XCLAIM`/`XAUTOCLAIM` that actually claimed some entries)

@return

@array-reply: a list of consumers and their attributes as described above.

@examples

```
> XINFO CONSUMERS mystream mygroup
1) 1) name
   2) "Alice"
   3) pending
   4) (integer) 1
   5) idle
   6) (integer) 9104628
   7) inactive
   8) (integer) 18104698
2) 1) name
   2) "Bob"
   3) pending
   4) (integer) 1
   5) idle
   6) (integer) 83841983
   7) inactive
   8) (integer) 993841998
```
