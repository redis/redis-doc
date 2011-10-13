Redis cluster Specification (work in progress)
===

Introduction
---

This document is a work in progress specification of Redis cluster.
The document is split into two parts. The first part documents what is already
implemented in the unstable branch of the Redis code base, the second part
documents what is still to be implemented.

All the parts of this document may be modified in the future as result of a
design change in Redis cluster, but the part not yet implemented is more likely
to change than the part of the specification that is already implemented.

The specification includes everything needed to write a client library,
however client libraries authors should be aware that it is possible for the
specification to change in the future in some detail.

What is Redis cluster
---

Redis cluster is a distributed and fault tolerant implementation of a
subset of the features available in the Redis stand alone server.

In Redis cluster there are no central or proxy nodes, and one of the
major design goals is linear scalability.

Redis cluster sacrifices fault tolerance for consistence, so the system
try to be as consistent as possible while guaranteeing limited resistance
to net splits and node failures (we consider node failures as
special cases of net splits).

Fault tolerance is achieved using two different roles for nodes, that
can be either masters or slaves. Even if nodes are functionally the same
and run the same server implementation, slave nodes are not used if
not to replace lost master nodes. It is actually possible to use slave nodes
for read-only queries when read-after-write consistency is not required.

Implemented subset
---

Redis Cluster implements all the single keys commands available in the
non distributed version of Redis. Commands performing complex multi key
operations like Set type unions or intersections are not implemented, and in
general all the operations where in theory keys are not available in the
same node are not implemented.

In the future there is the possibility to add a new kind of node called a
Computation Node to perform multi-key read only operations in the cluster,
but it is not likely that the Redis cluster itself will be able
to perform complex multi key operations implementing some kind of
transparent way to move keys around.

Redis Cluster does not support multiple databases like the stand alone version
of Redis, there is just database 0, and SELECT is not allowed.

Clients and Servers roles in the Redis cluster protocol
---

In Redis cluster nodes are responsible for holding the data,
and taking the state of the cluster, including mapping keys to the right nodes.
Cluster nodes are also able to auto-discover other nodes, detect non working
nodes, and performing slave nodes election to master when needed.

To perform their tasks all the cluster nodes are connected using a
TCP bus and a binary protocol (the **cluser bus**).
Every node is connected to every other node in the cluster using the cluster
bus. Nodes use a gossip protocol to propagate information about the cluster
in order to discover new nodes, to send ping packets to make sure all the
other nodes are working properly, and to send cluster messages needed to
signal specific conditions. The cluster bus is also used in order to
propagate Pub/Sub messages across the cluster.

Since cluster nodes are not able to proxy requests clients may be redirected
to other nodes using redirections errors `-MOVED` and `-ASK`.
The client is in theory free to send requests to all the nodes in the cluster,
getting redirected if needed, so the client is not required to take the
state of the cluster. However clients that are able to cache the map between
keys and nodes can improve the performance in a sensible way.

Keys distribution model
---

The key space is split into 4096 slots, effectively setting an upper limit
for the cluster size of 4096 nodes (however the suggested max size of
nodes is in the order of a few hundreds).

All the master nodes will handle a percentage of the 4096 hash slots.
When the cluster is **stable**, that means that there is no a cluster
reconfiguration in progress (where hash slots are moved from one node
to another) a single hash slot will be served exactly by a single node
(however the serving node can have one ore more slaves that will replace
it in the case of net splits or failures).

The algorithm used to map keys to hash slots is the following:

    HASH_SLOT = CRC16(key) mod 4096

* Name: XMODEM (also known as ZMODEM or CRC-16/ACORN)
* Width: 16 bit
* Poly: 1021 (That is actually x^16 + x^12 + x^5 + 1)
* Initialization: 0000
* Reflect Input byte: False
* Reflect Output CRC: False
* Xor constant to output CRC: 0000
* Output for "123456789": 31C3

A reference implementation of the CRC16 algorithm used is available in the
Appendix A of this document.

12 out of 16 bit of the output of CRC16 are used.
In our tests CRC16 behaved remarkably well in distributing different kind of
keys evenly across the 4096 slots.

Cluster nodes attributes
---

Every node has an unique name in the cluster. The node name is the
hex representation of a 160 bit random number, obtained the first time a
node is started (usually using /dev/urandom).
The node will save its ID in the node configuration file, and will use the
same ID forever, or at least as long as the node configuration file is not
deleted by the system administrator.

The node ID is used to identify every node across the whole cluster.
It is possible for a give node to change IP and address without any need
to also change the node ID. The cluster is also able to detect the change
in IP/port and reconfigure broadcast the information using the gossip
protocol running over the cluster bus.

Every node has other associated informations that all the other nodes
know:

* The IP address and TCP port where the node is located.
* A set of flags.
* A set of hash slots served by the node.
* Last time we sent a PING packet using the cluster bus.
* Last time we received a PONG packet in reply.
* The number of slaves of this node.
* The master node ID, if this node is a slave (or 0000000... if it is a master).

All this informations are available using the `CLUSTER NODES` command that
can be sent to all the nodes in the cluster, both master and slave nodes.

The following is an example of output of CLUSTER NODES sent to a master
node in a small cluster of three nodes.

```
$ redis-cli cluster nodes
d1861060fe6a534d42d8a19aeb36600e18785e04 :0 myself - 0 1318428930 connected 0-1364
3886e65cc906bfd9b1f7e7bde468726a052d1dae 127.0.0.1:6380 master - 1318428930 1318428931 connected 1365-2729
d289c575dcbc4bdd2931585fd4339089e461a27d 127.0.0.1:6381 master - 1318428931 1318428931 connected 2730-4095
```

In the above listing the different fields are in order: node id, address:port, flags, last ping sent, last pong received, link state, slots.

Nodes handshake
---

Nodes always accept connection in the cluster bus port, and even reply to
pings when received, even if the pinging node is not trusted.
However all the other packets will be discareded by the node if the node
is not considered part of the cluster.

A node will accept another node as part of the cluster only in two ways:

* If a node will present itself with a MEET message. A meet message is exactly
like a PING message, but forces the receiver to accept the node as part of
the cluster. Nodes will send MEET messages to other nodes ONLY IF the system
administrator requests this via the following commnad:

    CLUSTER MEET <ip> <port>

* A node will also register another node as part of the cluster if a node that is already trusted will gossip about this other node. So if A knows B, and B nows C, eventually B will send gossip messages to A about C. When this happens A will register C as part of the network, and will try to connect with C.

This means that as long as we join nodes in any connected graph, they'll eventually form a fully connected graph automatically. This means that basically the cluster is able to auto-discover other nodes, but only if there is a trusted relationship that was forced by the system administrator.

This mechanism makes the cluster more robust but prevents that different Redis clusters will accidentally mix after change of IP addresses or other network related events.

All the nodes actively try to connect to all the other known nodes if the link is down.

MOVED Redirection
---

A Redis client is free to send queries to every node in the cluster, including
slave nodes. The node will analyze the query, and if it is acceptable
(that is, only a single key is mentioned in the query) it will see what
node is responsible for the hash slot where the key belongs.

If the hash slot is served by the node, the query is simply processed, otherwise
the node will check its internal hash slot -> node ID map and will reply
to the client with a MOVED error.

A MOVED error is like the following:

    GET x
    -MOVED 3999 127.0.0.1:6381

The error includes the hash slot of the key (3999) and the ip:port of the
instance that can serve the query. The client need to reissue the query
to the specified ip address and port. Note that even if the client waits
a long time before reissuing the query, and in the meantime the cluster
configuration changed, the destination node will reply again with a MOVED
error if the hash slot 3999 is now served by another node.

So while from the point of view of the cluster nodes are identified by
IDs we try to simply our interface with the client just exposing a map
between hash slots and Redis nodes identified by ip:port pairs.

The client is not required to, but should try to memorize that hash slot
3999 is served by 127.0.0.1:6381. This way once a new command needs to
be issued it can compute the hash slot of the target key and pick the
right node with higher chances.

Note that when the Cluster is stable, eventually all the clients will obtain
a map of hash slots -> nodes, making the cluster efficient, with clients
directly addressing the right nodes without redirections nor proxies or
other single point of failure entities.

A client should be also able to handle -ASK redirections that are described
later in this document.

Cluster live reconfiguration
---

Redis cluster supports the ability to add and remove nodes while the cluster
is running. Actually adding or removing a node is abstracted into the same
operation, that is, moving an hash slot from a node to another.

* To add a new node to the cluster an empty node is added to the cluster and some hash slot is moved from existing nodes to the new node.
* To remove a node from the cluster the hash slots assigned to that node are moved to other existing nodes.

So the core of the implementation is the ability to move slots around.
Actually from a practical point of view an hash slot is just a set of keys, so
what Redis cluster really does during *resharding* is to move keys from
an instance to another instance.

To understand how this works we need to show the `CLUSTER` subcommands
that are used to manipulate the slots translation table in a Redis cluster node.

The following subcommands are available:

* CLUSTER ADDSLOTS <slot1> [slot2] ... [slotN]
* CLUSTER DELSLOTS <slot1> [slot2] ... [slotN]
* CLUSTER SETSLOT <slot> NODE <node>
* CLUSTER SETSLOT <slot> MIGRATING <node>
* CLUSTER SETSLOT <slot> IMPORTING <node>

The first two commands, ADDSLOTS and DELSLOTS, are simply used to assign
(or remove) slots to a Redis node. After the hash slots are assigned they
will propagate across all the cluster using the gossip protocol.
The ADDSLOTS command is usually used when a new cluster is configured
from scratch to assign slots to all the nodes in a fast way.

The SETSLOT subcommand is used to assign a slot to a specific node ID if
the NODE form is used. Otherwise the slot can be set in the two special
states MIGRATING and IMPORTING:

* When a slot is set as MIGRATING, the node will accept all the requests
for queries that are about this hash slot, but only if the key in question
exists, otherwise the query is forwarded using a -ASK redirection to the
node that is target of the migration.
* When a slot is set as IMPORTING, the node will accept all the requests
for queries that are about this hash slot, but only if the request is
preceded by an ASKING command. Otherwise if not ASKING command was given
by the client, the query is redirected to the real hash slot owner via
a -MOVED redirection error.

At first this may appear strange, but now we'll make it more clear.
Assume that we have two Redis nodes, called A and B.
We want to move hash slot 8 from A to B, so we issue commands like this:

* We send B: CLUSTER SETSLOT 8 IMPORTING A
* We send A: CLUSTER SETSLOT 8 MIGRATING B

All the other nodes will continue to point clients to node "A" every time
they are queried with a key that belongs to hash slot 8, so what happens
is that:

* All the queries about already existing keys are processed by "A".
* All the queries about non existing keys in A are processed by "B".

This way we no longer create new keys in "A".
In the meantime, a special client that is called `redis-trib` and is
the Redis cluster configuration utility will make sure to migrate existing
keys from A to B. This is performed using the following command:

    CLUSTER GETKEYSINSLOT <slot> <count>

the above command will return `count` keys in the specified hash slot.
For every key returned, redis-trib sends node A a `MIGRATE` command, that
will migrate the specified key from A to B in an atomic way (both instances
are locked for the time needed to migrate a key so there are no race
conditions). This is how MIGRATE works:

    MIGRATE <target host> <target port> <key> <target database id> <timeout>

MIGRATE will connect to the target instance, send a serialized version of
the key, and once an OK code is received will delete the old key from its own
dataset. So from the point of view of an external client a key either exists
in A or B in a given time.

In Redis cluster there is no need to specify a database other than 0, but
MIGRATE can be used for other tasks as well not involving Redis cluster so
it is a general enough command.
MIGRATE is optimized to be as fast as possible even when moving complex
keys such as long lists, but of course in Redis cluster reconfiguring the
cluster where big keys are present is not considered a wise procedure if
there are latency constraints in the application using the database.

ASK redirection
---

In the previous section we briefly talked about ASK redirection, why we
can't simply use the MOVED redirection? Because while MOVED means that
we think the hash slot is permanently served by a different node and the
next queries should be tried against the specified node, ASK means to
only ask the next query to the specified node.

This is needed because the next query about hash slot 8 can be about the
key that is still in A, so we always want that the client will try A and
then B if needed. Since this happens only for one hash slot out of 4096
available the performance hit on the cluster is acceptable.

However we need to force that client behavior, so in order to make sure
that clients will only try slot B after A was tried, node B will only
accept queries of a slot that is set as IMPORTING if the client send the
ASKING command before sending the query.

Basically the ASKING command set a one-time flag on the client that forces
a node to serve a query about an IMPORTING slot.

So the full semantics of the ASK redirection is the following, from the
point of view of the client.

* If ASK redirection is received send only the query in object to the specified node.
* Start the query with the ASKING command.
* Don't update local client tables to map hash slot 8 to B for now.

Once the hash slot 8 migration is completed, A will send a MOVED message and
the client may permanently map hash slot 8 to the new ip:port pair.
Note that however if a buggy client will perform the map earlier this is not
a problem since it will not send the ASKING command before the query and B
will redirect the client to A using a MOVED redirection error.

Clients implementations hints
---

* TODO Pipelining: use MULTI/EXEC for pipelining.
* TODO Persistent connections to nodes.
* TODO hash slot guessing algorithm.

Fault Tolerance
===

Node failure detection
---

Failure detection is implemented in the following way:

* A node marks another node setting the PFAIL flag (possible failure) if the node is not responding to our PING requests for a given time.
* Nodes broadcast information about other nodes (three random nodes taken at random) when pinging other nodes. The gossip section contains information about other nodes flags.
* If we have a node marked as PFAIL, and we receive a gossip message where another nodes also think the same node is PFAIL, we mark it as FAIL (failure).
* Once a node marks another node as FAIL as result of a PFAIL confirmed by another node, a message is send to all the other nodes to force all the reachable nodes in the cluster to set the specified not as FAIL.

So basically a node is not able to mark another node as failing without external acknowledge.

(still to implement:)
Once a node is marked as failing, any other node receiving a PING or
connection attempt from this node will send back a "MARK AS FAIL" message
in reply that will force the receiving node to set itself as failing.

Cluster state detection (only partially implemented)
---

Every cluster node scan the list of nodes every time a configuration change
happens in the cluster (this can be an update to an hash slot, or simply
a node that is now in a failure state).

Once the configuration is processed the node enters one of the following states:

* FAIL: the cluster can't work. When the node is in this state it will not serve queries at all and will return an error for every query. This state is entered when the node detects that the current nodes are not able to serve all the 4096 slots.
* OK: the cluster can work as all the 4096 slots are served by nodes that are not flagged as FAIL.

This means that the Redis Cluster is designed to stop accepting queries once even a subset of the hash slots are not available. However there is a portion of time in which an hash slot can't be accessed correctly since the associated node is experiencing problems, but the node is still not marked as failing.
In this range of time the cluster will only accept queries about a subset of the 4096 hash slots.

Since Redis cluster does not support MULTI/EXEC transactions the application
developer should make sure the application can recover from only a subset of queries being accepted by the cluster.

Slave election (not implemented)
---

Every master can have any number of slaves (including zero).
Slaves are responsible of electing themselves to masters when a given
master fails. For instance we may have node A1, A2, A3, where A1 is the
master an A2 and A3 are two slaves.

If A1 is failing in some way and no longer replies to pings, other nodes
will end marking it as failing using the gossip protocol. When this happens
its **first slave** will try to perform the election.

The concept of first slave is very simple. Of all the slaves of a master
the first slave is the one that has the smallest node ID, sorting node IDs
lexicographically. If the first slave is also marked as failing, the next
slave is in charge of performing the election and so forth.

So after a configuration update every slave checks if it is the first slave
of the failing master. In the case it is it changes its state to master
and broadcasts a message to all the other nodes to update the configuration.

Protection mode (not implemented)
---

After a net split resulting into a few isolated nodes, this nodes will
end thinking all the other nodes are failing. In the process they may try
to start a slave election or some other action to modify the cluster
configuration. In order to avoid this problem, nodes seeing a majority of
other nodes in PFAIL or FAIL state for a long enough time should enter
a protection mode that will prevent them from taking actions.

The protection mode is cleared once the cluster state is OK again.

Majority of masters rule (not implemented)
---

As a result of a net split it is possible that two or more partitions are
independently able to serve all the hash slots.
Since Redis Cluster try to be consistent this is not what we want, and
a net split should always produce zero or one single partition able to
operate.

In order to enforce this rule nodes into a partition should only try to
serve queries if they have the **majority of the original master nodes**.

Publish/Subscribe (implemented, but to refine)
===

In a Redis Cluster clients can subscribe to every node, and can also
publish to every other node. The cluster will make sure that publish
messages are forwarded as needed.

The current implementation will simply broadcast all the publish messages
to all the other nodes, but at some point this will be optimized either
using bloom filters or other algorithms.

Appendix A: CRC16 reference implementation in ANSI C
---

```
/*      
 * Copyright 2001-2010 Georges Menie (www.menie.org)
 * Copyright 2010 Salvatore Sanfilippo (adapted to Redis coding style)
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of California, Berkeley nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* CRC16 implementation acording to CCITT standards.
 *
 * Note by @antirez: this is actually the XMODEM CRC 16 algorithm, using the
 * following parameters:
 *
 * Name                       : "XMODEM", also known as "ZMODEM", "CRC-16/ACORN"
 * Width                      : 16 bit
 * Poly                       : 1021 (That is actually x^16 + x^12 + x^5 + 1)
 * Initialization             : 0000
 * Reflect Input byte         : False
 * Reflect Output CRC         : False
 * Xor constant to output CRC : 0000
 * Output for "123456789"     : 31C3
 */

static const uint16_t crc16tab[256]= {
    0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
    0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
    0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
    0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
    0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
    0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
    0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
    0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
    0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
    0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
    0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
    0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
    0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
    0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
    0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
    0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
    0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
    0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
    0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
    0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
    0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
    0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
    0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
    0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
    0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
    0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
    0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
    0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
    0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
    0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
    0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
    0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
};
  
uint16_t crc16(const char *buf, int len) {
    int counter;
    uint16_t crc = 0;
    for (counter = 0; counter < len; counter++)
            crc = (crc<<8) ^ crc16tab[((crc>>8) ^ *buf++)&0x00FF];
    return crc;
}
```
