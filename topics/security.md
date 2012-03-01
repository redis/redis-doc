Redis Security
===

This document provides an introduction to the topic of security from the point of
view of Redis: the access control provided by Redis, code security concerns,
attacks that can be triggered from the outside selecting malicious inputs and
other similar topics are covered.

Redis general security model
----

Redis is designed to be accessed by trusted clients inside trusted environments.
This means that usually it is not a good idea to expose the Redis instance
directly on the internet, and in general in an environment where untrusted
clients can directly access the Redis TCP port or UNIX socket.

For instance in the common context of a web application implemented using Redis
as a database, cache, or messaging system, the clients inside the front-end
(web side) of the application will query Redis to generate the pages or
to perform the operations requested or triggered by the web application user.

In this case the web application mediates the access between the Redis and
untrusted clients (the user browsers accessing the web application).

This is a specific example, but in general, untrusted access to Redis should
be always mediated by a layer implementing ACLs, validating the user input,
and deciding what operations to perform against the Redis instance.

In general Redis is not optimized for maximum security but for maximum
performances and simplicity.

Network security
---

Accessing to the Redis port should be denied to everybody but trusted clients
in the network, so the servers running Redis should either be directly accessible
only by the computers implementing the application using Redis.

In the common case of a single computer directly exposed on the internet such
as a virtualized Linux instance (Linode, EC2, ...) the Redis port should be
firewalled to prevent access from the outside. Clients will still be able to
access Redis using the loopback interface.

Note that it is possible to bind Redis to a single interface adding a line
like the following to the **redis.conf** file:

    bind 127.0.0.1

Failing to protect the Redis port from the outside can have a big security
impact because of the nature of Redis. For instance a single **FLUSHALL** command
can be used by an external attack to delete the whole data set with a single
command.

Authentication feature
---

While Redis does not tries to implement Access Control, nevertheless it provides
a tiny later of authentication that is optionally turned on editing the
redis.conf file.

When the authorization layer is enabled Redis will refuse any query by
unauthenticated clients. A client can authenticate itself by sending the
**AUTH** command followed by the password.

The password is set by the system administrator in clear inside the
redis.conf file. It should be long enough in order to prevent brute force
attacks for two reasons:

* Redis is very fast at serving queries. Many passwords per second can be tested by an external client.
* The Redis password is stored inside the redis.conf and inside client configuration, so does not need to be remembered by the system administrator, thus it can be very long.

The goal of the authentication layer is to optionally provide a layer of
redundancy. Should firewalling or any other system implemented to protect Redis
from external attackers fail for some reason an external client will still not
be able to access the Redis instance.

The AUTH command is sent unencrypted similarly to every other Redis command, so it does not protect in the case of an attacker that has enough access to the network to perform eavesdropping.

Data encryption support
---

Redis does not support encryption, so in order to implement setups where
trusted parties can access a Redis instance over the internet or other
untrusted networks an additional layer of protection should be implemented,
like for instance an SSL proxy.

Disabling of specific commands
---

It is possible to disable commands in Redis, or to rename them into an unguessable
name, so that normal clients are limited to a specified set of commands.

For instance a virtualized servers provider may provide a managed Redis instance
service. However in this context normal users should probably not be able to
call the Redis **CONFIG** command to alter the configuration of the instance,
but the systems that provide and remove instances should be able to do so.

In this case it is possible to use a feature that makes it possible to either
rename or completely shadow commands from the command table. This feature
is available as a statement that can be used inside the redis.conf configuration
file. The following is an example:

    rename-command CONFIG b840fc02d524045429941cc15f59e41cb7be6c52

In the above example the **CONFIG** command was renamed into an unguessable name.
It is also possible to completely disable it (or any other command) renaming it
to the empty string, like in the following example:

    rename-command CONFIG ""

Attacks triggered by carefully selected inputs by external clients
---

There is a class of attacks that an attacker can trigger from the outside even
without external access to the instance. An example of such attackers are
the ability to insert data into Redis that triggers pathological (worst case)
algorithm complexity on data structures implemented inside Redis internals.

For instance an attacker could supply, via a web form, a set of strings that
is known to hash to the same bucket into an hash table in order to turn the
O(1) expected time (the average time) to the O(N) worst case, consuming more
CPU than expected, and ultimately causing a Denial of Service.

To prevent this specific attack Redis uses a per-execution pseudo random
seed to the hash function.

Redis also uses the qsort algorithm in order to implement the SORT command,
it is possible by carefully selecting the right set of inputs to trigger an
quadratic worst-case behavior of qsort since currently the algorithm is not
randomized.

String escaping and NoSQL injection
---

In the Redis protocol there is no concept of string escaping, so code injection
is not possible under normal circumstances using a normal client library.
All the protocol uses prefixed-length strings and is completely binary safe.

Lua scripts executed by the **EVAL** and **EVALSHA** commands also follow the
same rules, thus those commands are also safe.

Applications must not compose the body of a Lua script using strings obtained from 
untrusted sources. Doing so would make the application vulnerable to code injection. 

Applications should instead bind input parameters either as keys or as arguments. 
Within the Lua script, these input parameters will be available via the 
special global variables **KEYS[1]** through **KEYS[n]** or **ARGV[1]** 
through **ARGV[N]**. For more information, refer to the documentation of **EVAL**.

Code security
---

In a classical Redis setup clients are allowed to have full access to the command
set, however accessing the instance should never result into the ability to
control the system where Redis is running.

Redis internally uses all the well known practices for writing secure code, to
prevent buffer overflows, format bugs and other memory corruption issues.
However the ability to control the server configuration using the **CONFIG**
command makes the client able to change the working dir of the program and
the name of the dump file. This makes clients able to write RDB Redis files
at random paths, that is a security issue that may easily lead to the ability
to run untrusted code as the same user as Redis is running.

Redis does not requires root privileges in order to run, it is recommended to
run it as an unprivileged *redis* user that is only used for this scope.
The Redis authors are currently investigating the possibility of adding a new
configuration parameter to prevent **CONFIG SET/GET dir** and other run-time
configuration directives similar to this in order to prevent clients from
forcing the server to write Redis dump files at arbitrary locations.
