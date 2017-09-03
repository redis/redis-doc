Redis Encryption
===

The idea of adding SSL support to Redis was proposed many times, however
currently we believe that given the small percentage of users requiring
SSL support, and the fact that each scenario tends to be different, using
a different "tunneling" strategy can be better. We may change the idea in the
future, but currently a good solution that may be suitable for many use cases
is to use the following project:

* [Spiped](http://www.tarsnap.com/spiped.html) is a utility for creating symmetrically encrypted and authenticated pipes between socket addresses, so that one may connect to one address (e.g., a UNIX socket on localhost) and transparently have a connection established to another address (e.g., a UNIX socket on a different system).

The software is written in a similar spirit to Redis itself, it is a self-contained 4000 lines of C code utility that does a single thing well.
