`CLUSTER SLOTS` returns details about which cluster slots map to which
Redis instances. The command is suitable to be used by Redis Cluster client
libraries implementations in order to retrieve (or update when a redirection
is received) the map associating cluster *hash slots* with actual nodes
network coordinates (composed of an IP address, a TCP port, and the node ID), so that when
a command is received, it can be sent to what is likely the right instance
for the keys specified in the command.

## Nested Result Array
Each nested result is:

  - Start slot range
  - End slot range
  - Master for slot range represented as nested IP/Port/ID array
  - First replica of master for slot range
  - Second replica
  - ...continues until all replicas for this master are returned.

Each result includes all active replicas of the master instance
for the listed slot range.  Failed replicas are not returned.

The third nested reply is guaranteed to be the IP/Port/ID array of
the master instance for the slot range.
All IP/Port/ID arrays after the third nested reply are replicas
of the master.

If a cluster instance has non-contiguous slots (e.g. 1-400,900,1800-6000) then
master and replica IP/Port/ID results will be duplicated for each top-level
slot range reply.

@return

@array-reply: nested list of slot ranges with IP/Port/ID mappings.

@examples

```
> CLUSTER SLOTS
1) 1) (integer) 0
   2) (integer) 5460
   3) 1) "127.0.0.1"
      2) (integer) 30001
      3) "09dbe9720cda62f7865eabc5fd8857c5d2678366"
   4) 1) "127.0.0.1"
      2) (integer) 30004
      3) "821d8ca00d7ccf931ed3ffc7e3db0599d2271abf"
2) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "127.0.0.1"
      2) (integer) 30002
      3) "c9d93d9f2c0c524ff34cc11838c2003d8c29e013"
   4) 1) "127.0.0.1"
      2) (integer) 30005
      3) "faadb3eb99009de4ab72ad6b6ed87634c7ee410f"
3) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "127.0.0.1"
      2) (integer) 30003
      3) "044ec91f325b7595e76dbcb18cc688b6a5b434a1"
   4) 1) "127.0.0.1"
      2) (integer) 30006
      3) "58e6e48d41228013e5d9c1c37c5060693925e97e"
```

**Warning:** In future versions there could be more elements describing the node better. In general a client implementation should just rely on the fact that certain parameters are at fixed positions as specified, but more parameters may follow and should be ignored. Similarly a client library should try if possible to cope with the fact that older versions may just have the IP and port parameter.
