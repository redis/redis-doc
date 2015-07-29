`CLUSTER SLOTS` returns details about which cluster slots map to which
Redis instances. The command is suitable to be used by Redis Cluster client
libraries implementations in order to retrieve (or update when a redirection
is received) the map associating cluster *hash slots* with actual nodes
network coordinates (composed of an IP address and a TCP port), so that when
a command is received, it can be sent to what is likely the right instance
for the keys specified in the command.

## Nested Result Array
Each nested result is:

  - Start slot range
  - End slot range
  - Master for slot range represented as nested IP/Port array 
  - First replica of master for slot range
  - Second replica
  - ...continues until all replicas for this master are returned.

Each result includes all active replicas of the master instance
for the listed slot range.  Failed replicas are not returned.

The third nested reply is guaranteed to be the IP/Port pair of
the master instance for the slot range.
All IP/Port pairs after the third nested reply are replicas
of the master.

If a cluster instance has non-contiguous slots (e.g. 1-400,900,1800-6000) then
master and replica IP/Port results will be duplicated for each top-level
slot range reply.

@return

@array-reply: nested list of slot ranges with IP/Port mappings.

### Sample Output
```
127.0.0.1:7001> cluster slots
1) 1) (integer) 0
   2) (integer) 4095
   3) 1) "127.0.0.1"
      2) (integer) 7000
   4) 1) "127.0.0.1"
      2) (integer) 7004
2) 1) (integer) 12288
   2) (integer) 16383
   3) 1) "127.0.0.1"
      2) (integer) 7003
   4) 1) "127.0.0.1"
      2) (integer) 7007
3) 1) (integer) 4096
   2) (integer) 8191
   3) 1) "127.0.0.1"
      2) (integer) 7001
   4) 1) "127.0.0.1"
      2) (integer) 7005
4) 1) (integer) 8192
   2) (integer) 12287
   3) 1) "127.0.0.1"
      2) (integer) 7002
   4) 1) "127.0.0.1"
      2) (integer) 7006
```


