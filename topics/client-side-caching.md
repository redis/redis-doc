# Redis server-assisted client side caching

Client side caching is a technique used in order to create high performance
services. It exploits the available memory in the application servers, that
usually are distinct computers compared to the database nodes, in order to
store some subset of the database information directly in the application side.

Normally when some data is required, the application servers will ask the
database about such information, like in the following picture:


    +-------------+                                +----------+
    |             | ------- GET user:1234 -------> |          |
    | Application |                                | Database |
    |             | <---- username = Alice ------- |          |
    +-------------+                                +----------+

When client side caching is used, the application will store the reply of
popular queries directily inside the application memory, so that it can
reuse such replies later, without contacting the database again.

    +-------------+                                +----------+
    |             |                                |          |
    | Application |       ( No chat needed )       | Database |
    |             |                                |          |
    +-------------+                                +----------+
    | Local cache |
    |             |
    | user:1234 = |
    | username    |
    | Alice       |
    +-------------+

While the application memory used for the local cache may not be very big,
the time needed in order to access the local computer memory is orders of
magnitude smaller compared to asking a networked service like a database.
Since often the same small percentage of data are accessed very frequently
this pattern can greatly reduce the latency for the application to get data
and, at the same time, the load in the database side.

## There are only two big problems in computer science...

A problem with the above pattern is how to invalidate the information that
the application is holding, in order to avoid presenting to the user stale
data. For example after the application above locally cached the user:1234
information, Alice may update her username to Flora. Yet the application
may continue to serve the old username for user 1234.

Sometimes this problem is not a big deal, so the client will just use a
"time to live" for the cached information. Once a given amount of time has
elapsed, the information will no longer be considered valid. More complex
patterns, when using Redis, leverage Pub/Sub messages in order to
send invalidation messages to clients listening. This can be made to work
but is tricky and costly from the point of view of the bandwidth used, because
often such patterns involve sending the invalidation messages to every client
in the application, even if certain clients may not have any copy of the
invalidated data.

Yet many very big applications use client side caching: it is in some way
the next logical strategy, after using a fast store like Redis, in order
to cut on latency and be able to handle more queries per second. Because the
usefulness of such pattern, to make it more accessible could be a real
advantage for Redis users. For this reason Redis 6, currently under
development, already implements server-assisted client side caching. Once
the database is an active part of the protocol, it can remember what
keys a given client requested (if it enabled client side caching in the
connection), and send invalidation messages if such keys gets modified.




