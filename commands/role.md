Provide information on the role of a Redis instance in the context of replication, by returning if the instance is currently a `master`, `slave`, or `sentinel`. The command also returns additional information about the state of the replication (if the role is master or slave) or the list of monitored master names (if the role is sentinel).

## Output format

The command returns an array of elements. The first element is the role of
the instance, as one of the following three strings:

* "master"
* "slave"
* "sentinel"

The additional elements of the array depends on the role.

## Master output

An example of output when `ROLE` is called in a master instance:

```
1) "master"
2) (integer) 3129659
3) 1) 1) "127.0.0.1"
      2) "9001"
      3) "3129242"
   2) 1) "127.0.0.1"
      2) "9002"
      3) "3129543"
```

The master output is composed of the following parts:

1. The string `master`.
2. The current master replication offset, which is an offset that masters and slaves share to understand, in partial resynchronizations, the part of the replication stream the slave needs to fetch to continue.
3. An array composed of three elements array representing the connected slaves. Every sub-array contains the slave IP, port, and the last acknowledged replication offset.

## Slave output

An example of output when `ROLE` is called in a slave instance:

```
1) "slave"
2) "127.0.0.1"
3) (integer) 9000
4) "connected"
5) (integer) 3167038
```

The slave output is composed of the following parts:

1. The string `slave`.
2. The IP of the master.
3. The port number of the master.
4. The state of the replication from the point of view of the master, that can be `connect` (the instance needs to connect to its master), `connecting` (the slave-master connection is in progress), `sync` (the master and slave are trying to perform the synchronization), `connected` (the slave is online).
5. The amount of data received from the slave so far in terms of master replication offset.

## Sentinel output

An example of Sentinel output:

```
1) "sentinel"
2) 1) "resque-master"
   2) "html-fragments-master"
   3) "stats-master"
   4) "metadata-master"
```

The sentinel output is composed of the following parts:

1. The string `sentinel`.
2. An array of master names monitored by this Sentinel instance.

@return

@array-reply: where the first element is one of `master`, `slave`, `sentinel` and the additional elements are role-specific as illustrated above.

@history

* This command was introduced in the middle of a Redis stable release, specifically with Redis 2.8.12.

@examples

```cli
ROLE
```
