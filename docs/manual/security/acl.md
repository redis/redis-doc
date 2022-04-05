---
title: "ACL"
linkTitle: "ACL"
weight: 1
description: Redis access control list
aliases:
    - /topics/acl
---

The Redis ACL, short for Access Control List, is the feature that allows certain
connections to be limited in terms of the commands that can be executed and the
keys that can be accessed. The way it works is that, after connecting, a client
is required to provide a username and a valid password to authenticate. If authentication succeeded, the connection is associated with a given
user and the limits the user has. Redis can be configured so that new
connections are already authenticated with a "default" user (this is the
default configuration). Configuring the default user has, as a side effect,
the ability to provide only a specific subset of functionalities to connections
that are not explicitly authenticated.

In the default configuration, Redis 6 (the first version to have ACLs) works
exactly like older versions of Redis. Every new connection is
capable of calling every possible command and accessing every key, so the
ACL feature is backward compatible with old clients and applications. Also
the old way to configure a password, using the **requirepass** configuration
directive, still works as expected. However, it now
sets a password for the default user.

The Redis `AUTH` command was extended in Redis 6, so now it is possible to
use it in the two-arguments form:

    AUTH <username> <password>

Here's an example of the old form:

    AUTH <password>

What happens is that the username used to authenticate is "default", so
just specifying the password implies that we want to authenticate against
the default user. This provides backward compatibility.

## When ACLs are useful

Before using ACLs, you may want to ask yourself what's the goal you want to
accomplish by implementing this layer of protection. Normally there are
two main goals that are well served by ACLs:

1. You want to improve security by restricting the access to commands and keys, so that untrusted clients have no access and trusted clients have just the minimum access level to the database in order to perform the work needed. For instance, certain clients may just be able to execute read only commands.
2. You want to improve operational safety, so that processes or humans accessing Redis are not allowed to damage the data or the configuration due to software errors or manual mistakes. For instance, there is no reason for a worker that fetches delayed jobs from Redis to be able to call the `FLUSHALL` command.

Another typical usage of ACLs is related to managed Redis instances. Redis is
often provided as a managed service both by internal company teams that handle
the Redis infrastructure for the other internal customers they have, or is
provided in a software-as-a-service setup by cloud providers. In both 
setups, we want to be sure that configuration commands are excluded for the
customers.

## Configure ACLs with the ACL command

ACLs are defined using a DSL (domain specific language) that describes what
a given user is allowed to do. Such rules are always implemented from the
first to the last, left-to-right, because sometimes the order of the rules is
important to understand what the user is really able to do.

By default there is a single user defined, called *default*. We
can use the `ACL LIST` command in order to check the currently active ACLs
and verify what the configuration of a freshly started, defaults-configured
Redis instance is:

    > ACL LIST
    1) "user default on nopass ~* &* +@all"

The command above reports the list of users in the same format that is
used in the Redis configuration files, by translating the current ACLs set
for the users back into their description.

The first two words in each line are "user" followed by the username. The
next words are ACL rules that describe different things. We'll show how the rules work in detail, but for now it is enough to say that the default
user is configured to be active (on), to require no password (nopass), to
access every possible key (`~*`) and Pub/Sub channel (`&*`), and be able to
call every possible command (`+@all`).

Also, in the special case of the default user, having the *nopass* rule means
that new connections are automatically authenticated with the default user
without any explicit `AUTH` call needed.

## ACL rules

The following is the list of valid ACL rules. Certain rules are just
single words that are used in order to activate or remove a flag, or to
perform a given change to the user ACL. Other rules are char prefixes that
are concatenated with command or category names, key patterns, and
so forth.

Enable and disallow users:

* `on`: Enable the user: it is possible to authenticate as this user.
* `off`: Disallow the user: it's no longer possible to authenticate with this user; however, previously authenticated connections will still work. Note that if the default user is flagged as *off*, new connections will start as not authenticated and will require the user to send `AUTH` or `HELLO` with the AUTH option in order to authenticate in some way, regardless of the default user configuration.

Allow and disallow commands:

* `+<command>`: Add the command to the list of commands the user can call. Can be used with `|` for allowing subcommands (e.g "+config|get").
* `-<command>`: Remove the command to the list of commands the user can call. Starting Redis 7.0, it can be used with `|` for blocking subcommands (e.g "-config|set").
* `+@<category>`: Add all the commands in such category to be called by the user, with valid categories being like @admin, @set, @sortedset, ... and so forth, see the full list by calling the `ACL CAT` command. The special category @all means all the commands, both the ones currently present in the server, and the ones that will be loaded in the future via modules.
* `-@<category>`: Like `+@<category>` but removes the commands from the list of commands the client can call.
* `+<command>|first-arg`: Allow a specific first argument of an otherwise disabled command. It is only supported on commands with no sub-commands, and is not allowed as negative form like -SELECT|1, only additive starting with "+". This feature is deprecated and may be removed in the future.
* `allcommands`: Alias for +@all. Note that it implies the ability to execute all the future commands loaded via the modules system.
* `nocommands`: Alias for -@all.

Allow and disallow certain keys and key permissions:

* `~<pattern>`: Add a pattern of keys that can be mentioned as part of commands. For instance `~*` allows all the keys. The pattern is a glob-style pattern like the one of `KEYS`. It is possible to specify multiple patterns.
* `%R~<pattern>`: (Available in Redis 7.0 and later) Add the specified read key pattern. This behaves similar to the regular key pattern but only grants permission to read from keys that match the given pattern. See [key permissions](#key-permissions) for more information.
* `%W~<pattern>`: (Available in Redis 7.0 and later) Add the specified write key pattern. This behaves similar to the regular key pattern but only grants permission to write to keys that match the given pattern. See [key permissions](#key-permissions) for more information.
* `%RW~<pattern>`: (Available in Redis 7.0 and later) Alias for `~<pattern>`. 
* `allkeys`: Alias for `~*`.
* `resetkeys`: Flush the list of allowed keys patterns. For instance the ACL `~foo:* ~bar:* resetkeys ~objects:*`, will only allow the client to access keys that match the pattern `objects:*`.

Allow and disallow Pub/Sub channels:

* `&<pattern>`: (Available in Redis 6.2 and later) Add a glob style pattern of Pub/Sub channels that can be accessed by the user. It is possible to specify multiple channel patterns. Note that pattern matching is done only for channels mentioned by `PUBLISH` and `SUBSCRIBE`, whereas `PSUBSCRIBE` requires a literal match between its channel patterns and those allowed for user.
* `allchannels`: Alias for `&*` that allows the user to access all Pub/Sub channels.
* `resetchannels`: Flush the list of allowed channel patterns and disconnect the user's Pub/Sub clients if these are no longer able to access their respective channels and/or channel patterns.

Configure valid passwords for the user:

* `><password>`: Add this password to the list of valid passwords for the user. For example `>mypass` will add "mypass" to the list of valid passwords.  This directive clears the *nopass* flag (see later). Every user can have any number of passwords.
* `<<password>`: Remove this password from the list of valid passwords. Emits an error in case the password you are trying to remove is actually not set.
* `#<hash>`: Add this SHA-256 hash value to the list of valid passwords for the user. This hash value will be compared to the hash of a password entered for an ACL user. This allows users to store hashes in the `acl.conf` file rather than storing cleartext passwords. Only SHA-256 hash values are accepted as the password hash must be 64 characters and only contain lowercase hexadecimal characters.
* `!<hash>`: Remove this hash value from from the list of valid passwords. This is useful when you do not know the password specified by the hash value but would like to remove the password from the user.
* `nopass`: All the set passwords of the user are removed, and the user is flagged as requiring no password: it means that every password will work against this user. If this directive is used for the default user, every new connection will be immediately authenticated with the default user without any explicit AUTH command required. Note that the *resetpass* directive will clear this condition.
* `resetpass`: Flushes the list of allowed passwords and removes the *nopass* status. After *resetpass*, the user has no associated passwords and there is no way to authenticate without adding some password (or setting it as *nopass* later).

*Note: if a user is not flagged with nopass and has no list of valid passwords, that user is effectively impossible to use because there will be no way to log in as that user.*

Configure selectors for the user:

* `(<rule list>)`: (Available in Redis 7.0 and later) Create a new selector to match rules against. Selectors are evaluated after the user permissions, and are evaluated according to the order they are defined. If a command matches either the user permissions or any selector, it is allowed. See [selectors](#selectors) for more information.
* `clearselectors`: (Available in Redis 7.0 and later) Delete all of the selectors attached to the user.

Reset the user:

* `reset` Performs the following actions: resetpass, resetkeys, resetchannels, off, -@all. The user returns to the same state it had immediately after its creation.

## Create and edit user ACLs with the ACL SETUSER command

Users can be created and modified in two main ways:

1. Using the ACL command and its `ACL SETUSER` subcommand.
2. Modifying the server configuration, where users can be defined, and restarting the server. With an *external ACL file*, just call `ACL LOAD`.

In this section we'll learn how to define users using the `ACL` command.
With such knowledge, it will be trivial to do the same things via the
configuration files. Defining users in the configuration deserves its own
section and will be discussed later separately.

To start, try the simplest `ACL SETUSER` command call:

    > ACL SETUSER alice
    OK

The `SETUSER` command takes the username and a list of ACL rules to apply
to the user. However the above example did not specify any rule at all.
This will just create the user if it did not exist, using the defaults for new
users. If the user already exists, the command above will do nothing at all.

Check the default user status:

    > ACL LIST
    1) "user alice off &* -@all"
    2) "user default on nopass ~* ~& +@all"

The new user "alice" is:

* In the off status, so AUTH will not work for the user "alice".
* The user also has no passwords set.
* Cannot access any command. Note that the user is created by default without the ability to access any command, so the `-@all` in the output above could be omitted; however, `ACL LIST` attempts to be explicit rather than implicit.
* There are no key patterns that the user can access.
* The user can access all Pub/Sub channels.

New users are created with restrictive permissions by default. Starting with Redis 6.2, ACL provides Pub/Sub channels access management as well. To ensure backward compatibility with version 6.0 when upgrading to Redis 6.2, new users are granted the 'allchannels' permission by default. The default can be set to `resetchannels` via the `acl-pubsub-default` configuration directive.

From 7.0, The `acl-pubsub-default` value is set to `resetchannels` to restrict the channels access by default to provide better security.
The default can be set to `allchannels` via the `acl-pubsub-default` configuration directive to be compatible with previous versions.

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
    (error) NOPERM this user has no permissions to run the 'set' command or its subcommand

Things are working as expected. In order to inspect the configuration of the
user alice (remember that user names are case sensitive), it is possible to
use an alternative to `ACL LIST` which is designed to be more suitable for
computers to read, while `ACL LIST` is more human readable.

    > ACL GETUSER alice
    1) "flags"
    2) 1) "on"
       2) "allchannels"
    3) "passwords"
    4) 1) "2d9c75..."
    5) "commands"
    6) "-@all +get"
    7) "keys"
    8) "~cached:*"
    9) "channels"
    10) "&*"
    11) "selectors"
    12) 1) 1) "commands"
           2) "-@all +set"
           3) "keys"
           4) "~*"
           5) "channels"
           6) "&*"

The `ACL GETUSER` returns a field-value array that describes the user in more parsable terms. The output includes the set of flags, a list of key patterns, passwords, and so forth. The output is probably more readable if we use RESP3, so that it is returned as a map reply:

    > ACL GETUSER alice
    1# "flags" => 1~ "on"
       2~ "allchannels"
    2# "passwords" => 1) "2d9c75273d72b32df726fb545c8a4edc719f0a95a6fd993950b10c474ad9c927"
    3# "commands" => "-@all +get"
    4# "keys" => "~cached:*"
    5# "channels" => "&*"
    6# "selectors" => 1) 1# "commands" => "-@all +set"
        2# "keys" => "~*"
        3# "channels" => "&*"

*Note: from now on, we'll continue using the Redis default protocol, version 2*

Using another `ACL SETUSER` command (from a different user, because alice cannot run the `ACL` command), we can add multiple patterns to the user:

    > ACL SETUSER alice ~objects:* ~items:* ~public:*
    OK
    > ACL LIST
    1) "user alice on >2d9c75... ~cached:* ~objects:* ~items:* ~public:* &* -@all +get"
    2) "user default on nopass ~* &* +@all"

The user representation in memory is now as we expect it to be.

## Multiple calls to ACL SETUSER

It is very important to understand what happens when ACL SETUSER is called
multiple times. What is critical to know is that every `SETUSER` call will
NOT reset the user, but will just apply the ACL rules to the existing user.
The user is reset only if it was not known before. In that case, a brand new
user is created with zeroed-ACLs. The user cannot do anything, is
disallowed, has no passwords, and so forth. This is the best default for safety.

However later calls will just modify the user incrementally. For instance,
the following sequence:

    > ACL SETUSER myuser +set
    OK
    > ACL SETUSER myuser +get
    OK

Will result in myuser being able to call both `GET` and `SET`:

    > ACL LIST
    1) "user default on nopass ~* &* +@all"
    2) "user myuser off &* -@all +set +get"

## Command categories

Setting user ACLs by specifying all the commands one after the other is
really annoying, so instead we do things like this:

    > ACL SETUSER antirez on +@all -@dangerous >42a979... ~*

By saying +@all and -@dangerous, we included all the commands and later removed
all the commands that are tagged as dangerous inside the Redis command table.
Note that command categories **never include modules commands** with
the exception of +@all. If you say +@all, all the commands can be executed by
the user, even future commands loaded via the modules system. However if you
use the ACL rule +@read or any other, the modules commands are always
excluded. This is very important because you should just trust the Redis
internal command table. Modules may expose dangerous things and in
the case of an ACL that is just additive, that is, in the form of `+@all -...`
You should be absolutely sure that you'll never include what you did not mean
to.

The following is a list of command categories and their meanings:

* **admin** - Administrative commands. Normal applications will never need to use
  these. Includes `REPLICAOF`, `CONFIG`, `DEBUG`, `SAVE`, `MONITOR`, `ACL`, `SHUTDOWN`, etc.
* **bitmap** - Data type: bitmaps related.
* **blocking** - Potentially blocking the connection until released by another
  command.
* **connection** - Commands affecting the connection or other connections.
  This includes `AUTH`, `SELECT`, `COMMAND`, `CLIENT`, `ECHO`, `PING`, etc.
* **dangerous** - Potentially dangerous commands (each should be considered with care for
  various reasons). This includes `FLUSHALL`, `MIGRATE`, `RESTORE`, `SORT`, `KEYS`,
  `CLIENT`, `DEBUG`, `INFO`, `CONFIG`, `SAVE`, `REPLICAOF`, etc.
* **geo** - Data type: geospatial indexes related.
* **hash** - Data type: hashes related.
* **hyperloglog** - Data type: hyperloglog related.
* **fast** - Fast O(1) commands. May loop on the number of arguments, but not the
  number of elements in the key.
* **keyspace** - Writing or reading from keys, databases, or their metadata 
  in a type agnostic way. Includes `DEL`, `RESTORE`, `DUMP`, `RENAME`, `EXISTS`, `DBSIZE`,
  `KEYS`, `EXPIRE`, `TTL`, `FLUSHALL`, etc. Commands that may modify the keyspace,
  key, or metadata will also have the `write` category. Commands that only read
  the keyspace, key, or metadata will have the `read` category.
* **list** - Data type: lists related.
* **pubsub** - PubSub-related commands.
* **read** - Reading from keys (values or metadata). Note that commands that don't
  interact with keys, will not have either `read` or `write`.
* **scripting** - Scripting related.
* **set** - Data type: sets related.
* **sortedset** - Data type: sorted sets related.
* **slow** - All commands that are not `fast`.
* **stream** - Data type: streams related.
* **string** - Data type: strings related.
* **transaction** - `WATCH` / `MULTI` / `EXEC` related commands.
* **write** - Writing to keys (values or metadata).

Redis can also show you a list of all categories and the exact commands each category includes using the Redis `ACL` command's `CAT` subcommand. It can be used in two forms:

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

As you can see, so far there are 21 distinct categories. Now let's check what
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

Note that commands may be part of multiple categories. For example, an
ACL rule like `+@geo -@read` will result in certain geo commands to be
excluded because they are read-only commands.

## Allow/block subcommands

Starting from Redis 7.0, subcommands can be allowed/blocked just like other
commands (by using the separator `|` between the command and subcommand, for
example: `+config|get` or `-config|set`)

That is true for all commands except DEBUG. In order to allow/block specific
DEBUG subcommands, see the next section.

## Allow the first-arg of a blocked command

**Note: This feature is deprecated since Redis 7.0 and may be removed in the future.**

Sometimes the ability to exclude or include a command or a subcommand as a whole is not enough.
Many deployments may not be happy providing the ability to execute a `SELECT` for any DB, but may
still want to be able to run `SELECT 0`.

In such case we could alter the ACL of a user in the following way:

    ACL SETUSER myuser -select +select|0

First, remove the `SELECT` command and then add the allowed
first-arg. Note that **it is not possible to do the reverse** since first-args
can be only added, not excluded. It is safer to specify all the first-args
that are valid for some user since it is possible that
new first-args may be added in the future.

Another example:

    ACL SETUSER myuser -debug +debug|digest

Note that first-arg matching may add some performance penalty; however, it is hard to measure even with synthetic benchmarks. The
additional CPU cost is only payed when such commands are called, and not when
other commands are called.

It is possible to use this mechanism in order to allow subcommands in Redis
versions prior to 7.0 (see above section).

## +@all VS -@all

In the previous section, it was observed how it is possible to define command
ACLs based on adding/removing single commands.

## Selectors

Starting with Redis 7.0, Redis supports adding multiple sets of rules that are evaluated independently of each other.
These secondary sets of permissions are called selectors and added by wrapping a set of rules within parentheses.
In order to execute a command, either the root permissions (rules defined outside of parenthesis) or any of the selectors (rules defined inside parenthesis) must match the given command.
Internally, the root permissions are checked first followed by selectors in the order they were added.

For example, consider a user with the ACL rules `+GET ~key1 (+SET ~key2)`.
This user is able to execute `GET key1` and `SET key2 hello`, but not `GET key2` or `SET key1 world`.

Unlike the user's root permissions, selectors cannot be modified after they are added.
Instead, selectors can be removed with the `clearselectors` keyword, which removes all of the added selectors.
Note that `clearselectors` does not remove the root permissions.

## Key permissions

Starting with Redis 7.0, key patterns can also be used to define how a command is able to touch a key.
This is achieved through rules that define key permissions.
The key permission rules take the form of `%(<permission>)~<pattern>`.
Permissions are defined as individual characters that map to the following key permissions:

* W (Write): The data stored within the key may be updated or deleted. 
* R (Read): User supplied data from the key is processed, copied or returned. Note that this does not include metadata such as size information (example `STRLEN`), type information (example `TYPE`) or information about whether a value exists within a collection (example `SISMEMBER`). 

Permissions can be composed together by specifying multiple characters. 
Specifying the permission as 'RW' is considered full access and is analogous to just passing in `~<pattern>`.

For a concrete example, consider a user with ACL rules `+@all ~app1:* (+@readonly ~app2:*)`.
This user has full access on `app1:*` and readonly access on `app2:*`.
However, some commands support reading data from one key, doing some transformation, and storing it into another key.
One such command is the `COPY` command, which copies the data from the source key into the destination key.
The example set of ACL rules is unable to handle a request copying data from `app2:user` into `app1:user`, since neither the root permission or the selector fully matches the command.
However, using key selectors you can define a set of ACL rules that can handle this request `+@all ~app1:* %R~app2:*`.
The first pattern is able to match `app1:user` and the second pattern is able to match `app2:user`.

Which type of permission is required for a command is documented through [key specifications](/topics/key-specs#logical-operation-flags).
The type of permission is based off the keys logical operation flags. 
The insert, update, and delete flags map to the write key permission. 
The access flag maps to the read key permission.
If the key has no logical operation flags, such as `EXISTS`, the user still needs either key read or key write permissions to execute the command. 

Note: Side channels to accessing user data are ignored when it comes to evaluating whether read permissions are required to execute a command.
This means that some write commands that return metadata about the modified key only require write permission on the key to execute:
For example, consider the following two commands:

* `LPUSH key1 data`: modifies "key1" but only returns metadata about it, the size of the list after the push, so the command only requires write permission on "key1" to execute.
* `LPOP key2`: modifies "key2" but also returns data from it, the left most item in the list, so the command requires both read and write permission on "key2" to execute.

If an application needs to make sure no data is accessed from a key, including side channels, it's recommended to not provide any access to the key.

## How passwords are stored internally

Redis internally stores passwords hashed with SHA256. If you set a password
and check the output of `ACL LIST` or `GETUSER`, you'll see a long hex
string that looks pseudo random. Here is an example, because in the previous
examples, for the sake of brevity, the long hex string was trimmed:

    > ACL GETUSER default
    1) "flags"
    2) 1) "on"
       2) "allkeys"
       3) "allcommands"
       4) "allchannels"
    3) "passwords"
    4) 1) "2d9c75273d72b32df726fb545c8a4edc719f0a95a6fd993950b10c474ad9c927"
    5) "commands"
    6) "+@all"
    7) "keys"
    8) "~*"
    9) "channels"
    10) "&*"
    11) "selectors"
    12) (empty array)

Also, starting with Redis 6, the old command `CONFIG GET requirepass` will
no longer return the clear text password, but instead the hashed password.

Using SHA256 provides the ability to avoid storing the password in clear text
while still allowing for a very fast `AUTH` command, which is a very important
feature of Redis and is coherent with what clients expect from Redis.

However ACL *passwords* are not really passwords. They are shared secrets
between the server and the client, because the password is
not an authentication token used by a human being. For instance:

* There are no length limits, the password will just be memorized in some client software. There is no human that needs to recall a password in this context.
* The ACL password does not protect any other thing. For example, it will never be the password for some email account.
* Often when you are able to access the hashed password itself, by having full access to the Redis commands of a given server, or corrupting the system itself, you already have access to what the password is protecting: the Redis instance stability and the data it contains.

For this reason, slowing down the password authentication, in order to use an
algorithm that uses time and space to make password cracking hard,
is a very poor choice. What we suggest instead is to generate strong
passwords, so that nobody will be able to crack it using a
dictionary or a brute force attack even if they have the hash. To do so, there is a special ACL
command that generates passwords using the system cryptographic pseudorandom
generator:

    > ACL GENPASS
    "dd721260bfe1b3d9601e7fbab36de6d04e2e67b0ef1c53de59d45950db0dd3cc"

The command outputs a 32-byte (256-bit) pseudorandom string converted to a
64-byte alphanumerical string. This is long enough to avoid attacks and short
enough to be easy to manage, cut & paste, store, and so forth. This is what
you should use in order to generate Redis passwords.

## Use an external ACL file

There are two ways to store users inside the Redis configuration:

1. Users can be specified directly inside the `redis.conf` file.
2. It is possible to specify an external ACL file.

The two methods are *mutually incompatible*, so Redis will ask you to use one
or the other. Specifying users inside `redis.conf` is
good for simple use cases. When there are multiple users to define, in a
complex environment, we recommend you use the ACL file instead.

The format used inside `redis.conf` and in the external ACL file is exactly
the same, so it is trivial to switch from one to the other, and is
the following:

    user <username> ... acl rules ...

For instance:

    user worker +@list +@connection ~jobs:* on >ffa9203c493aa99

When you want to use an external ACL file, you are required to specify
the configuration directive called `aclfile`, like this:

    aclfile /etc/redis/users.acl

When you are just specifying a few users directly inside the `redis.conf`
file, you can use `CONFIG REWRITE` in order to store the new user configuration
inside the file by rewriting it.

The external ACL file however is more powerful. You can do the following:

* Use `ACL LOAD` if you modified the ACL file manually and you want Redis to reload the new configuration. Note that this command is able to load the file *only if all the users are correctly specified*. Otherwise, an error is reported to the user, and the old configuration will remain valid.
* Use `ACL SAVE` to save the current ACL configuration to the ACL file.

Note that `CONFIG REWRITE` does not also trigger `ACL SAVE`. When you use
an ACL file, the configuration and the ACLs are handled separately.

## ACL rules for Sentinel and Replicas

In case you don't want to provide Redis replicas and Redis Sentinel instances
full access to your Redis instances, the following is the set of commands
that must be allowed in order for everything to work correctly.

For Sentinel, allow the user to access the following commands both in the master and replica instances:

* AUTH, CLIENT, SUBSCRIBE, SCRIPT, PUBLISH, PING, INFO, MULTI, SLAVEOF, CONFIG, CLIENT, EXEC.

Sentinel does not need to access any key in the database but does use Pub/Sub, so the ACL rule would be the following (note: AUTH is not needed since it is always allowed):

    ACL SETUSER sentinel-user on >somepassword allchannels +multi +slaveof +ping +exec +subscribe +config|rewrite +role +publish +info +client|setname +client|kill +script|kill

Redis replicas require the following commands to be allowed on the master instance:

* PSYNC, REPLCONF, PING

No keys need to be accessed, so this translates to the following rules:

    ACL setuser replica-user on >somepassword +psync +replconf +ping

Note that you don't need to configure the replicas to allow the master to be able to execute any set of commands. The master is always authenticated as the root user from the point of view of replicas.
