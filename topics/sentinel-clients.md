**WARNING:** This document is a draft and the guidelines that it contains may change in the future as the Sentinel project evolves.

Guidelines for Redis clients with support for Redis Sentinel
===

Redis Sentinel is a monitoring solution for Redis instances that handles different aspects of monitoring, including notification of events, automatic failover. 
Sentinel can also play the role of configuration source for Redis clients. This document is targetted at Redis clients developers that want to support Sentinel in their clients implementation with the following goals:

* Automatic configuration of clients via Sentinel.
* Improved reliability of Redis Sentinel automatic fail over, because of Sentinel-aware clients that will automatically reconnect to the new master.

For details about how Redis Sentinel works, please check the [Redis Documentation](/topics/sentinel) itself, as this document only contains informations needed for Redis client developers.

Redis service discovery via Sentinel
===

Redis Sentinel identify every master with a name like "stats" or "cache".
However the address of the Redis master that is used for a specific purpose inside a network may change after events like an automatic failover, a manually triggered failover (for instance in order to upgrade a Redis instance), and other reasons.

Normally Redis clients have some kind of hard-coded configuraiton that specifies the address of a Redis master instance within a network as IP address and port number. However if the master address changes, manual intervention in every client is needed.

A Redis client supporting Sentinel can automatically discover the address of a Redis master from the master name using Redis Sentinel. So instead of an hard coded IP address and port, a client supporting Sentinel should optionally be able to take as input:

* A list of ip:port pairs pointing to known Sentinel instances.
* The name of the service, like "cache" or "timelines".

This is the procedure a client should follow in order to obtain the master address starting from the list of Sentinels and the service name.

Step 1: connecting to the first Sentinel
---

The client should iterate the list of Sentinel addresses. For every address it should try to connect to the Sentinel, using a short timeout. On errors or timeouts the next Sentinel address should be tried.

If all the Sentinel addresses were tried without success, an error should be returned to the client.

Step 2: ask for master address
---

Once a connection with a Sentinel is established, the client should retry to execute the following command on the Sentinel:

    SENTINEL get-master-addr-by-name master-name

Where *master-name* should be replaced with the actual service name specified by the user.

The result from this call can be one of the following three replies:

* An ip:port pair.
* A null reply.
* An `-IDONTKNOW` error.

If an ip:port pair is received, this address should be used to connect to the Redis master. Otherwise if a null reply or `-IDONTKNOW` reply is received, the client should try the next Sentinel in the list.

Step 3: give priority to the replying Sentinel
---

When a correct ip:port pair is received, the replying Sentinel address should be put at the top of the list of Sentinel addresses, so that the next time we'll try the responding Sentinel before any other.

IMPORTANT: The result of this procedure should not be cached by the Redis client. Every time a new connection should be performed to a master the full resolving procedure should be used instead.

Handling reconnections
===

Once the service name is resoled into the master address and a connection is established with the Redis master instance, every time a reconnection is needed, the client should resolve again the address using Sentinels. For instance:

* If the client reconnects after a timeout or socket error.
* If the client reconnects because it was explicitly closed or reconnected in any way by the user.

In the above cases and any other the client should resolve the master address again.

Connection pools
===

For clients implementing connection pools, on reconnection of a single connection, the Sentinel should be contacted again, and in case of a master address change all the existing connections should be closed and connected to the new address.

Error reporting
===

The client should correctly return the information to the user in case of errors. Specifically:

* If no Sentinel can be contacted (so that the client was never able to get the reply to `SENTINEL get-master-addr-by-name`), an error that clearly states that Redis Sentinel is unreachable should be returned.
* If all the Sentinels in the pool replied with a null reply, the user should be informed with an error that Sentinels don't know this master name.
* If at least one Sentinel replies with `-IDONTKNOW` the client should return an error like: "Redis Sentinel don't know the specified master address." so that the user is informed that the service name is configured in at least a Sentinel instance, but apparently the master was never reached by the Sentinel.

Sentinels list automatic refresh
===

Optionally once a successful reply to `get-master-addr-by-name` is received, a client may update its internal list of Sentinel nodes following this procedure:

* Obtain a list of other Sentinels for this master using the command `SENTINEL sentinels <master-name>`.
* Add every ip:port pair not already existing in our list at the end of the list.

It is not needed for a client to be able to make the list persistent updating its own configuration. The ability to upgrade the in-memory representation of the list of Sentinels can be already useful to improve reliability.

Additional information
===

For additional information or to discuss specific aspects of this guidelines, please drop a message to the [Redis Google Group](https://groups.google.com/group/redis-db).
