This command returns the list of all consumers groups of the stream stored at `<key>`.

By default, only the following information is provided for each of the groups:

* **name**: the consumer group's name
* **consumers**: the number of consumers in the group
* **pending**: the length of the group's pending entries list (PEL), which are messages that were delivered but are yet to be acknowledged
* **last-delivered-id**: the ID of the last entry delivered the group's consumers

@reply

@array-reply: a list of consumer groups.

@examples

```
> XINFO GROUPS mystream
1) 1) name
   2) "mygroup"
   3) consumers
   4) (integer) 2
   5) pending
   6) (integer) 2
   7) last-delivered-id
   8) "1588152489012-0"
2) 1) name
   2) "some-other-group"
   3) consumers
   4) (integer) 1
   5) pending
   6) (integer) 0
   7) last-delivered-id
   8) "1588152498034-0"
```
