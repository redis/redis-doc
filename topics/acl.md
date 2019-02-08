# ACL

Redis ACLs, short for Access Control List, is the feature that allows certain
connections to be limited in the commands that can be executed and the keys
that can be accessed. The way it works is that, after connecting, a client
requires to authenticate providing a username and one valid password: if
the authentication stage succeeded, the connection is associated with a given
user and the limits the user has. Redis can be configured so that new
connections are already authenticated with a "default" user (this is the
default configuration), so configuring the default user has, as a side effect,
the ability to provide only a specific subset of functionalities to connections
that are not authenticated.

In the default configuration, Redis 6, the first version to have ACLs, works
exactly like older versions of Redis, that is, every new connection is
capable of calling every possible command and accessing every key, so the
new feature is backward compatible with old clients and applications. Moreover
the old way to configure a password, using the **requirepass** configuration
directive, still works as expected, however now what it does is just to
set a password for the default user.

Before using ACLs you may want to ask yourself what's the goal you want to
accomplish by implementing this layer of protection. Normally there are
two main goals that are well served by ACLs:

1. You want to improve security by restricting the access to commands and keys, so that unstrusted clients have no access and less trusted clients are not able to do bad things.
2. You want to improve operational safety, so that processes or humans accessing Redis are not allowed, because of software errors or mistakes, to damage the data or the configuration. For instance there is no reason for a worker that fetches delayed jobs from Redis to be able to call the `FLUSHALL` command.

TODO list:

* Make sure to specify that modules commands are ignored when adding/removing categories.
* Document cost of keys matching with some benchmark.
* Document how +@all also includes module commands and every future command.
* Document how ACL SAVE is not included in CONFIG REWRITE.
* Document backward compatibility with requirepass and single argument AUTH.
