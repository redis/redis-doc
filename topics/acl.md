# ACL

The Redis ACL, short for Access Control List, is the feature that allows certain
connections to be limited in terms of the commands that can be executed and the
keys that can be accessed. The way it works is that, after connecting, a client
is required to authenticate providing a username and a valid password: if
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

The command above reports the list of users in the same format that is
used in the Redis configuration files, by translating the current ACLs set
for the users back into their description.

The first two words in each line are "user" followed by the username. The
next words are ACL rules that describe different things. We'll show in
details how the rules work, but for now it is enough to say that the default
user is configured to be active (on), to require no password (nopass), to
access every possible key (`~*`) and be able to call every possible command
(+@all).

Also, in the special case of the default user, having the *nopass* rule means
that new connections are automatically authenticated with the default user
without any explicit `AUTH` call needed.

## ACL rules

The following is the list of the valid ACL rules. Certain rules are just
single words that are used in order to activate or remove a flag, or to
perform a given change to the user ACL. Other rules are char prefixes that
are concatenated with command or cagetories names, or key patterns, and
so forth.

Enable and disallow users:

* `on`: Enable the user: it is possible to authenticate as this user.
* `off`: Disable the user: it's no longer possible to authenticate with this user, however the already authenticated connections will still work. Note that if the default user is flagged as *off*, new connections will start not authenticated and will require the user to send `AUTH` or `HELLO` with the AUTH option in order to authenticate in some way, regardless of the default user configuration.

Allow and disallow commands:

* `+<command>`: Add the command to the list of commands the user can call.
* `-<command>`: Remove the command to the list of commands the user can call.
* `+@<category>`: Add all the commands in such category to be called by the user, with valid categories being like @admin, @set, @sortedset, ... and so forth, see the full list by calling the `ACL CAT` command. The special category @all means all the commands, both the ones currently present in the server, and the ones that will be loaded in the future via modules.
* `-@<category>`: Like `+@<category>` but removes the commands from the list of commands the client can call.
* `+<command>|subcommand`: Allow a specific subcommand of an otherwise disabled command. Note that this form is not allowed as negative like `-DEBUG|SEGFAULT`, but only additive starting with "+". This ACL will cause an error if the command is already active as a whole.
* `allcommands`: Alias for +@all. Note that it implies the ability to execute all the future commands loaded via the modules system.
* `nocommands`: Alias for -@all.

Allow and disallow certain keys:

`~<pattern>`: Add a pattern of keys that can be mentioned as part of commands. For instance `~*` allows all the keys. The pattern is a glob-style pattern like the one of KEYS.  It is possible to specify multiple patterns.
* `allkeys`: Alias for `~*`.
* `resetkeys`: Flush the list of allowed keys patterns. For instance the ACL `~foo:* ~bar:* resetkeys ~objects:*`, will result in the client only be able to access keys matching the pattern `objects:*`.

Configure valid passwords for the user:

* `><password>`: Add this passowrd to the list of valid passwords for the user. For example `>mypass` will add "mypass" to the list of valid passwords.  This directive clears the *nopass* flag (see later). Every user can have any number of passwords.
* `<<password>`: Remove this password from the list of valid passwords. Emits an error in case the password you are trying to remove is actually not set.
* `nopass`: All the set passwords of the user are removed, and the user is flagged as requiring no password: it means that every password will work against this user. If this directive is used for the default user, every new connection will be immediately authenticated with the default user without any explicit AUTH command required. Note that the *resetpass* directive will clear this condition.
* `resetpass`: Flush the list of allowed passwords. Moreover removes the *nopass* status. After *resetpass* the user has no associated passwords and there is no way to authenticate without adding some password (or setting it as *nopass* later).

*Note: an use that is not flagged with nopass, and has no list of valid passwords, is effectively impossible to use, because there will be no way to log in as such user.*

Reset the user:

* `reset` Performs the following actions: resetpass, resetkeys, off, -@all. The user returns to the same state it has immediately after its creation.

## Creating and editing users ACLs with the ACL SETUSER command

Users can be created and modified in two main ways:

1. Using the ACL command and its `ACL SETUSER` subcommand.
2. Modifying the server configuration, where users can be defined, and restarting the server, or if we are using an *external ACL file*, just issuing `ACL LOAD`.

In this section we'll learn how to define users using the `ACL` command.
With such knowledge it will be trivial to do the same things via the
configuration files. Defining users in the configuration deserves its own
section and will be discussed later separately.

To start let's try the simplest `ACL SETUSER` command call:

    > ACL SETUSER alice
    OK

The `SETUSER` command takes the username and a list of ACL rules to apply
to the user. However in the above example I did not specify any rule at all.
This will just create the user if it did not exist, using the default
attributes of a just creates uses. If the user already exist, the command
above will do nothing at all.

Let's check what is the default user status:

    > ACL LIST
    1) "user alice off -@all"
    2) "user default on nopass ~* +@all"

The just created user "alice" is:

* In off status, that is, it's disabled. AUTH will not work.
* Cannot access any command. Note that the user is created by default without the ability to access any command, so the `-@all` in the output above could be omitted, however `ACL LIST` attempts to be explicit rather than implicit.
* Finally there are no key patterns that the user can access.
* The user also has no passwords set.

Such user is completely useless. Let's try to define the user so that
it is active, has a password, and can access with only the `GET` command
to key names starting with the string "cached:".

    > ACL SETUSER alice on >p1pp0 ~cached:* +get
    OK

Now the user can do something, but will refuse to do other things:

    > AUTH alice p1pp0
    OK
    > GET foo
    (error) NOPERM this user has no permissions to access one of the keys used as arguments
    > GET cached:1234
    (nil)
    > SET cached:1234 zap
    (error) NOPERM this user has no permissions to run the 'set' command or its subcommnad

Things are working as expected. In order to inspect the configuration of the
user alice (remember that user names are case sensitive), it is possible to
use an alternative to `ACL LIST` which is designed to be more suitable for
computers to read, while `ACL LIST` is more biased towards humans.

    > ACL GETUSER alice
    1) "flags"
    2) 1) "on"
    3) "passwords"
    4) 1) "p1pp0"
    5) "commands"
    6) "-@all +get"
    7) "keys"
    8) 1) "cached:*"

The `ACL GETUSER` returns a field-value array describing the user in more parsable terms. The output includes the set of flags, a list of key patterns, passwords and so forth. The output is probably more readalbe if we use RESP3, so that it is returned as as map reply:

    > ACL GETUSER alice
    1# "flags" => 1~ "on"
    2# "passwords" => 1) "p1pp0"
    3# "commands" => "-@all +get"
    4# "keys" => 1) "cached:*"

*Note: from now on we'll continue using the Redis default protocol, version 2, because it will take some time for the community to switch to the new one.*

Using another `ACL SETUSER` command (from a different user, because alice cannot run the `ACL` command) we can add multiple patterns to the user:

    > ACL SETUSER alice ~objects:* ~items:* ~public:*
    OK
    > ACL LIST
    1) "user alice on >p1pp0 ~cached:* ~objects:* ~items:* ~public:* -@all +get"
    2) "user default on nopass ~* +@all"

The user representation in memory is now as we expect it to be.

## What happens calling ACL SETUSER multiple times

It is very important to understand what happens when ACL SETUSER is called
multiple times. What is critical to know is that every `SETUSER` call will
NOT reset the user, but will just apply the ACL rules to the existing user.
The user is reset only if it was not known before: in that case a brand new
user is created with zeroed-ACLs, that is, the user cannot do anything, is
disabled, has no passwords and so forth: for safety this is the best default.

However later calls will just modify the user incrementally so for instance
the following sequence:

    > ACL SETUSER myuser +set
    OK
    > ACL SETUSER myuser +get
    OK

Will result into myuser to be able to call both `GET` and `SET`:

    > ACL LIST
    1) "user default on nopass ~* +@all"
    2) "user myuser off -@all +set +get"

## Playings with command categories

Setting users ACLs by specifying all the commands one after the other is
really annoying, so instead we do things like that:

    > ACL SETUSER antirez on +@all -@dangerous >somepassword ~*

By saying +@all and -@dangerous we included all the commands and later removed
all the commands that are tagged as dangerous inside the Redis command table.
Please note that command categories **never include modules commnads** with
the exception of +@all. If you say +@all all the commands can be executed by
the user, even future commands loaded via the modules system. However if you
use the ACL rule +@readonly or any other, the modules commands are always
excluded. This is very important because you should just trust the Redis
internal command table for sanity. Moudles my expose dangerous things and in
the case of an ACL that is just additive, that is, in the form of `+@all -...`
You should be absolutely sure that you'll never include what you did not mean
to.

However to remember that categories are defined, and what commands each
category exactly includes, is impossible and would be super boring, so the
Redis `ACL` command exports the `CAT` subcommand that can be used in two forms:

    ACL CAT -- Will just list all the categories available
    ACL CAT <category-name> -- Will list all the commands inside the category

Examples:

     > ACL CAT
     1) "keyspace"
     2) "read"
     3) "write"
     4) "set"
     5) "sortedset"
     6) "list"
     7) "hash"
     8) "string"
     9) "bitmap"
    10) "hyperloglog"
    11) "geo"
    12) "stream"
    13) "pubsub"
    14) "admin"
    15) "fast"
    16) "slow"
    17) "blocking"
    18) "dangerous"
    19) "connection"
    20) "transaction"
    21) "scripting"

As you can see so far there are 21 distinct categories. Now let's check what
command is part of the *geo* category:

    > ACL CAT geo
    1) "geohash"
    2) "georadius_ro"
    3) "georadiusbymember"
    4) "geopos"
    5) "geoadd"
    6) "georadiusbymember_ro"
    7) "geodist"
    8) "georadius"

Note that commands may be part of multiple categories, so for instance an
ACL rule like `+@geo -@readonly` will result in certain geo commands to be
excluded because they are readonly commands.

## +@all VS -@all

## TODO list for this document

* Make sure to specify that modules commands are ignored when adding/removing categories.
* Document cost of keys matching with some benchmark.
* Document how +@all also includes module commands and every future command.
* Document how ACL SAVE is not included in CONFIG REWRITE.
* Document backward compatibility with requirepass and single argument AUTH.
