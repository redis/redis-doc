# ACL

The Redis ACL, short for Access Control List, is the feature that allows certain
connections to be limited in the commands that can be executed and the keys
that can be accessed. The way it works is that, after connecting, a client
requires to authenticate providing a username and a valid password: if
the authentication stage succeeded, the connection is associated with a given
user and the limits the user has. Redis can be configured so that new
connections are already authenticated with a "default" user (this is the
default configuration), so configuring the default user has, as a side effect,
the ability to provide only a specific subset of functionalities to connections
that are not explicitly authenticated.

In the default configuration, Redis 6 (the first version to have ACLs) works
exactly like older versions of Redis, that is, every new connection is
capable of calling every possible command and accessing every key, so the
ACL feature is backward compatible with old clients and applications. Also
the old way to configure a password, using the **requirepass** configuration
directive, still works as expected, but now what it does is just to
set a password for the default user.

The Redis `AUTH` command was extended in Redis 6, so now it is possible to
use it in the two-arguments form:

    AUTH <username> <password>

When it is used according to the old form, that is:

    AUTH <password>

What happens is that the username used to authenticate is "default", so
just specifying the password implies that we want to authenticate against
the default user. This provides perfect backward compatibility with the past.

## When ACLs are useful

Before using ACLs you may want to ask yourself what's the goal you want to
accomplish by implementing this layer of protection. Normally there are
two main goals that are well served by ACLs:

1. You want to improve security by restricting the access to commands and keys, so that untrusted clients have no access and trusted clients have just the minimum access level to the database in order to perform the work needed. For instance certain clients may just be able to execute read only commands.
2. You want to improve operational safety, so that processes or humans accessing Redis are not allowed, because of software errors or manual mistakes, to damage the data or the configuration. For instance there is no reason for a worker that fetches delayed jobs from Redis to be able to call the `FLUSHALL` command.

Another typical usage of ACLs is related to managed Redis instances. Redis is
often provided as a managed service both by internal company teams that handle
the Redis infrastructure for the other internal customers they have, or is
provided in a software-as-a-service setup by cloud providers. In both such
setups we want to be sure that configuration commands are excluded for the
customers. The way this was accomplished in the past, via command renaming, was
a trick that allowed us to survive without ACLs for a long time, but is not
ideal.

## Configuring ACLs using the ACL command

ACLs are defined using a DSL (domain specific language) that describes what
a given user is able to do or not. Such rules are always implemented from the
first to the last, left-to-right, because sometimes the order of the rules is
important to understand what the user is really able to do.

By default there is a single user defined, that is called *default*. We
can use the `ACL LIST` command in order to check the currently active ACLs
and verify what the configuration of a freshly stared and unconfigured Redis
instance is:

    > ACL LIST
    1) "user default on nopass ~* +@all"

This command is able to report the list of users in the same format that is
used in the Redis configuration files, by translating the current ACLs set
for the users back into their description.

The first two words in each line are "user" followed by the username. The
following words are ACL rules that describe different things. We'll show in
details how the rules work, but for now it is enough to say that the default
user is configured to be active (on), to require no password (nopass), to
access every possible key (`~*`) and be able to call every possible command
(+@all).

Also, in the special case of the default user, having the *nopass* rule means
that new connections are automatically authenticated with the default user
without any explicit `AUTH` call needed.

TODO list:

* Make sure to specify that modules commands are ignored when adding/removing categories.
* Document cost of keys matching with some benchmark.
* Document how +@all also includes module commands and every future command.
* Document how ACL SAVE is not included in CONFIG REWRITE.
* Document backward compatibility with requirepass and single argument AUTH.
