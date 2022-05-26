---
title: "Modules API reference"
linkTitle: "API reference"
weight: 1
description: >
    Auto-generated reference for the Redis Modules API
aliases:
    - /topics/modules-api-ref
---

<!-- This file is generated from module.c using
     utils/generate-module-api-doc.rb -->

## Sections

* [Heap allocation raw functions](#section-heap-allocation-raw-functions)
* [Commands API](#section-commands-api)
* [Module information and time measurement](#section-module-information-and-time-measurement)
* [Automatic memory management for modules](#section-automatic-memory-management-for-modules)
* [String objects APIs](#section-string-objects-apis)
* [Reply APIs](#section-reply-apis)
* [Commands replication API](#section-commands-replication-api)
* [DB and Key APIs – Generic API](#section-db-and-key-apis-generic-api)
* [Key API for String type](#section-key-api-for-string-type)
* [Key API for List type](#section-key-api-for-list-type)
* [Key API for Sorted Set type](#section-key-api-for-sorted-set-type)
* [Key API for Sorted Set iterator](#section-key-api-for-sorted-set-iterator)
* [Key API for Hash type](#section-key-api-for-hash-type)
* [Key API for Stream type](#section-key-api-for-stream-type)
* [Calling Redis commands from modules](#section-calling-redis-commands-from-modules)
* [Modules data types](#section-modules-data-types)
* [RDB loading and saving functions](#section-rdb-loading-and-saving-functions)
* [Key digest API (DEBUG DIGEST interface for modules types)](#section-key-digest-api-debug-digest-interface-for-modules-types)
* [AOF API for modules data types](#section-aof-api-for-modules-data-types)
* [IO context handling](#section-io-context-handling)
* [Logging](#section-logging)
* [Blocking clients from modules](#section-blocking-clients-from-modules)
* [Thread Safe Contexts](#section-thread-safe-contexts)
* [Module Keyspace Notifications API](#section-module-keyspace-notifications-api)
* [Modules Cluster API](#section-modules-cluster-api)
* [Modules Timers API](#section-modules-timers-api)
* [Modules EventLoop API](#section-modules-eventloop-api)
* [Modules ACL API](#section-modules-acl-api)
* [Modules Dictionary API](#section-modules-dictionary-api)
* [Modules Info fields](#section-modules-info-fields)
* [Modules utility APIs](#section-modules-utility-apis)
* [Modules API exporting / importing](#section-modules-api-exporting-importing)
* [Module Command Filter API](#section-module-command-filter-api)
* [Scanning keyspace and hashes](#section-scanning-keyspace-and-hashes)
* [Module fork API](#section-module-fork-api)
* [Server hooks implementation](#section-server-hooks-implementation)
* [Module Configurations API](#section-module-configurations-api)
* [Key eviction API](#section-key-eviction-api)
* [Miscellaneous APIs](#section-miscellaneous-apis)
* [Defrag API](#section-defrag-api)
* [Function index](#section-function-index)

<span id="section-heap-allocation-raw-functions"></span>

## Heap allocation raw functions

Memory allocated with these functions are taken into account by Redis key
eviction algorithms and are reported in Redis memory usage information.

<span id="RedisModule_Alloc"></span>

### `RedisModule_Alloc`

    void *RedisModule_Alloc(size_t bytes);

**Available since:** 4.0.0

Use like `malloc()`. Memory allocated with this function is reported in
Redis INFO memory, used for keys eviction according to maxmemory settings
and in general is taken into account as memory allocated by Redis.
You should avoid using `malloc()`.
This function panics if unable to allocate enough memory.

<span id="RedisModule_TryAlloc"></span>

### `RedisModule_TryAlloc`

    void *RedisModule_TryAlloc(size_t bytes);

**Available since:** 7.0.0

Similar to [`RedisModule_Alloc`](#RedisModule_Alloc), but returns NULL in case of allocation failure, instead
of panicking.

<span id="RedisModule_Calloc"></span>

### `RedisModule_Calloc`

    void *RedisModule_Calloc(size_t nmemb, size_t size);

**Available since:** 4.0.0

Use like `calloc()`. Memory allocated with this function is reported in
Redis INFO memory, used for keys eviction according to maxmemory settings
and in general is taken into account as memory allocated by Redis.
You should avoid using `calloc()` directly.

<span id="RedisModule_Realloc"></span>

### `RedisModule_Realloc`

    void* RedisModule_Realloc(void *ptr, size_t bytes);

**Available since:** 4.0.0

Use like `realloc()` for memory obtained with [`RedisModule_Alloc()`](#RedisModule_Alloc).

<span id="RedisModule_Free"></span>

### `RedisModule_Free`

    void RedisModule_Free(void *ptr);

**Available since:** 4.0.0

Use like `free()` for memory obtained by [`RedisModule_Alloc()`](#RedisModule_Alloc) and
[`RedisModule_Realloc()`](#RedisModule_Realloc). However you should never try to free with
[`RedisModule_Free()`](#RedisModule_Free) memory allocated with `malloc()` inside your module.

<span id="RedisModule_Strdup"></span>

### `RedisModule_Strdup`

    char *RedisModule_Strdup(const char *str);

**Available since:** 4.0.0

Like `strdup()` but returns memory allocated with [`RedisModule_Alloc()`](#RedisModule_Alloc).

<span id="RedisModule_PoolAlloc"></span>

### `RedisModule_PoolAlloc`

    void *RedisModule_PoolAlloc(RedisModuleCtx *ctx, size_t bytes);

**Available since:** 4.0.0

Return heap allocated memory that will be freed automatically when the
module callback function returns. Mostly suitable for small allocations
that are short living and must be released when the callback returns
anyway. The returned memory is aligned to the architecture word size
if at least word size bytes are requested, otherwise it is just
aligned to the next power of two, so for example a 3 bytes request is
4 bytes aligned while a 2 bytes request is 2 bytes aligned.

There is no realloc style function since when this is needed to use the
pool allocator is not a good idea.

The function returns NULL if `bytes` is 0.

<span id="section-commands-api"></span>

## Commands API

These functions are used to implement custom Redis commands.

For examples, see [https://redis.io/topics/modules-intro](https://redis.io/topics/modules-intro).

<span id="RedisModule_IsKeysPositionRequest"></span>

### `RedisModule_IsKeysPositionRequest`

    int RedisModule_IsKeysPositionRequest(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Return non-zero if a module command, that was declared with the
flag "getkeys-api", is called in a special way to get the keys positions
and not to get executed. Otherwise zero is returned.

<span id="RedisModule_KeyAtPosWithFlags"></span>

### `RedisModule_KeyAtPosWithFlags`

    void RedisModule_KeyAtPosWithFlags(RedisModuleCtx *ctx, int pos, int flags);

**Available since:** 7.0.0

When a module command is called in order to obtain the position of
keys, since it was flagged as "getkeys-api" during the registration,
the command implementation checks for this special call using the
[`RedisModule_IsKeysPositionRequest()`](#RedisModule_IsKeysPositionRequest) API and uses this function in
order to report keys.

The supported flags are the ones used by [`RedisModule_SetCommandInfo`](#RedisModule_SetCommandInfo), see `REDISMODULE_CMD_KEY_`*.


The following is an example of how it could be used:

    if (RedisModule_IsKeysPositionRequest(ctx)) {
        RedisModule_KeyAtPosWithFlags(ctx, 2, REDISMODULE_CMD_KEY_RO | REDISMODULE_CMD_KEY_ACCESS);
        RedisModule_KeyAtPosWithFlags(ctx, 1, REDISMODULE_CMD_KEY_RW | REDISMODULE_CMD_KEY_UPDATE | REDISMODULE_CMD_KEY_ACCESS);
    }

 Note: in the example above the get keys API could have been handled by key-specs (preferred).
 Implementing the getkeys-api is required only when is it not possible to declare key-specs that cover all keys.

<span id="RedisModule_KeyAtPos"></span>

### `RedisModule_KeyAtPos`

    void RedisModule_KeyAtPos(RedisModuleCtx *ctx, int pos);

**Available since:** 4.0.0

This API existed before [`RedisModule_KeyAtPosWithFlags`](#RedisModule_KeyAtPosWithFlags) was added, now deprecated and
can be used for compatibility with older versions, before key-specs and flags
were introduced.

<span id="RedisModule_IsChannelsPositionRequest"></span>

### `RedisModule_IsChannelsPositionRequest`

    int RedisModule_IsChannelsPositionRequest(RedisModuleCtx *ctx);

**Available since:** 7.0.0

Return non-zero if a module command, that was declared with the
flag "getchannels-api", is called in a special way to get the channel positions
and not to get executed. Otherwise zero is returned.

<span id="RedisModule_ChannelAtPosWithFlags"></span>

### `RedisModule_ChannelAtPosWithFlags`

    void RedisModule_ChannelAtPosWithFlags(RedisModuleCtx *ctx,
                                           int pos,
                                           int flags);

**Available since:** 7.0.0

When a module command is called in order to obtain the position of
channels, since it was flagged as "getchannels-api" during the
registration, the command implementation checks for this special call
using the [`RedisModule_IsChannelsPositionRequest()`](#RedisModule_IsChannelsPositionRequest) API and uses this
function in order to report the channels.

The supported flags are:
* `REDISMODULE_CMD_CHANNEL_SUBSCRIBE`: This command will subscribe to the channel.
* `REDISMODULE_CMD_CHANNEL_UNSUBSCRIBE`: This command will unsubscribe from this channel.
* `REDISMODULE_CMD_CHANNEL_PUBLISH`: This command will publish to this channel.
* `REDISMODULE_CMD_CHANNEL_PATTERN`: Instead of acting on a specific channel, will act on any 
                                   channel specified by the pattern. This is the same access
                                   used by the PSUBSCRIBE and PUNSUBSCRIBE commands available 
                                   in Redis. Not intended to be used with PUBLISH permissions.

The following is an example of how it could be used:

    if (RedisModule_IsChannelsPositionRequest(ctx)) {
        RedisModule_ChannelAtPosWithFlags(ctx, 1, REDISMODULE_CMD_CHANNEL_SUBSCRIBE | REDISMODULE_CMD_CHANNEL_PATTERN);
        RedisModule_ChannelAtPosWithFlags(ctx, 1, REDISMODULE_CMD_CHANNEL_PUBLISH);
    }

Note: One usage of declaring channels is for evaluating ACL permissions. In this context,
unsubscribing is always allowed, so commands will only be checked against subscribe and
publish permissions. This is preferred over using [`RedisModule_ACLCheckChannelPermissions`](#RedisModule_ACLCheckChannelPermissions), since
it allows the ACLs to be checked before the command is executed.

<span id="RedisModule_CreateCommand"></span>

### `RedisModule_CreateCommand`

    int RedisModule_CreateCommand(RedisModuleCtx *ctx,
                                  const char *name,
                                  RedisModuleCmdFunc cmdfunc,
                                  const char *strflags,
                                  int firstkey,
                                  int lastkey,
                                  int keystep);

**Available since:** 4.0.0

Register a new command in the Redis server, that will be handled by
calling the function pointer 'cmdfunc' using the RedisModule calling
convention. The function returns `REDISMODULE_ERR` if the specified command
name is already busy or a set of invalid flags were passed, otherwise
`REDISMODULE_OK` is returned and the new command is registered.

This function must be called during the initialization of the module
inside the `RedisModule_OnLoad()` function. Calling this function outside
of the initialization function is not defined.

The command function type is the following:

     int MyCommand_RedisCommand(RedisModuleCtx *ctx, RedisModuleString **argv, int argc);

And is supposed to always return `REDISMODULE_OK`.

The set of flags 'strflags' specify the behavior of the command, and should
be passed as a C string composed of space separated words, like for
example "write deny-oom". The set of flags are:

* **"write"**:     The command may modify the data set (it may also read
                   from it).
* **"readonly"**:  The command returns data from keys but never writes.
* **"admin"**:     The command is an administrative command (may change
                   replication or perform similar tasks).
* **"deny-oom"**:  The command may use additional memory and should be
                   denied during out of memory conditions.
* **"deny-script"**:   Don't allow this command in Lua scripts.
* **"allow-loading"**: Allow this command while the server is loading data.
                       Only commands not interacting with the data set
                       should be allowed to run in this mode. If not sure
                       don't use this flag.
* **"pubsub"**:    The command publishes things on Pub/Sub channels.
* **"random"**:    The command may have different outputs even starting
                   from the same input arguments and key values.
                   Starting from Redis 7.0 this flag has been deprecated.
                   Declaring a command as "random" can be done using
                   command tips, see https://redis.io/topics/command-tips.
* **"allow-stale"**: The command is allowed to run on slaves that don't
                     serve stale data. Don't use if you don't know what
                     this means.
* **"no-monitor"**: Don't propagate the command on monitor. Use this if
                    the command has sensitive data among the arguments.
* **"no-slowlog"**: Don't log this command in the slowlog. Use this if
                    the command has sensitive data among the arguments.
* **"fast"**:      The command time complexity is not greater
                   than O(log(N)) where N is the size of the collection or
                   anything else representing the normal scalability
                   issue with the command.
* **"getkeys-api"**: The command implements the interface to return
                     the arguments that are keys. Used when start/stop/step
                     is not enough because of the command syntax.
* **"no-cluster"**: The command should not register in Redis Cluster
                    since is not designed to work with it because, for
                    example, is unable to report the position of the
                    keys, programmatically creates key names, or any
                    other reason.
* **"no-auth"**:    This command can be run by an un-authenticated client.
                    Normally this is used by a command that is used
                    to authenticate a client.
* **"may-replicate"**: This command may generate replication traffic, even
                       though it's not a write command.
* **"no-mandatory-keys"**: All the keys this command may take are optional
* **"blocking"**: The command has the potential to block the client.
* **"allow-busy"**: Permit the command while the server is blocked either by
                    a script or by a slow module command, see
                    RM_Yield.
* **"getchannels-api"**: The command implements the interface to return
                         the arguments that are channels.

The last three parameters specify which arguments of the new command are
Redis keys. See [https://redis.io/commands/command](https://redis.io/commands/command) for more information.

* `firstkey`: One-based index of the first argument that's a key.
              Position 0 is always the command name itself.
              0 for commands with no keys.
* `lastkey`:  One-based index of the last argument that's a key.
              Negative numbers refer to counting backwards from the last
              argument (-1 means the last argument provided)
              0 for commands with no keys.
* `keystep`:  Step between first and last key indexes.
              0 for commands with no keys.

This information is used by ACL, Cluster and the `COMMAND` command.

NOTE: The scheme described above serves a limited purpose and can
only be used to find keys that exist at constant indices.
For non-trivial key arguments, you may pass 0,0,0 and use
[`RedisModule_SetCommandInfo`](#RedisModule_SetCommandInfo) to set key specs using a more advanced scheme.

<span id="RedisModule_GetCommand"></span>

### `RedisModule_GetCommand`

    RedisModuleCommand *RedisModule_GetCommand(RedisModuleCtx *ctx,
                                               const char *name);

**Available since:** 7.0.0

Get an opaque structure, representing a module command, by command name.
This structure is used in some of the command-related APIs.

NULL is returned in case of the following errors:

* Command not found
* The command is not a module command
* The command doesn't belong to the calling module

<span id="RedisModule_CreateSubcommand"></span>

### `RedisModule_CreateSubcommand`

    int RedisModule_CreateSubcommand(RedisModuleCommand *parent,
                                     const char *name,
                                     RedisModuleCmdFunc cmdfunc,
                                     const char *strflags,
                                     int firstkey,
                                     int lastkey,
                                     int keystep);

**Available since:** 7.0.0

Very similar to [`RedisModule_CreateCommand`](#RedisModule_CreateCommand) except that it is used to create
a subcommand, associated with another, container, command.

Example: If a module has a configuration command, MODULE.CONFIG, then
GET and SET should be individual subcommands, while MODULE.CONFIG is
a command, but should not be registered with a valid `funcptr`:

     if (RedisModule_CreateCommand(ctx,"module.config",NULL,"",0,0,0) == REDISMODULE_ERR)
         return REDISMODULE_ERR;

     RedisModuleCommand *parent = RedisModule_GetCommand(ctx,,"module.config");

     if (RedisModule_CreateSubcommand(parent,"set",cmd_config_set,"",0,0,0) == REDISMODULE_ERR)
        return REDISMODULE_ERR;

     if (RedisModule_CreateSubcommand(parent,"get",cmd_config_get,"",0,0,0) == REDISMODULE_ERR)
        return REDISMODULE_ERR;

Returns `REDISMODULE_OK` on success and `REDISMODULE_ERR` in case of the following errors:

* Error while parsing `strflags`
* Command is marked as `no-cluster` but cluster mode is enabled
* `parent` is already a subcommand (we do not allow more than one level of command nesting)
* `parent` is a command with an implementation (`RedisModuleCmdFunc`) (A parent command should be a pure container of subcommands)
* `parent` already has a subcommand called `name`

<span id="RedisModule_SetCommandInfo"></span>

### `RedisModule_SetCommandInfo`

    int RedisModule_SetCommandInfo(RedisModuleCommand *command,
                                   const RedisModuleCommandInfo *info);

**Available since:** 7.0.0

Set additional command information.

Affects the output of `COMMAND`, `COMMAND INFO` and `COMMAND DOCS`, Cluster,
ACL and is used to filter commands with the wrong number of arguments before
the call reaches the module code.

This function can be called after creating a command using [`RedisModule_CreateCommand`](#RedisModule_CreateCommand)
and fetching the command pointer using [`RedisModule_GetCommand`](#RedisModule_GetCommand). The information can
only be set once for each command and has the following structure:

    typedef struct RedisModuleCommandInfo {
        const RedisModuleCommandInfoVersion *version;
        const char *summary;
        const char *complexity;
        const char *since;
        RedisModuleCommandHistoryEntry *history;
        const char *tips;
        int arity;
        RedisModuleCommandKeySpec *key_specs;
        RedisModuleCommandArg *args;
    } RedisModuleCommandInfo;

All fields except `version` are optional. Explanation of the fields:

- `version`: This field enables compatibility with different Redis versions.
  Always set this field to `REDISMODULE_COMMAND_INFO_VERSION`.

- `summary`: A short description of the command (optional).

- `complexity`: Complexity description (optional).

- `since`: The version where the command was introduced (optional).
  Note: The version specified should be the module's, not Redis version.

- `history`: An array of `RedisModuleCommandHistoryEntry` (optional), which is
  a struct with the following fields:

        const char *since;
        const char *changes;

    `since` is a version string and `changes` is a string describing the
    changes. The array is terminated by a zeroed entry, i.e. an entry with
    both strings set to NULL.

- `tips`: A string of space-separated tips regarding this command, meant for
  clients and proxies. See [https://redis.io/topics/command-tips](https://redis.io/topics/command-tips).

- `arity`: Number of arguments, including the command name itself. A positive
  number specifies an exact number of arguments and a negative number
  specifies a minimum number of arguments, so use -N to say >= N. Redis
  validates a call before passing it to a module, so this can replace an
  arity check inside the module command implementation. A value of 0 (or an
  omitted arity field) is equivalent to -2 if the command has sub commands
  and -1 otherwise.

- `key_specs`: An array of `RedisModuleCommandKeySpec`, terminated by an
  element memset to zero. This is a scheme that tries to describe the
  positions of key arguments better than the old [`RedisModule_CreateCommand`](#RedisModule_CreateCommand) arguments
  `firstkey`, `lastkey`, `keystep` and is needed if those three are not
  enough to describe the key positions. There are two steps to retrieve key
  positions: *begin search* (BS) in which index should find the first key and
  *find keys* (FK) which, relative to the output of BS, describes how can we
  will which arguments are keys. Additionally, there are key specific flags.

    Key-specs cause the triplet (firstkey, lastkey, keystep) given in
    RM_CreateCommand to be recomputed, but it is still useful to provide
    these three parameters in RM_CreateCommand, to better support old Redis
    versions where RM_SetCommandInfo is not available.

    Note that key-specs don't fully replace the "getkeys-api" (see
    RM_CreateCommand, RM_IsKeysPositionRequest and RM_KeyAtPosWithFlags) so
    it may be a good idea to supply both key-specs and implement the
    getkeys-api.

    A key-spec has the following structure:

        typedef struct RedisModuleCommandKeySpec {
            const char *notes;
            uint64_t flags;
            RedisModuleKeySpecBeginSearchType begin_search_type;
            union {
                struct {
                    int pos;
                } index;
                struct {
                    const char *keyword;
                    int startfrom;
                } keyword;
            } bs;
            RedisModuleKeySpecFindKeysType find_keys_type;
            union {
                struct {
                    int lastkey;
                    int keystep;
                    int limit;
                } range;
                struct {
                    int keynumidx;
                    int firstkey;
                    int keystep;
                } keynum;
            } fk;
        } RedisModuleCommandKeySpec;

    Explanation of the fields of RedisModuleCommandKeySpec:

    * `notes`: Optional notes or clarifications about this key spec.

    * `flags`: A bitwise or of key-spec flags described below.

    * `begin_search_type`: This describes how the first key is discovered.
      There are two ways to determine the first key:

        * `REDISMODULE_KSPEC_BS_UNKNOWN`: There is no way to tell where the
          key args start.
        * `REDISMODULE_KSPEC_BS_INDEX`: Key args start at a constant index.
        * `REDISMODULE_KSPEC_BS_KEYWORD`: Key args start just after a
          specific keyword.

    * `bs`: This is a union in which the `index` or `keyword` branch is used
      depending on the value of the `begin_search_type` field.

        * `bs.index.pos`: The index from which we start the search for keys.
          (`REDISMODULE_KSPEC_BS_INDEX` only.)

        * `bs.keyword.keyword`: The keyword (string) that indicates the
          beginning of key arguments. (`REDISMODULE_KSPEC_BS_KEYWORD` only.)

        * `bs.keyword.startfrom`: An index in argv from which to start
          searching. Can be negative, which means start search from the end,
          in reverse. Example: -2 means to start in reverse from the
          penultimate argument. (`REDISMODULE_KSPEC_BS_KEYWORD` only.)

    * `find_keys_type`: After the "begin search", this describes which
      arguments are keys. The strategies are:

        * `REDISMODULE_KSPEC_BS_UNKNOWN`: There is no way to tell where the
          key args are located.
        * `REDISMODULE_KSPEC_FK_RANGE`: Keys end at a specific index (or
          relative to the last argument).
        * `REDISMODULE_KSPEC_FK_KEYNUM`: There's an argument that contains
          the number of key args somewhere before the keys themselves.

      `find_keys_type` and `fk` can be omitted if this keyspec describes
      exactly one key.

    * `fk`: This is a union in which the `range` or `keynum` branch is used
      depending on the value of the `find_keys_type` field.

        * `fk.range` (for `REDISMODULE_KSPEC_FK_RANGE`): A struct with the
          following fields:

            * `lastkey`: Index of the last key relative to the result of the
              begin search step. Can be negative, in which case it's not
              relative. -1 indicates the last argument, -2 one before the
              last and so on.

            * `keystep`: How many arguments should we skip after finding a
              key, in order to find the next one?

            * `limit`: If `lastkey` is -1, we use `limit` to stop the search
              by a factor. 0 and 1 mean no limit. 2 means 1/2 of the
              remaining args, 3 means 1/3, and so on.

        * `fk.keynum` (for `REDISMODULE_KSPEC_FK_KEYNUM`): A struct with the
          following fields:

            * `keynumidx`: Index of the argument containing the number of
              keys to come, relative to the result of the begin search step.

            * `firstkey`: Index of the fist key relative to the result of the
              begin search step. (Usually it's just after `keynumidx`, in
              which case it should be set to `keynumidx + 1`.)

            * `keystep`: How many arguments should we skip after finding a
              key, in order to find the next one?

    Key-spec flags:

    The first four refer to what the command actually does with the *value or
    metadata of the key*, and not necessarily the user data or how it affects
    it. Each key-spec may must have exactly one of these. Any operation
    that's not distinctly deletion, overwrite or read-only would be marked as
    RW.

    * `REDISMODULE_CMD_KEY_RO`: Read-Only. Reads the value of the key, but
      doesn't necessarily return it.

    * `REDISMODULE_CMD_KEY_RW`: Read-Write. Modifies the data stored in the
      value of the key or its metadata.

    * `REDISMODULE_CMD_KEY_OW`: Overwrite. Overwrites the data stored in the
      value of the key.

    * `REDISMODULE_CMD_KEY_RM`: Deletes the key.

    The next four refer to *user data inside the value of the key*, not the
    metadata like LRU, type, cardinality. It refers to the logical operation
    on the user's data (actual input strings or TTL), being
    used/returned/copied/changed. It doesn't refer to modification or
    returning of metadata (like type, count, presence of data). ACCESS can be
    combined with one of the write operations INSERT, DELETE or UPDATE. Any
    write that's not an INSERT or a DELETE would be UPDATE.

    * `REDISMODULE_CMD_KEY_ACCESS`: Returns, copies or uses the user data
      from the value of the key.

    * `REDISMODULE_CMD_KEY_UPDATE`: Updates data to the value, new value may
      depend on the old value.

    * `REDISMODULE_CMD_KEY_INSERT`: Adds data to the value with no chance of
      modification or deletion of existing data.

    * `REDISMODULE_CMD_KEY_DELETE`: Explicitly deletes some content from the
      value of the key.

    Other flags:

    * `REDISMODULE_CMD_KEY_NOT_KEY`: The key is not actually a key, but 
      should be routed in cluster mode as if it was a key.

    * `REDISMODULE_CMD_KEY_INCOMPLETE`: The keyspec might not point out all
      the keys it should cover.

    * `REDISMODULE_CMD_KEY_VARIABLE_FLAGS`: Some keys might have different
      flags depending on arguments.

- `args`: An array of `RedisModuleCommandArg`, terminated by an element memset
  to zero. `RedisModuleCommandArg` is a structure with at the fields described
  below.

        typedef struct RedisModuleCommandArg {
            const char *name;
            RedisModuleCommandArgType type;
            int key_spec_index;
            const char *token;
            const char *summary;
            const char *since;
            int flags;
            struct RedisModuleCommandArg *subargs;
        } RedisModuleCommandArg;

    Explanation of the fields:

    * `name`: Name of the argument.

    * `type`: The type of the argument. See below for details. The types
      `REDISMODULE_ARG_TYPE_ONEOF` and `REDISMODULE_ARG_TYPE_BLOCK` require
      an argument to have sub-arguments, i.e. `subargs`.

    * `key_spec_index`: If the `type` is `REDISMODULE_ARG_TYPE_KEY` you must
      provide the index of the key-spec associated with this argument. See
      `key_specs` above. If the argument is not a key, you may specify -1.

    * `token`: The token preceding the argument (optional). Example: the
      argument `seconds` in `SET` has a token `EX`. If the argument consists
      of only a token (for example `NX` in `SET`) the type should be
      `REDISMODULE_ARG_TYPE_PURE_TOKEN` and `value` should be NULL.

    * `summary`: A short description of the argument (optional).

    * `since`: The first version which included this argument (optional).

    * `flags`: A bitwise or of the macros `REDISMODULE_CMD_ARG_*`. See below.

    * `value`: The display-value of the argument. This string is what should
      be displayed when creating the command syntax from the output of
      `COMMAND`. If `token` is not NULL, it should also be displayed.

    Explanation of `RedisModuleCommandArgType`:

    * `REDISMODULE_ARG_TYPE_STRING`: String argument.
    * `REDISMODULE_ARG_TYPE_INTEGER`: Integer argument.
    * `REDISMODULE_ARG_TYPE_DOUBLE`: Double-precision float argument.
    * `REDISMODULE_ARG_TYPE_KEY`: String argument representing a keyname.
    * `REDISMODULE_ARG_TYPE_PATTERN`: String, but regex pattern.
    * `REDISMODULE_ARG_TYPE_UNIX_TIME`: Integer, but Unix timestamp.
    * `REDISMODULE_ARG_TYPE_PURE_TOKEN`: Argument doesn't have a placeholder.
      It's just a token without a value. Example: the `KEEPTTL` option of the
      `SET` command.
    * `REDISMODULE_ARG_TYPE_ONEOF`: Used when the user can choose only one of
      a few sub-arguments. Requires `subargs`. Example: the `NX` and `XX`
      options of `SET`.
    * `REDISMODULE_ARG_TYPE_BLOCK`: Used when one wants to group together
      several sub-arguments, usually to apply something on all of them, like
      making the entire group "optional". Requires `subargs`. Example: the
      `LIMIT offset count` parameters in `ZRANGE`.

    Explanation of the command argument flags:

    * `REDISMODULE_CMD_ARG_OPTIONAL`: The argument is optional (like GET in
      the SET command).
    * `REDISMODULE_CMD_ARG_MULTIPLE`: The argument may repeat itself (like
      key in DEL).
    * `REDISMODULE_CMD_ARG_MULTIPLE_TOKEN`: The argument may repeat itself,
      and so does its token (like `GET pattern` in SORT).

On success `REDISMODULE_OK` is returned. On error `REDISMODULE_ERR` is returned
and `errno` is set to EINVAL if invalid info was provided or EEXIST if info
has already been set. If the info is invalid, a warning is logged explaining
which part of the info is invalid and why.

<span id="section-module-information-and-time-measurement"></span>

## Module information and time measurement

<span id="RedisModule_IsModuleNameBusy"></span>

### `RedisModule_IsModuleNameBusy`

    int RedisModule_IsModuleNameBusy(const char *name);

**Available since:** 4.0.3

Return non-zero if the module name is busy.
Otherwise zero is returned.

<span id="RedisModule_Milliseconds"></span>

### `RedisModule_Milliseconds`

    long long RedisModule_Milliseconds(void);

**Available since:** 4.0.0

Return the current UNIX time in milliseconds.

<span id="RedisModule_MonotonicMicroseconds"></span>

### `RedisModule_MonotonicMicroseconds`

    uint64_t RedisModule_MonotonicMicroseconds(void);

**Available since:** 7.0.0

Return counter of micro-seconds relative to an arbitrary point in time.

<span id="RedisModule_BlockedClientMeasureTimeStart"></span>

### `RedisModule_BlockedClientMeasureTimeStart`

    int RedisModule_BlockedClientMeasureTimeStart(RedisModuleBlockedClient *bc);

**Available since:** 6.2.0

Mark a point in time that will be used as the start time to calculate
the elapsed execution time when [`RedisModule_BlockedClientMeasureTimeEnd()`](#RedisModule_BlockedClientMeasureTimeEnd) is called.
Within the same command, you can call multiple times
[`RedisModule_BlockedClientMeasureTimeStart()`](#RedisModule_BlockedClientMeasureTimeStart) and [`RedisModule_BlockedClientMeasureTimeEnd()`](#RedisModule_BlockedClientMeasureTimeEnd)
to accumulate independent time intervals to the background duration.
This method always return `REDISMODULE_OK`.

<span id="RedisModule_BlockedClientMeasureTimeEnd"></span>

### `RedisModule_BlockedClientMeasureTimeEnd`

    int RedisModule_BlockedClientMeasureTimeEnd(RedisModuleBlockedClient *bc);

**Available since:** 6.2.0

Mark a point in time that will be used as the end time
to calculate the elapsed execution time.
On success `REDISMODULE_OK` is returned.
This method only returns `REDISMODULE_ERR` if no start time was
previously defined ( meaning [`RedisModule_BlockedClientMeasureTimeStart`](#RedisModule_BlockedClientMeasureTimeStart) was not called ).

<span id="RedisModule_Yield"></span>

### `RedisModule_Yield`

    void RedisModule_Yield(RedisModuleCtx *ctx, int flags, const char *busy_reply);

**Available since:** 7.0.0

This API allows modules to let Redis process background tasks, and some
commands during long blocking execution of a module command.
The module can call this API periodically.
The flags is a bit mask of these:

- `REDISMODULE_YIELD_FLAG_NONE`: No special flags, can perform some background
                                 operations, but not process client commands.
- `REDISMODULE_YIELD_FLAG_CLIENTS`: Redis can also process client commands.

The `busy_reply` argument is optional, and can be used to control the verbose
error string after the `-BUSY` error code.

When the `REDISMODULE_YIELD_FLAG_CLIENTS` is used, Redis will only start
processing client commands after the time defined by the
`busy-reply-threshold` config, in which case Redis will start rejecting most
commands with `-BUSY` error, but allow the ones marked with the `allow-busy`
flag to be executed.
This API can also be used in thread safe context (while locked), and during
loading (in the `rdb_load` callback, in which case it'll reject commands with
the -LOADING error)

<span id="RedisModule_SetModuleOptions"></span>

### `RedisModule_SetModuleOptions`

    void RedisModule_SetModuleOptions(RedisModuleCtx *ctx, int options);

**Available since:** 6.0.0

Set flags defining capabilities or behavior bit flags.

`REDISMODULE_OPTIONS_HANDLE_IO_ERRORS`:
Generally, modules don't need to bother with this, as the process will just
terminate if a read error happens, however, setting this flag would allow
repl-diskless-load to work if enabled.
The module should use [`RedisModule_IsIOError`](#RedisModule_IsIOError) after reads, before using the
data that was read, and in case of error, propagate it upwards, and also be
able to release the partially populated value and all it's allocations.

`REDISMODULE_OPTION_NO_IMPLICIT_SIGNAL_MODIFIED`:
See [`RedisModule_SignalModifiedKey()`](#RedisModule_SignalModifiedKey).

`REDISMODULE_OPTIONS_HANDLE_REPL_ASYNC_LOAD`:
Setting this flag indicates module awareness of diskless async replication (repl-diskless-load=swapdb)
and that redis could be serving reads during replication instead of blocking with LOADING status.

<span id="RedisModule_SignalModifiedKey"></span>

### `RedisModule_SignalModifiedKey`

    int RedisModule_SignalModifiedKey(RedisModuleCtx *ctx,
                                      RedisModuleString *keyname);

**Available since:** 6.0.0

Signals that the key is modified from user's perspective (i.e. invalidate WATCH
and client side caching).

This is done automatically when a key opened for writing is closed, unless
the option `REDISMODULE_OPTION_NO_IMPLICIT_SIGNAL_MODIFIED` has been set using
[`RedisModule_SetModuleOptions()`](#RedisModule_SetModuleOptions).

<span id="section-automatic-memory-management-for-modules"></span>

## Automatic memory management for modules

<span id="RedisModule_AutoMemory"></span>

### `RedisModule_AutoMemory`

    void RedisModule_AutoMemory(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Enable automatic memory management.

The function must be called as the first function of a command implementation
that wants to use automatic memory.

When enabled, automatic memory management tracks and automatically frees
keys, call replies and Redis string objects once the command returns. In most
cases this eliminates the need of calling the following functions:

1. [`RedisModule_CloseKey()`](#RedisModule_CloseKey)
2. [`RedisModule_FreeCallReply()`](#RedisModule_FreeCallReply)
3. [`RedisModule_FreeString()`](#RedisModule_FreeString)

These functions can still be used with automatic memory management enabled,
to optimize loops that make numerous allocations for example.

<span id="section-string-objects-apis"></span>

## String objects APIs

<span id="RedisModule_CreateString"></span>

### `RedisModule_CreateString`

    RedisModuleString *RedisModule_CreateString(RedisModuleCtx *ctx,
                                                const char *ptr,
                                                size_t len);

**Available since:** 4.0.0

Create a new module string object. The returned string must be freed
with [`RedisModule_FreeString()`](#RedisModule_FreeString), unless automatic memory is enabled.

The string is created by copying the `len` bytes starting
at `ptr`. No reference is retained to the passed buffer.

The module context 'ctx' is optional and may be NULL if you want to create
a string out of the context scope. However in that case, the automatic
memory management will not be available, and the string memory must be
managed manually.

<span id="RedisModule_CreateStringPrintf"></span>

### `RedisModule_CreateStringPrintf`

    RedisModuleString *RedisModule_CreateStringPrintf(RedisModuleCtx *ctx,
                                                      const char *fmt,
                                                      ...);

**Available since:** 4.0.0

Create a new module string object from a printf format and arguments.
The returned string must be freed with [`RedisModule_FreeString()`](#RedisModule_FreeString), unless
automatic memory is enabled.

The string is created using the sds formatter function `sdscatvprintf()`.

The passed context 'ctx' may be NULL if necessary, see the
[`RedisModule_CreateString()`](#RedisModule_CreateString) documentation for more info.

<span id="RedisModule_CreateStringFromLongLong"></span>

### `RedisModule_CreateStringFromLongLong`

    RedisModuleString *RedisModule_CreateStringFromLongLong(RedisModuleCtx *ctx,
                                                            long long ll);

**Available since:** 4.0.0

Like `RedisModule_CreatString()`, but creates a string starting from a `long long`
integer instead of taking a buffer and its length.

The returned string must be released with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by
enabling automatic memory management.

The passed context 'ctx' may be NULL if necessary, see the
[`RedisModule_CreateString()`](#RedisModule_CreateString) documentation for more info.

<span id="RedisModule_CreateStringFromDouble"></span>

### `RedisModule_CreateStringFromDouble`

    RedisModuleString *RedisModule_CreateStringFromDouble(RedisModuleCtx *ctx,
                                                          double d);

**Available since:** 6.0.0

Like `RedisModule_CreatString()`, but creates a string starting from a double
instead of taking a buffer and its length.

The returned string must be released with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by
enabling automatic memory management.

<span id="RedisModule_CreateStringFromLongDouble"></span>

### `RedisModule_CreateStringFromLongDouble`

    RedisModuleString *RedisModule_CreateStringFromLongDouble(RedisModuleCtx *ctx,
                                                              long double ld,
                                                              int humanfriendly);

**Available since:** 6.0.0

Like `RedisModule_CreatString()`, but creates a string starting from a long
double.

The returned string must be released with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by
enabling automatic memory management.

The passed context 'ctx' may be NULL if necessary, see the
[`RedisModule_CreateString()`](#RedisModule_CreateString) documentation for more info.

<span id="RedisModule_CreateStringFromString"></span>

### `RedisModule_CreateStringFromString`

    RedisModuleString *RedisModule_CreateStringFromString(RedisModuleCtx *ctx,
                                                          const RedisModuleString *str);

**Available since:** 4.0.0

Like `RedisModule_CreatString()`, but creates a string starting from another
`RedisModuleString`.

The returned string must be released with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by
enabling automatic memory management.

The passed context 'ctx' may be NULL if necessary, see the
[`RedisModule_CreateString()`](#RedisModule_CreateString) documentation for more info.

<span id="RedisModule_CreateStringFromStreamID"></span>

### `RedisModule_CreateStringFromStreamID`

    RedisModuleString *RedisModule_CreateStringFromStreamID(RedisModuleCtx *ctx,
                                                            const RedisModuleStreamID *id);

**Available since:** 6.2.0

Creates a string from a stream ID. The returned string must be released with
[`RedisModule_FreeString()`](#RedisModule_FreeString), unless automatic memory is enabled.

The passed context `ctx` may be NULL if necessary. See the
[`RedisModule_CreateString()`](#RedisModule_CreateString) documentation for more info.

<span id="RedisModule_FreeString"></span>

### `RedisModule_FreeString`

    void RedisModule_FreeString(RedisModuleCtx *ctx, RedisModuleString *str);

**Available since:** 4.0.0

Free a module string object obtained with one of the Redis modules API calls
that return new string objects.

It is possible to call this function even when automatic memory management
is enabled. In that case the string will be released ASAP and removed
from the pool of string to release at the end.

If the string was created with a NULL context 'ctx', it is also possible to
pass ctx as NULL when releasing the string (but passing a context will not
create any issue). Strings created with a context should be freed also passing
the context, so if you want to free a string out of context later, make sure
to create it using a NULL context.

<span id="RedisModule_RetainString"></span>

### `RedisModule_RetainString`

    void RedisModule_RetainString(RedisModuleCtx *ctx, RedisModuleString *str);

**Available since:** 4.0.0

Every call to this function, will make the string 'str' requiring
an additional call to [`RedisModule_FreeString()`](#RedisModule_FreeString) in order to really
free the string. Note that the automatic freeing of the string obtained
enabling modules automatic memory management counts for one
[`RedisModule_FreeString()`](#RedisModule_FreeString) call (it is just executed automatically).

Normally you want to call this function when, at the same time
the following conditions are true:

1. You have automatic memory management enabled.
2. You want to create string objects.
3. Those string objects you create need to live *after* the callback
   function(for example a command implementation) creating them returns.

Usually you want this in order to store the created string object
into your own data structure, for example when implementing a new data
type.

Note that when memory management is turned off, you don't need
any call to RetainString() since creating a string will always result
into a string that lives after the callback function returns, if
no FreeString() call is performed.

It is possible to call this function with a NULL context.

When strings are going to be retained for an extended duration, it is good
practice to also call [`RedisModule_TrimStringAllocation()`](#RedisModule_TrimStringAllocation) in order to
optimize memory usage.

Threaded modules that reference retained strings from other threads *must*
explicitly trim the allocation as soon as the string is retained. Not doing
so may result with automatic trimming which is not thread safe.

<span id="RedisModule_HoldString"></span>

### `RedisModule_HoldString`

    RedisModuleString* RedisModule_HoldString(RedisModuleCtx *ctx,
                                              RedisModuleString *str);

**Available since:** 6.0.7


This function can be used instead of [`RedisModule_RetainString()`](#RedisModule_RetainString).
The main difference between the two is that this function will always
succeed, whereas [`RedisModule_RetainString()`](#RedisModule_RetainString) may fail because of an
assertion.

The function returns a pointer to `RedisModuleString`, which is owned
by the caller. It requires a call to [`RedisModule_FreeString()`](#RedisModule_FreeString) to free
the string when automatic memory management is disabled for the context.
When automatic memory management is enabled, you can either call
[`RedisModule_FreeString()`](#RedisModule_FreeString) or let the automation free it.

This function is more efficient than [`RedisModule_CreateStringFromString()`](#RedisModule_CreateStringFromString)
because whenever possible, it avoids copying the underlying
`RedisModuleString`. The disadvantage of using this function is that it
might not be possible to use [`RedisModule_StringAppendBuffer()`](#RedisModule_StringAppendBuffer) on the
returned `RedisModuleString`.

It is possible to call this function with a NULL context.

When strings are going to be held for an extended duration, it is good
practice to also call [`RedisModule_TrimStringAllocation()`](#RedisModule_TrimStringAllocation) in order to
optimize memory usage.

Threaded modules that reference held strings from other threads *must*
explicitly trim the allocation as soon as the string is held. Not doing
so may result with automatic trimming which is not thread safe.

<span id="RedisModule_StringPtrLen"></span>

### `RedisModule_StringPtrLen`

    const char *RedisModule_StringPtrLen(const RedisModuleString *str,
                                         size_t *len);

**Available since:** 4.0.0

Given a string module object, this function returns the string pointer
and length of the string. The returned pointer and length should only
be used for read only accesses and never modified.

<span id="RedisModule_StringToLongLong"></span>

### `RedisModule_StringToLongLong`

    int RedisModule_StringToLongLong(const RedisModuleString *str, long long *ll);

**Available since:** 4.0.0

Convert the string into a `long long` integer, storing it at `*ll`.
Returns `REDISMODULE_OK` on success. If the string can't be parsed
as a valid, strict `long long` (no spaces before/after), `REDISMODULE_ERR`
is returned.

<span id="RedisModule_StringToDouble"></span>

### `RedisModule_StringToDouble`

    int RedisModule_StringToDouble(const RedisModuleString *str, double *d);

**Available since:** 4.0.0

Convert the string into a double, storing it at `*d`.
Returns `REDISMODULE_OK` on success or `REDISMODULE_ERR` if the string is
not a valid string representation of a double value.

<span id="RedisModule_StringToLongDouble"></span>

### `RedisModule_StringToLongDouble`

    int RedisModule_StringToLongDouble(const RedisModuleString *str,
                                       long double *ld);

**Available since:** 6.0.0

Convert the string into a long double, storing it at `*ld`.
Returns `REDISMODULE_OK` on success or `REDISMODULE_ERR` if the string is
not a valid string representation of a double value.

<span id="RedisModule_StringToStreamID"></span>

### `RedisModule_StringToStreamID`

    int RedisModule_StringToStreamID(const RedisModuleString *str,
                                     RedisModuleStreamID *id);

**Available since:** 6.2.0

Convert the string into a stream ID, storing it at `*id`.
Returns `REDISMODULE_OK` on success and returns `REDISMODULE_ERR` if the string
is not a valid string representation of a stream ID. The special IDs "+" and
"-" are allowed.

<span id="RedisModule_StringCompare"></span>

### `RedisModule_StringCompare`

    int RedisModule_StringCompare(RedisModuleString *a, RedisModuleString *b);

**Available since:** 4.0.0

Compare two string objects, returning -1, 0 or 1 respectively if
a < b, a == b, a > b. Strings are compared byte by byte as two
binary blobs without any encoding care / collation attempt.

<span id="RedisModule_StringAppendBuffer"></span>

### `RedisModule_StringAppendBuffer`

    int RedisModule_StringAppendBuffer(RedisModuleCtx *ctx,
                                       RedisModuleString *str,
                                       const char *buf,
                                       size_t len);

**Available since:** 4.0.0

Append the specified buffer to the string 'str'. The string must be a
string created by the user that is referenced only a single time, otherwise
`REDISMODULE_ERR` is returned and the operation is not performed.

<span id="RedisModule_TrimStringAllocation"></span>

### `RedisModule_TrimStringAllocation`

    void RedisModule_TrimStringAllocation(RedisModuleString *str);

**Available since:** 7.0.0

Trim possible excess memory allocated for a `RedisModuleString`.

Sometimes a `RedisModuleString` may have more memory allocated for
it than required, typically for argv arguments that were constructed
from network buffers. This function optimizes such strings by reallocating
their memory, which is useful for strings that are not short lived but
retained for an extended duration.

This operation is *not thread safe* and should only be called when
no concurrent access to the string is guaranteed. Using it for an argv
string in a module command before the string is potentially available
to other threads is generally safe.

Currently, Redis may also automatically trim retained strings when a
module command returns. However, doing this explicitly should still be
a preferred option:

1. Future versions of Redis may abandon auto-trimming.
2. Auto-trimming as currently implemented is *not thread safe*.
   A background thread manipulating a recently retained string may end up
   in a race condition with the auto-trim, which could result with
   data corruption.

<span id="section-reply-apis"></span>

## Reply APIs

These functions are used for sending replies to the client.

Most functions always return `REDISMODULE_OK` so you can use it with
'return' in order to return from the command implementation with:

    if (... some condition ...)
        return RedisModule_ReplyWithLongLong(ctx,mycount);

### Reply with collection functions

After starting a collection reply, the module must make calls to other
`ReplyWith*` style functions in order to emit the elements of the collection.
Collection types include: Array, Map, Set and Attribute.

When producing collections with a number of elements that is not known
beforehand, the function can be called with a special flag
`REDISMODULE_POSTPONED_LEN` (`REDISMODULE_POSTPONED_ARRAY_LEN` in the past),
and the actual number of elements can be later set with `RedisModule_ReplySet`*Length()
call (which will set the latest "open" count if there are multiple ones).

<span id="RedisModule_WrongArity"></span>

### `RedisModule_WrongArity`

    int RedisModule_WrongArity(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Send an error about the number of arguments given to the command,
citing the command name in the error message. Returns `REDISMODULE_OK`.

Example:

    if (argc != 3) return RedisModule_WrongArity(ctx);

<span id="RedisModule_ReplyWithLongLong"></span>

### `RedisModule_ReplyWithLongLong`

    int RedisModule_ReplyWithLongLong(RedisModuleCtx *ctx, long long ll);

**Available since:** 4.0.0

Send an integer reply to the client, with the specified `long long` value.
The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithError"></span>

### `RedisModule_ReplyWithError`

    int RedisModule_ReplyWithError(RedisModuleCtx *ctx, const char *err);

**Available since:** 4.0.0

Reply with the error 'err'.

Note that 'err' must contain all the error, including
the initial error code. The function only provides the initial "-", so
the usage is, for example:

    RedisModule_ReplyWithError(ctx,"ERR Wrong Type");

and not just:

    RedisModule_ReplyWithError(ctx,"Wrong Type");

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithSimpleString"></span>

### `RedisModule_ReplyWithSimpleString`

    int RedisModule_ReplyWithSimpleString(RedisModuleCtx *ctx, const char *msg);

**Available since:** 4.0.0

Reply with a simple string (`+... \r\n` in RESP protocol). This replies
are suitable only when sending a small non-binary string with small
overhead, like "OK" or similar replies.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithArray"></span>

### `RedisModule_ReplyWithArray`

    int RedisModule_ReplyWithArray(RedisModuleCtx *ctx, long len);

**Available since:** 4.0.0

Reply with an array type of 'len' elements.

After starting an array reply, the module must make `len` calls to other
`ReplyWith*` style functions in order to emit the elements of the array.
See Reply APIs section for more details.

Use [`RedisModule_ReplySetArrayLength()`](#RedisModule_ReplySetArrayLength) to set deferred length.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithMap"></span>

### `RedisModule_ReplyWithMap`

    int RedisModule_ReplyWithMap(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Reply with a RESP3 Map type of 'len' pairs.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

After starting a map reply, the module must make `len*2` calls to other
`ReplyWith*` style functions in order to emit the elements of the map.
See Reply APIs section for more details.

If the connected client is using RESP2, the reply will be converted to a flat
array.

Use [`RedisModule_ReplySetMapLength()`](#RedisModule_ReplySetMapLength) to set deferred length.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithSet"></span>

### `RedisModule_ReplyWithSet`

    int RedisModule_ReplyWithSet(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Reply with a RESP3 Set type of 'len' elements.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

After starting a set reply, the module must make `len` calls to other
`ReplyWith*` style functions in order to emit the elements of the set.
See Reply APIs section for more details.

If the connected client is using RESP2, the reply will be converted to an
array type.

Use [`RedisModule_ReplySetSetLength()`](#RedisModule_ReplySetSetLength) to set deferred length.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithAttribute"></span>

### `RedisModule_ReplyWithAttribute`

    int RedisModule_ReplyWithAttribute(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Add attributes (metadata) to the reply. Should be done before adding the
actual reply. see [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md)#attribute-type

After starting an attributes reply, the module must make `len*2` calls to other
`ReplyWith*` style functions in order to emit the elements of the attribute map.
See Reply APIs section for more details.

Use [`RedisModule_ReplySetAttributeLength()`](#RedisModule_ReplySetAttributeLength) to set deferred length.

Not supported by RESP2 and will return `REDISMODULE_ERR`, otherwise
the function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithNullArray"></span>

### `RedisModule_ReplyWithNullArray`

    int RedisModule_ReplyWithNullArray(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Reply to the client with a null array, simply null in RESP3,
null array in RESP2.

Note: In RESP3 there's no difference between Null reply and
NullArray reply, so to prevent ambiguity it's better to avoid
using this API and use [`RedisModule_ReplyWithNull`](#RedisModule_ReplyWithNull) instead.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithEmptyArray"></span>

### `RedisModule_ReplyWithEmptyArray`

    int RedisModule_ReplyWithEmptyArray(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Reply to the client with an empty array.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplySetArrayLength"></span>

### `RedisModule_ReplySetArrayLength`

    void RedisModule_ReplySetArrayLength(RedisModuleCtx *ctx, long len);

**Available since:** 4.0.0

When [`RedisModule_ReplyWithArray()`](#RedisModule_ReplyWithArray) is used with the argument
`REDISMODULE_POSTPONED_LEN`, because we don't know beforehand the number
of items we are going to output as elements of the array, this function
will take care to set the array length.

Since it is possible to have multiple array replies pending with unknown
length, this function guarantees to always set the latest array length
that was created in a postponed way.

For example in order to output an array like [1,[10,20,30]] we
could write:

     RedisModule_ReplyWithArray(ctx,REDISMODULE_POSTPONED_LEN);
     RedisModule_ReplyWithLongLong(ctx,1);
     RedisModule_ReplyWithArray(ctx,REDISMODULE_POSTPONED_LEN);
     RedisModule_ReplyWithLongLong(ctx,10);
     RedisModule_ReplyWithLongLong(ctx,20);
     RedisModule_ReplyWithLongLong(ctx,30);
     RedisModule_ReplySetArrayLength(ctx,3); // Set len of 10,20,30 array.
     RedisModule_ReplySetArrayLength(ctx,2); // Set len of top array

Note that in the above example there is no reason to postpone the array
length, since we produce a fixed number of elements, but in the practice
the code may use an iterator or other ways of creating the output so
that is not easy to calculate in advance the number of elements.

<span id="RedisModule_ReplySetMapLength"></span>

### `RedisModule_ReplySetMapLength`

    void RedisModule_ReplySetMapLength(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Very similar to [`RedisModule_ReplySetArrayLength`](#RedisModule_ReplySetArrayLength) except `len` should
exactly half of the number of `ReplyWith*` functions called in the
context of the map.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

<span id="RedisModule_ReplySetSetLength"></span>

### `RedisModule_ReplySetSetLength`

    void RedisModule_ReplySetSetLength(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Very similar to [`RedisModule_ReplySetArrayLength`](#RedisModule_ReplySetArrayLength)
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

<span id="RedisModule_ReplySetAttributeLength"></span>

### `RedisModule_ReplySetAttributeLength`

    void RedisModule_ReplySetAttributeLength(RedisModuleCtx *ctx, long len);

**Available since:** 7.0.0

Very similar to [`RedisModule_ReplySetMapLength`](#RedisModule_ReplySetMapLength)
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

Must not be called if [`RedisModule_ReplyWithAttribute`](#RedisModule_ReplyWithAttribute) returned an error.

<span id="RedisModule_ReplyWithStringBuffer"></span>

### `RedisModule_ReplyWithStringBuffer`

    int RedisModule_ReplyWithStringBuffer(RedisModuleCtx *ctx,
                                          const char *buf,
                                          size_t len);

**Available since:** 4.0.0

Reply with a bulk string, taking in input a C buffer pointer and length.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithCString"></span>

### `RedisModule_ReplyWithCString`

    int RedisModule_ReplyWithCString(RedisModuleCtx *ctx, const char *buf);

**Available since:** 5.0.6

Reply with a bulk string, taking in input a C buffer pointer that is
assumed to be null-terminated.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithString"></span>

### `RedisModule_ReplyWithString`

    int RedisModule_ReplyWithString(RedisModuleCtx *ctx, RedisModuleString *str);

**Available since:** 4.0.0

Reply with a bulk string, taking in input a `RedisModuleString` object.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithEmptyString"></span>

### `RedisModule_ReplyWithEmptyString`

    int RedisModule_ReplyWithEmptyString(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Reply with an empty string.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithVerbatimStringType"></span>

### `RedisModule_ReplyWithVerbatimStringType`

    int RedisModule_ReplyWithVerbatimStringType(RedisModuleCtx *ctx,
                                                const char *buf,
                                                size_t len,
                                                const char *ext);

**Available since:** 7.0.0

Reply with a binary safe string, which should not be escaped or filtered
taking in input a C buffer pointer, length and a 3 character type/extension.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithVerbatimString"></span>

### `RedisModule_ReplyWithVerbatimString`

    int RedisModule_ReplyWithVerbatimString(RedisModuleCtx *ctx,
                                            const char *buf,
                                            size_t len);

**Available since:** 6.0.0

Reply with a binary safe string, which should not be escaped or filtered
taking in input a C buffer pointer and length.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithNull"></span>

### `RedisModule_ReplyWithNull`

    int RedisModule_ReplyWithNull(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Reply to the client with a NULL.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithBool"></span>

### `RedisModule_ReplyWithBool`

    int RedisModule_ReplyWithBool(RedisModuleCtx *ctx, int b);

**Available since:** 7.0.0

Reply with a RESP3 Boolean type.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

In RESP3, this is boolean type
In RESP2, it's a string response of "1" and "0" for true and false respectively.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithCallReply"></span>

### `RedisModule_ReplyWithCallReply`

    int RedisModule_ReplyWithCallReply(RedisModuleCtx *ctx,
                                       RedisModuleCallReply *reply);

**Available since:** 4.0.0

Reply exactly what a Redis command returned us with [`RedisModule_Call()`](#RedisModule_Call).
This function is useful when we use [`RedisModule_Call()`](#RedisModule_Call) in order to
execute some command, as we want to reply to the client exactly the
same reply we obtained by the command.

Return:
- `REDISMODULE_OK` on success.
- `REDISMODULE_ERR` if the given reply is in RESP3 format but the client expects RESP2.
  In case of an error, it's the module writer responsibility to translate the reply
  to RESP2 (or handle it differently by returning an error). Notice that for
  module writer convenience, it is possible to pass `0` as a parameter to the fmt
  argument of `RM_Call` so that the `RedisModuleCallReply` will return in the same
  protocol (RESP2 or RESP3) as set in the current client's context.

<span id="RedisModule_ReplyWithDouble"></span>

### `RedisModule_ReplyWithDouble`

    int RedisModule_ReplyWithDouble(RedisModuleCtx *ctx, double d);

**Available since:** 4.0.0

Reply with a RESP3 Double type.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

Send a string reply obtained converting the double 'd' into a bulk string.
This function is basically equivalent to converting a double into
a string into a C buffer, and then calling the function
[`RedisModule_ReplyWithStringBuffer()`](#RedisModule_ReplyWithStringBuffer) with the buffer and length.

In RESP3 the string is tagged as a double, while in RESP2 it's just a plain string 
that the user will have to parse.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithBigNumber"></span>

### `RedisModule_ReplyWithBigNumber`

    int RedisModule_ReplyWithBigNumber(RedisModuleCtx *ctx,
                                       const char *bignum,
                                       size_t len);

**Available since:** 7.0.0

Reply with a RESP3 BigNumber type.
Visit [https://github.com/antirez/RESP3/blob/master/spec.md](https://github.com/antirez/RESP3/blob/master/spec.md) for more info about RESP3.

In RESP3, this is a string of length `len` that is tagged as a BigNumber, 
however, it's up to the caller to ensure that it's a valid BigNumber.
In RESP2, this is just a plain bulk string response.

The function always returns `REDISMODULE_OK`.

<span id="RedisModule_ReplyWithLongDouble"></span>

### `RedisModule_ReplyWithLongDouble`

    int RedisModule_ReplyWithLongDouble(RedisModuleCtx *ctx, long double ld);

**Available since:** 6.0.0

Send a string reply obtained converting the long double 'ld' into a bulk
string. This function is basically equivalent to converting a long double
into a string into a C buffer, and then calling the function
[`RedisModule_ReplyWithStringBuffer()`](#RedisModule_ReplyWithStringBuffer) with the buffer and length.
The double string uses human readable formatting (see
`addReplyHumanLongDouble` in networking.c).

The function always returns `REDISMODULE_OK`.

<span id="section-commands-replication-api"></span>

## Commands replication API

<span id="RedisModule_Replicate"></span>

### `RedisModule_Replicate`

    int RedisModule_Replicate(RedisModuleCtx *ctx,
                              const char *cmdname,
                              const char *fmt,
                              ...);

**Available since:** 4.0.0

Replicate the specified command and arguments to slaves and AOF, as effect
of execution of the calling command implementation.

The replicated commands are always wrapped into the MULTI/EXEC that
contains all the commands replicated in a given module command
execution. However the commands replicated with [`RedisModule_Call()`](#RedisModule_Call)
are the first items, the ones replicated with [`RedisModule_Replicate()`](#RedisModule_Replicate)
will all follow before the EXEC.

Modules should try to use one interface or the other.

This command follows exactly the same interface of [`RedisModule_Call()`](#RedisModule_Call),
so a set of format specifiers must be passed, followed by arguments
matching the provided format specifiers.

Please refer to [`RedisModule_Call()`](#RedisModule_Call) for more information.

Using the special "A" and "R" modifiers, the caller can exclude either
the AOF or the replicas from the propagation of the specified command.
Otherwise, by default, the command will be propagated in both channels.

#### Note about calling this function from a thread safe context:

Normally when you call this function from the callback implementing a
module command, or any other callback provided by the Redis Module API,
Redis will accumulate all the calls to this function in the context of
the callback, and will propagate all the commands wrapped in a MULTI/EXEC
transaction. However when calling this function from a threaded safe context
that can live an undefined amount of time, and can be locked/unlocked in
at will, the behavior is different: MULTI/EXEC wrapper is not emitted
and the command specified is inserted in the AOF and replication stream
immediately.

#### Return value

The command returns `REDISMODULE_ERR` if the format specifiers are invalid
or the command name does not belong to a known command.

<span id="RedisModule_ReplicateVerbatim"></span>

### `RedisModule_ReplicateVerbatim`

    int RedisModule_ReplicateVerbatim(RedisModuleCtx *ctx);

**Available since:** 4.0.0

This function will replicate the command exactly as it was invoked
by the client. Note that this function will not wrap the command into
a MULTI/EXEC stanza, so it should not be mixed with other replication
commands.

Basically this form of replication is useful when you want to propagate
the command to the slaves and AOF file exactly as it was called, since
the command can just be re-executed to deterministically re-create the
new state starting from the old one.

The function always returns `REDISMODULE_OK`.

<span id="section-db-and-key-apis-generic-api"></span>

## DB and Key APIs – Generic API

<span id="RedisModule_GetClientId"></span>

### `RedisModule_GetClientId`

    unsigned long long RedisModule_GetClientId(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Return the ID of the current client calling the currently active module
command. The returned ID has a few guarantees:

1. The ID is different for each different client, so if the same client
   executes a module command multiple times, it can be recognized as
   having the same ID, otherwise the ID will be different.
2. The ID increases monotonically. Clients connecting to the server later
   are guaranteed to get IDs greater than any past ID previously seen.

Valid IDs are from 1 to 2^64 - 1. If 0 is returned it means there is no way
to fetch the ID in the context the function was currently called.

After obtaining the ID, it is possible to check if the command execution
is actually happening in the context of AOF loading, using this macro:

     if (RedisModule_IsAOFClient(RedisModule_GetClientId(ctx)) {
         // Handle it differently.
     }

<span id="RedisModule_GetClientUserNameById"></span>

### `RedisModule_GetClientUserNameById`

    RedisModuleString *RedisModule_GetClientUserNameById(RedisModuleCtx *ctx,
                                                         uint64_t id);

**Available since:** 6.2.1

Return the ACL user name used by the client with the specified client ID.
Client ID can be obtained with [`RedisModule_GetClientId()`](#RedisModule_GetClientId) API. If the client does not
exist, NULL is returned and errno is set to ENOENT. If the client isn't
using an ACL user, NULL is returned and errno is set to ENOTSUP

<span id="RedisModule_GetClientInfoById"></span>

### `RedisModule_GetClientInfoById`

    int RedisModule_GetClientInfoById(void *ci, uint64_t id);

**Available since:** 6.0.0

Return information about the client with the specified ID (that was
previously obtained via the [`RedisModule_GetClientId()`](#RedisModule_GetClientId) API). If the
client exists, `REDISMODULE_OK` is returned, otherwise `REDISMODULE_ERR`
is returned.

When the client exist and the `ci` pointer is not NULL, but points to
a structure of type `RedisModuleClientInfo`, previously initialized with
the correct `REDISMODULE_CLIENTINFO_INITIALIZER`, the structure is populated
with the following fields:

     uint64_t flags;         // REDISMODULE_CLIENTINFO_FLAG_*
     uint64_t id;            // Client ID
     char addr[46];          // IPv4 or IPv6 address.
     uint16_t port;          // TCP port.
     uint16_t db;            // Selected DB.

Note: the client ID is useless in the context of this call, since we
      already know, however the same structure could be used in other
      contexts where we don't know the client ID, yet the same structure
      is returned.

With flags having the following meaning:

    REDISMODULE_CLIENTINFO_FLAG_SSL          Client using SSL connection.
    REDISMODULE_CLIENTINFO_FLAG_PUBSUB       Client in Pub/Sub mode.
    REDISMODULE_CLIENTINFO_FLAG_BLOCKED      Client blocked in command.
    REDISMODULE_CLIENTINFO_FLAG_TRACKING     Client with keys tracking on.
    REDISMODULE_CLIENTINFO_FLAG_UNIXSOCKET   Client using unix domain socket.
    REDISMODULE_CLIENTINFO_FLAG_MULTI        Client in MULTI state.

However passing NULL is a way to just check if the client exists in case
we are not interested in any additional information.

This is the correct usage when we want the client info structure
returned:

     RedisModuleClientInfo ci = REDISMODULE_CLIENTINFO_INITIALIZER;
     int retval = RedisModule_GetClientInfoById(&ci,client_id);
     if (retval == REDISMODULE_OK) {
         printf("Address: %s\n", ci.addr);
     }

<span id="RedisModule_PublishMessage"></span>

### `RedisModule_PublishMessage`

    int RedisModule_PublishMessage(RedisModuleCtx *ctx,
                                   RedisModuleString *channel,
                                   RedisModuleString *message);

**Available since:** 6.0.0

Publish a message to subscribers (see PUBLISH command).

<span id="RedisModule_PublishMessageShard"></span>

### `RedisModule_PublishMessageShard`

    int RedisModule_PublishMessageShard(RedisModuleCtx *ctx,
                                        RedisModuleString *channel,
                                        RedisModuleString *message);

**Available since:** 7.0.0

Publish a message to shard-subscribers (see SPUBLISH command).

<span id="RedisModule_GetSelectedDb"></span>

### `RedisModule_GetSelectedDb`

    int RedisModule_GetSelectedDb(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Return the currently selected DB.

<span id="RedisModule_GetContextFlags"></span>

### `RedisModule_GetContextFlags`

    int RedisModule_GetContextFlags(RedisModuleCtx *ctx);

**Available since:** 4.0.3

Return the current context's flags. The flags provide information on the
current request context (whether the client is a Lua script or in a MULTI),
and about the Redis instance in general, i.e replication and persistence.

It is possible to call this function even with a NULL context, however
in this case the following flags will not be reported:

 * LUA, MULTI, REPLICATED, DIRTY (see below for more info).

Available flags and their meaning:

 * `REDISMODULE_CTX_FLAGS_LUA`: The command is running in a Lua script

 * `REDISMODULE_CTX_FLAGS_MULTI`: The command is running inside a transaction

 * `REDISMODULE_CTX_FLAGS_REPLICATED`: The command was sent over the replication
   link by the MASTER

 * `REDISMODULE_CTX_FLAGS_MASTER`: The Redis instance is a master

 * `REDISMODULE_CTX_FLAGS_SLAVE`: The Redis instance is a slave

 * `REDISMODULE_CTX_FLAGS_READONLY`: The Redis instance is read-only

 * `REDISMODULE_CTX_FLAGS_CLUSTER`: The Redis instance is in cluster mode

 * `REDISMODULE_CTX_FLAGS_AOF`: The Redis instance has AOF enabled

 * `REDISMODULE_CTX_FLAGS_RDB`: The instance has RDB enabled

 * `REDISMODULE_CTX_FLAGS_MAXMEMORY`:  The instance has Maxmemory set

 * `REDISMODULE_CTX_FLAGS_EVICT`:  Maxmemory is set and has an eviction
   policy that may delete keys

 * `REDISMODULE_CTX_FLAGS_OOM`: Redis is out of memory according to the
   maxmemory setting.

 * `REDISMODULE_CTX_FLAGS_OOM_WARNING`: Less than 25% of memory remains before
                                      reaching the maxmemory level.

 * `REDISMODULE_CTX_FLAGS_LOADING`: Server is loading RDB/AOF

 * `REDISMODULE_CTX_FLAGS_REPLICA_IS_STALE`: No active link with the master.

 * `REDISMODULE_CTX_FLAGS_REPLICA_IS_CONNECTING`: The replica is trying to
                                                connect with the master.

 * `REDISMODULE_CTX_FLAGS_REPLICA_IS_TRANSFERRING`: Master -> Replica RDB
                                                  transfer is in progress.

 * `REDISMODULE_CTX_FLAGS_REPLICA_IS_ONLINE`: The replica has an active link
                                            with its master. This is the
                                            contrary of STALE state.

 * `REDISMODULE_CTX_FLAGS_ACTIVE_CHILD`: There is currently some background
                                       process active (RDB, AUX or module).

 * `REDISMODULE_CTX_FLAGS_MULTI_DIRTY`: The next EXEC will fail due to dirty
                                      CAS (touched keys).

 * `REDISMODULE_CTX_FLAGS_IS_CHILD`: Redis is currently running inside
                                   background child process.

 * `REDISMODULE_CTX_FLAGS_RESP3`: Indicate the that client attached to this
                                context is using RESP3.

<span id="RedisModule_AvoidReplicaTraffic"></span>

### `RedisModule_AvoidReplicaTraffic`

    int RedisModule_AvoidReplicaTraffic();

**Available since:** 6.0.0

Returns true if a client sent the CLIENT PAUSE command to the server or
if Redis Cluster does a manual failover, pausing the clients.
This is needed when we have a master with replicas, and want to write,
without adding further data to the replication channel, that the replicas
replication offset, match the one of the master. When this happens, it is
safe to failover the master without data loss.

However modules may generate traffic by calling [`RedisModule_Call()`](#RedisModule_Call) with
the "!" flag, or by calling [`RedisModule_Replicate()`](#RedisModule_Replicate), in a context outside
commands execution, for instance in timeout callbacks, threads safe
contexts, and so forth. When modules will generate too much traffic, it
will be hard for the master and replicas offset to match, because there
is more data to send in the replication channel.

So modules may want to try to avoid very heavy background work that has
the effect of creating data to the replication channel, when this function
returns true. This is mostly useful for modules that have background
garbage collection tasks, or that do writes and replicate such writes
periodically in timer callbacks or other periodic callbacks.

<span id="RedisModule_SelectDb"></span>

### `RedisModule_SelectDb`

    int RedisModule_SelectDb(RedisModuleCtx *ctx, int newid);

**Available since:** 4.0.0

Change the currently selected DB. Returns an error if the id
is out of range.

Note that the client will retain the currently selected DB even after
the Redis command implemented by the module calling this function
returns.

If the module command wishes to change something in a different DB and
returns back to the original one, it should call [`RedisModule_GetSelectedDb()`](#RedisModule_GetSelectedDb)
before in order to restore the old DB number before returning.

<span id="RedisModule_KeyExists"></span>

### `RedisModule_KeyExists`

    int RedisModule_KeyExists(RedisModuleCtx *ctx, robj *keyname);

**Available since:** 7.0.0

Check if a key exists, without affecting its last access time.

This is equivalent to calling [`RedisModule_OpenKey`](#RedisModule_OpenKey) with the mode `REDISMODULE_READ` |
`REDISMODULE_OPEN_KEY_NOTOUCH`, then checking if NULL was returned and, if not,
calling [`RedisModule_CloseKey`](#RedisModule_CloseKey) on the opened key.

<span id="RedisModule_OpenKey"></span>

### `RedisModule_OpenKey`

    RedisModuleKey *RedisModule_OpenKey(RedisModuleCtx *ctx,
                                        robj *keyname,
                                        int mode);

**Available since:** 4.0.0

Return a handle representing a Redis key, so that it is possible
to call other APIs with the key handle as argument to perform
operations on the key.

The return value is the handle representing the key, that must be
closed with [`RedisModule_CloseKey()`](#RedisModule_CloseKey).

If the key does not exist and WRITE mode is requested, the handle
is still returned, since it is possible to perform operations on
a yet not existing key (that will be created, for example, after
a list push operation). If the mode is just READ instead, and the
key does not exist, NULL is returned. However it is still safe to
call [`RedisModule_CloseKey()`](#RedisModule_CloseKey) and [`RedisModule_KeyType()`](#RedisModule_KeyType) on a NULL
value.

<span id="RedisModule_CloseKey"></span>

### `RedisModule_CloseKey`

    void RedisModule_CloseKey(RedisModuleKey *key);

**Available since:** 4.0.0

Close a key handle.

<span id="RedisModule_KeyType"></span>

### `RedisModule_KeyType`

    int RedisModule_KeyType(RedisModuleKey *key);

**Available since:** 4.0.0

Return the type of the key. If the key pointer is NULL then
`REDISMODULE_KEYTYPE_EMPTY` is returned.

<span id="RedisModule_ValueLength"></span>

### `RedisModule_ValueLength`

    size_t RedisModule_ValueLength(RedisModuleKey *key);

**Available since:** 4.0.0

Return the length of the value associated with the key.
For strings this is the length of the string. For all the other types
is the number of elements (just counting keys for hashes).

If the key pointer is NULL or the key is empty, zero is returned.

<span id="RedisModule_DeleteKey"></span>

### `RedisModule_DeleteKey`

    int RedisModule_DeleteKey(RedisModuleKey *key);

**Available since:** 4.0.0

If the key is open for writing, remove it, and setup the key to
accept new writes as an empty key (that will be created on demand).
On success `REDISMODULE_OK` is returned. If the key is not open for
writing `REDISMODULE_ERR` is returned.

<span id="RedisModule_UnlinkKey"></span>

### `RedisModule_UnlinkKey`

    int RedisModule_UnlinkKey(RedisModuleKey *key);

**Available since:** 4.0.7

If the key is open for writing, unlink it (that is delete it in a
non-blocking way, not reclaiming memory immediately) and setup the key to
accept new writes as an empty key (that will be created on demand).
On success `REDISMODULE_OK` is returned. If the key is not open for
writing `REDISMODULE_ERR` is returned.

<span id="RedisModule_GetExpire"></span>

### `RedisModule_GetExpire`

    mstime_t RedisModule_GetExpire(RedisModuleKey *key);

**Available since:** 4.0.0

Return the key expire value, as milliseconds of remaining TTL.
If no TTL is associated with the key or if the key is empty,
`REDISMODULE_NO_EXPIRE` is returned.

<span id="RedisModule_SetExpire"></span>

### `RedisModule_SetExpire`

    int RedisModule_SetExpire(RedisModuleKey *key, mstime_t expire);

**Available since:** 4.0.0

Set a new expire for the key. If the special expire
`REDISMODULE_NO_EXPIRE` is set, the expire is cancelled if there was
one (the same as the PERSIST command).

Note that the expire must be provided as a positive integer representing
the number of milliseconds of TTL the key should have.

The function returns `REDISMODULE_OK` on success or `REDISMODULE_ERR` if
the key was not open for writing or is an empty key.

<span id="RedisModule_GetAbsExpire"></span>

### `RedisModule_GetAbsExpire`

    mstime_t RedisModule_GetAbsExpire(RedisModuleKey *key);

**Available since:** 6.2.2

Return the key expire value, as absolute Unix timestamp.
If no TTL is associated with the key or if the key is empty,
`REDISMODULE_NO_EXPIRE` is returned.

<span id="RedisModule_SetAbsExpire"></span>

### `RedisModule_SetAbsExpire`

    int RedisModule_SetAbsExpire(RedisModuleKey *key, mstime_t expire);

**Available since:** 6.2.2

Set a new expire for the key. If the special expire
`REDISMODULE_NO_EXPIRE` is set, the expire is cancelled if there was
one (the same as the PERSIST command).

Note that the expire must be provided as a positive integer representing
the absolute Unix timestamp the key should have.

The function returns `REDISMODULE_OK` on success or `REDISMODULE_ERR` if
the key was not open for writing or is an empty key.

<span id="RedisModule_ResetDataset"></span>

### `RedisModule_ResetDataset`

    void RedisModule_ResetDataset(int restart_aof, int async);

**Available since:** 6.0.0

Performs similar operation to FLUSHALL, and optionally start a new AOF file (if enabled)
If `restart_aof` is true, you must make sure the command that triggered this call is not
propagated to the AOF file.
When async is set to true, db contents will be freed by a background thread.

<span id="RedisModule_DbSize"></span>

### `RedisModule_DbSize`

    unsigned long long RedisModule_DbSize(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Returns the number of keys in the current db.

<span id="RedisModule_RandomKey"></span>

### `RedisModule_RandomKey`

    RedisModuleString *RedisModule_RandomKey(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Returns a name of a random key, or NULL if current db is empty.

<span id="RedisModule_GetKeyNameFromOptCtx"></span>

### `RedisModule_GetKeyNameFromOptCtx`

    const RedisModuleString *RedisModule_GetKeyNameFromOptCtx(RedisModuleKeyOptCtx *ctx);

**Available since:** 7.0.0

Returns the name of the key currently being processed.

<span id="RedisModule_GetToKeyNameFromOptCtx"></span>

### `RedisModule_GetToKeyNameFromOptCtx`

    const RedisModuleString *RedisModule_GetToKeyNameFromOptCtx(RedisModuleKeyOptCtx *ctx);

**Available since:** 7.0.0

Returns the name of the target key currently being processed.

<span id="RedisModule_GetDbIdFromOptCtx"></span>

### `RedisModule_GetDbIdFromOptCtx`

    int RedisModule_GetDbIdFromOptCtx(RedisModuleKeyOptCtx *ctx);

**Available since:** 7.0.0

Returns the dbid currently being processed.

<span id="RedisModule_GetToDbIdFromOptCtx"></span>

### `RedisModule_GetToDbIdFromOptCtx`

    int RedisModule_GetToDbIdFromOptCtx(RedisModuleKeyOptCtx *ctx);

**Available since:** 7.0.0

Returns the target dbid currently being processed.

<span id="section-key-api-for-string-type"></span>

## Key API for String type

See also [`RedisModule_ValueLength()`](#RedisModule_ValueLength), which returns the length of a string.

<span id="RedisModule_StringSet"></span>

### `RedisModule_StringSet`

    int RedisModule_StringSet(RedisModuleKey *key, RedisModuleString *str);

**Available since:** 4.0.0

If the key is open for writing, set the specified string 'str' as the
value of the key, deleting the old value if any.
On success `REDISMODULE_OK` is returned. If the key is not open for
writing or there is an active iterator, `REDISMODULE_ERR` is returned.

<span id="RedisModule_StringDMA"></span>

### `RedisModule_StringDMA`

    char *RedisModule_StringDMA(RedisModuleKey *key, size_t *len, int mode);

**Available since:** 4.0.0

Prepare the key associated string value for DMA access, and returns
a pointer and size (by reference), that the user can use to read or
modify the string in-place accessing it directly via pointer.

The 'mode' is composed by bitwise OR-ing the following flags:

    REDISMODULE_READ -- Read access
    REDISMODULE_WRITE -- Write access

If the DMA is not requested for writing, the pointer returned should
only be accessed in a read-only fashion.

On error (wrong type) NULL is returned.

DMA access rules:

1. No other key writing function should be called since the moment
the pointer is obtained, for all the time we want to use DMA access
to read or modify the string.

2. Each time [`RedisModule_StringTruncate()`](#RedisModule_StringTruncate) is called, to continue with the DMA
access, [`RedisModule_StringDMA()`](#RedisModule_StringDMA) should be called again to re-obtain
a new pointer and length.

3. If the returned pointer is not NULL, but the length is zero, no
byte can be touched (the string is empty, or the key itself is empty)
so a [`RedisModule_StringTruncate()`](#RedisModule_StringTruncate) call should be used if there is to enlarge
the string, and later call StringDMA() again to get the pointer.

<span id="RedisModule_StringTruncate"></span>

### `RedisModule_StringTruncate`

    int RedisModule_StringTruncate(RedisModuleKey *key, size_t newlen);

**Available since:** 4.0.0

If the key is open for writing and is of string type, resize it, padding
with zero bytes if the new length is greater than the old one.

After this call, [`RedisModule_StringDMA()`](#RedisModule_StringDMA) must be called again to continue
DMA access with the new pointer.

The function returns `REDISMODULE_OK` on success, and `REDISMODULE_ERR` on
error, that is, the key is not open for writing, is not a string
or resizing for more than 512 MB is requested.

If the key is empty, a string key is created with the new string value
unless the new length value requested is zero.

<span id="section-key-api-for-list-type"></span>

## Key API for List type

Many of the list functions access elements by index. Since a list is in
essence a doubly-linked list, accessing elements by index is generally an
O(N) operation. However, if elements are accessed sequentially or with
indices close together, the functions are optimized to seek the index from
the previous index, rather than seeking from the ends of the list.

This enables iteration to be done efficiently using a simple for loop:

    long n = RM_ValueLength(key);
    for (long i = 0; i < n; i++) {
        RedisModuleString *elem = RedisModule_ListGet(key, i);
        // Do stuff...
    }

Note that after modifying a list using [`RedisModule_ListPop`](#RedisModule_ListPop), [`RedisModule_ListSet`](#RedisModule_ListSet) or
[`RedisModule_ListInsert`](#RedisModule_ListInsert), the internal iterator is invalidated so the next operation
will require a linear seek.

Modifying a list in any another way, for example using [`RedisModule_Call()`](#RedisModule_Call), while a key
is open will confuse the internal iterator and may cause trouble if the key
is used after such modifications. The key must be reopened in this case.

See also [`RedisModule_ValueLength()`](#RedisModule_ValueLength), which returns the length of a list.

<span id="RedisModule_ListPush"></span>

### `RedisModule_ListPush`

    int RedisModule_ListPush(RedisModuleKey *key,
                             int where,
                             RedisModuleString *ele);

**Available since:** 4.0.0

Push an element into a list, on head or tail depending on 'where' argument
(`REDISMODULE_LIST_HEAD` or `REDISMODULE_LIST_TAIL`). If the key refers to an
empty key opened for writing, the key is created. On success, `REDISMODULE_OK`
is returned. On failure, `REDISMODULE_ERR` is returned and `errno` is set as
follows:

- EINVAL if key or ele is NULL.
- ENOTSUP if the key is of another type than list.
- EBADF if the key is not opened for writing.

Note: Before Redis 7.0, `errno` was not set by this function.

<span id="RedisModule_ListPop"></span>

### `RedisModule_ListPop`

    RedisModuleString *RedisModule_ListPop(RedisModuleKey *key, int where);

**Available since:** 4.0.0

Pop an element from the list, and returns it as a module string object
that the user should be free with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by enabling
automatic memory. The `where` argument specifies if the element should be
popped from the beginning or the end of the list (`REDISMODULE_LIST_HEAD` or
`REDISMODULE_LIST_TAIL`). On failure, the command returns NULL and sets
`errno` as follows:

- EINVAL if key is NULL.
- ENOTSUP if the key is empty or of another type than list.
- EBADF if the key is not opened for writing.

Note: Before Redis 7.0, `errno` was not set by this function.

<span id="RedisModule_ListGet"></span>

### `RedisModule_ListGet`

    RedisModuleString *RedisModule_ListGet(RedisModuleKey *key, long index);

**Available since:** 7.0.0

Returns the element at index `index` in the list stored at `key`, like the
LINDEX command. The element should be free'd using [`RedisModule_FreeString()`](#RedisModule_FreeString) or using
automatic memory management.

The index is zero-based, so 0 means the first element, 1 the second element
and so on. Negative indices can be used to designate elements starting at the
tail of the list. Here, -1 means the last element, -2 means the penultimate
and so forth.

When no value is found at the given key and index, NULL is returned and
`errno` is set as follows:

- EINVAL if key is NULL.
- ENOTSUP if the key is not a list.
- EBADF if the key is not opened for reading.
- EDOM if the index is not a valid index in the list.

<span id="RedisModule_ListSet"></span>

### `RedisModule_ListSet`

    int RedisModule_ListSet(RedisModuleKey *key,
                            long index,
                            RedisModuleString *value);

**Available since:** 7.0.0

Replaces the element at index `index` in the list stored at `key`.

The index is zero-based, so 0 means the first element, 1 the second element
and so on. Negative indices can be used to designate elements starting at the
tail of the list. Here, -1 means the last element, -2 means the penultimate
and so forth.

On success, `REDISMODULE_OK` is returned. On failure, `REDISMODULE_ERR` is
returned and `errno` is set as follows:

- EINVAL if key or value is NULL.
- ENOTSUP if the key is not a list.
- EBADF if the key is not opened for writing.
- EDOM if the index is not a valid index in the list.

<span id="RedisModule_ListInsert"></span>

### `RedisModule_ListInsert`

    int RedisModule_ListInsert(RedisModuleKey *key,
                               long index,
                               RedisModuleString *value);

**Available since:** 7.0.0

Inserts an element at the given index.

The index is zero-based, so 0 means the first element, 1 the second element
and so on. Negative indices can be used to designate elements starting at the
tail of the list. Here, -1 means the last element, -2 means the penultimate
and so forth. The index is the element's index after inserting it.

On success, `REDISMODULE_OK` is returned. On failure, `REDISMODULE_ERR` is
returned and `errno` is set as follows:

- EINVAL if key or value is NULL.
- ENOTSUP if the key of another type than list.
- EBADF if the key is not opened for writing.
- EDOM if the index is not a valid index in the list.

<span id="RedisModule_ListDelete"></span>

### `RedisModule_ListDelete`

    int RedisModule_ListDelete(RedisModuleKey *key, long index);

**Available since:** 7.0.0

Removes an element at the given index. The index is 0-based. A negative index
can also be used, counting from the end of the list.

On success, `REDISMODULE_OK` is returned. On failure, `REDISMODULE_ERR` is
returned and `errno` is set as follows:

- EINVAL if key or value is NULL.
- ENOTSUP if the key is not a list.
- EBADF if the key is not opened for writing.
- EDOM if the index is not a valid index in the list.

<span id="section-key-api-for-sorted-set-type"></span>

## Key API for Sorted Set type

See also [`RedisModule_ValueLength()`](#RedisModule_ValueLength), which returns the length of a sorted set.

<span id="RedisModule_ZsetAdd"></span>

### `RedisModule_ZsetAdd`

    int RedisModule_ZsetAdd(RedisModuleKey *key,
                            double score,
                            RedisModuleString *ele,
                            int *flagsptr);

**Available since:** 4.0.0

Add a new element into a sorted set, with the specified 'score'.
If the element already exists, the score is updated.

A new sorted set is created at value if the key is an empty open key
setup for writing.

Additional flags can be passed to the function via a pointer, the flags
are both used to receive input and to communicate state when the function
returns. 'flagsptr' can be NULL if no special flags are used.

The input flags are:

    REDISMODULE_ZADD_XX: Element must already exist. Do nothing otherwise.
    REDISMODULE_ZADD_NX: Element must not exist. Do nothing otherwise.
    REDISMODULE_ZADD_GT: If element exists, new score must be greater than the current score. 
                         Do nothing otherwise. Can optionally be combined with XX.
    REDISMODULE_ZADD_LT: If element exists, new score must be less than the current score.
                         Do nothing otherwise. Can optionally be combined with XX.

The output flags are:

    REDISMODULE_ZADD_ADDED: The new element was added to the sorted set.
    REDISMODULE_ZADD_UPDATED: The score of the element was updated.
    REDISMODULE_ZADD_NOP: No operation was performed because XX or NX flags.

On success the function returns `REDISMODULE_OK`. On the following errors
`REDISMODULE_ERR` is returned:

* The key was not opened for writing.
* The key is of the wrong type.
* 'score' double value is not a number (NaN).

<span id="RedisModule_ZsetIncrby"></span>

### `RedisModule_ZsetIncrby`

    int RedisModule_ZsetIncrby(RedisModuleKey *key,
                               double score,
                               RedisModuleString *ele,
                               int *flagsptr,
                               double *newscore);

**Available since:** 4.0.0

This function works exactly like [`RedisModule_ZsetAdd()`](#RedisModule_ZsetAdd), but instead of setting
a new score, the score of the existing element is incremented, or if the
element does not already exist, it is added assuming the old score was
zero.

The input and output flags, and the return value, have the same exact
meaning, with the only difference that this function will return
`REDISMODULE_ERR` even when 'score' is a valid double number, but adding it
to the existing score results into a NaN (not a number) condition.

This function has an additional field 'newscore', if not NULL is filled
with the new score of the element after the increment, if no error
is returned.

<span id="RedisModule_ZsetRem"></span>

### `RedisModule_ZsetRem`

    int RedisModule_ZsetRem(RedisModuleKey *key,
                            RedisModuleString *ele,
                            int *deleted);

**Available since:** 4.0.0

Remove the specified element from the sorted set.
The function returns `REDISMODULE_OK` on success, and `REDISMODULE_ERR`
on one of the following conditions:

* The key was not opened for writing.
* The key is of the wrong type.

The return value does NOT indicate the fact the element was really
removed (since it existed) or not, just if the function was executed
with success.

In order to know if the element was removed, the additional argument
'deleted' must be passed, that populates the integer by reference
setting it to 1 or 0 depending on the outcome of the operation.
The 'deleted' argument can be NULL if the caller is not interested
to know if the element was really removed.

Empty keys will be handled correctly by doing nothing.

<span id="RedisModule_ZsetScore"></span>

### `RedisModule_ZsetScore`

    int RedisModule_ZsetScore(RedisModuleKey *key,
                              RedisModuleString *ele,
                              double *score);

**Available since:** 4.0.0

On success retrieve the double score associated at the sorted set element
'ele' and returns `REDISMODULE_OK`. Otherwise `REDISMODULE_ERR` is returned
to signal one of the following conditions:

* There is no such element 'ele' in the sorted set.
* The key is not a sorted set.
* The key is an open empty key.

<span id="section-key-api-for-sorted-set-iterator"></span>

## Key API for Sorted Set iterator

<span id="RedisModule_ZsetRangeStop"></span>

### `RedisModule_ZsetRangeStop`

    void RedisModule_ZsetRangeStop(RedisModuleKey *key);

**Available since:** 4.0.0

Stop a sorted set iteration.

<span id="RedisModule_ZsetRangeEndReached"></span>

### `RedisModule_ZsetRangeEndReached`

    int RedisModule_ZsetRangeEndReached(RedisModuleKey *key);

**Available since:** 4.0.0

Return the "End of range" flag value to signal the end of the iteration.

<span id="RedisModule_ZsetFirstInScoreRange"></span>

### `RedisModule_ZsetFirstInScoreRange`

    int RedisModule_ZsetFirstInScoreRange(RedisModuleKey *key,
                                          double min,
                                          double max,
                                          int minex,
                                          int maxex);

**Available since:** 4.0.0

Setup a sorted set iterator seeking the first element in the specified
range. Returns `REDISMODULE_OK` if the iterator was correctly initialized
otherwise `REDISMODULE_ERR` is returned in the following conditions:

1. The value stored at key is not a sorted set or the key is empty.

The range is specified according to the two double values 'min' and 'max'.
Both can be infinite using the following two macros:

* `REDISMODULE_POSITIVE_INFINITE` for positive infinite value
* `REDISMODULE_NEGATIVE_INFINITE` for negative infinite value

'minex' and 'maxex' parameters, if true, respectively setup a range
where the min and max value are exclusive (not included) instead of
inclusive.

<span id="RedisModule_ZsetLastInScoreRange"></span>

### `RedisModule_ZsetLastInScoreRange`

    int RedisModule_ZsetLastInScoreRange(RedisModuleKey *key,
                                         double min,
                                         double max,
                                         int minex,
                                         int maxex);

**Available since:** 4.0.0

Exactly like [`RedisModule_ZsetFirstInScoreRange()`](#RedisModule_ZsetFirstInScoreRange) but the last element of
the range is selected for the start of the iteration instead.

<span id="RedisModule_ZsetFirstInLexRange"></span>

### `RedisModule_ZsetFirstInLexRange`

    int RedisModule_ZsetFirstInLexRange(RedisModuleKey *key,
                                        RedisModuleString *min,
                                        RedisModuleString *max);

**Available since:** 4.0.0

Setup a sorted set iterator seeking the first element in the specified
lexicographical range. Returns `REDISMODULE_OK` if the iterator was correctly
initialized otherwise `REDISMODULE_ERR` is returned in the
following conditions:

1. The value stored at key is not a sorted set or the key is empty.
2. The lexicographical range 'min' and 'max' format is invalid.

'min' and 'max' should be provided as two `RedisModuleString` objects
in the same format as the parameters passed to the ZRANGEBYLEX command.
The function does not take ownership of the objects, so they can be released
ASAP after the iterator is setup.

<span id="RedisModule_ZsetLastInLexRange"></span>

### `RedisModule_ZsetLastInLexRange`

    int RedisModule_ZsetLastInLexRange(RedisModuleKey *key,
                                       RedisModuleString *min,
                                       RedisModuleString *max);

**Available since:** 4.0.0

Exactly like [`RedisModule_ZsetFirstInLexRange()`](#RedisModule_ZsetFirstInLexRange) but the last element of
the range is selected for the start of the iteration instead.

<span id="RedisModule_ZsetRangeCurrentElement"></span>

### `RedisModule_ZsetRangeCurrentElement`

    RedisModuleString *RedisModule_ZsetRangeCurrentElement(RedisModuleKey *key,
                                                           double *score);

**Available since:** 4.0.0

Return the current sorted set element of an active sorted set iterator
or NULL if the range specified in the iterator does not include any
element.

<span id="RedisModule_ZsetRangeNext"></span>

### `RedisModule_ZsetRangeNext`

    int RedisModule_ZsetRangeNext(RedisModuleKey *key);

**Available since:** 4.0.0

Go to the next element of the sorted set iterator. Returns 1 if there was
a next element, 0 if we are already at the latest element or the range
does not include any item at all.

<span id="RedisModule_ZsetRangePrev"></span>

### `RedisModule_ZsetRangePrev`

    int RedisModule_ZsetRangePrev(RedisModuleKey *key);

**Available since:** 4.0.0

Go to the previous element of the sorted set iterator. Returns 1 if there was
a previous element, 0 if we are already at the first element or the range
does not include any item at all.

<span id="section-key-api-for-hash-type"></span>

## Key API for Hash type

See also [`RedisModule_ValueLength()`](#RedisModule_ValueLength), which returns the number of fields in a hash.

<span id="RedisModule_HashSet"></span>

### `RedisModule_HashSet`

    int RedisModule_HashSet(RedisModuleKey *key, int flags, ...);

**Available since:** 4.0.0

Set the field of the specified hash field to the specified value.
If the key is an empty key open for writing, it is created with an empty
hash value, in order to set the specified field.

The function is variadic and the user must specify pairs of field
names and values, both as `RedisModuleString` pointers (unless the
CFIELD option is set, see later). At the end of the field/value-ptr pairs,
NULL must be specified as last argument to signal the end of the arguments
in the variadic function.

Example to set the hash argv[1] to the value argv[2]:

     RedisModule_HashSet(key,REDISMODULE_HASH_NONE,argv[1],argv[2],NULL);

The function can also be used in order to delete fields (if they exist)
by setting them to the specified value of `REDISMODULE_HASH_DELETE`:

     RedisModule_HashSet(key,REDISMODULE_HASH_NONE,argv[1],
                         REDISMODULE_HASH_DELETE,NULL);

The behavior of the command changes with the specified flags, that can be
set to `REDISMODULE_HASH_NONE` if no special behavior is needed.

    REDISMODULE_HASH_NX: The operation is performed only if the field was not
                         already existing in the hash.
    REDISMODULE_HASH_XX: The operation is performed only if the field was
                         already existing, so that a new value could be
                         associated to an existing filed, but no new fields
                         are created.
    REDISMODULE_HASH_CFIELDS: The field names passed are null terminated C
                              strings instead of RedisModuleString objects.
    REDISMODULE_HASH_COUNT_ALL: Include the number of inserted fields in the
                                returned number, in addition to the number of
                                updated and deleted fields. (Added in Redis
                                6.2.)

Unless NX is specified, the command overwrites the old field value with
the new one.

When using `REDISMODULE_HASH_CFIELDS`, field names are reported using
normal C strings, so for example to delete the field "foo" the following
code can be used:

     RedisModule_HashSet(key,REDISMODULE_HASH_CFIELDS,"foo",
                         REDISMODULE_HASH_DELETE,NULL);

Return value:

The number of fields existing in the hash prior to the call, which have been
updated (its old value has been replaced by a new value) or deleted. If the
flag `REDISMODULE_HASH_COUNT_ALL` is set, inserted fields not previously
existing in the hash are also counted.

If the return value is zero, `errno` is set (since Redis 6.2) as follows:

- EINVAL if any unknown flags are set or if key is NULL.
- ENOTSUP if the key is associated with a non Hash value.
- EBADF if the key was not opened for writing.
- ENOENT if no fields were counted as described under Return value above.
  This is not actually an error. The return value can be zero if all fields
  were just created and the `COUNT_ALL` flag was unset, or if changes were held
  back due to the NX and XX flags.

NOTICE: The return value semantics of this function are very different
between Redis 6.2 and older versions. Modules that use it should determine
the Redis version and handle it accordingly.

<span id="RedisModule_HashGet"></span>

### `RedisModule_HashGet`

    int RedisModule_HashGet(RedisModuleKey *key, int flags, ...);

**Available since:** 4.0.0

Get fields from a hash value. This function is called using a variable
number of arguments, alternating a field name (as a `RedisModuleString`
pointer) with a pointer to a `RedisModuleString` pointer, that is set to the
value of the field if the field exists, or NULL if the field does not exist.
At the end of the field/value-ptr pairs, NULL must be specified as last
argument to signal the end of the arguments in the variadic function.

This is an example usage:

     RedisModuleString *first, *second;
     RedisModule_HashGet(mykey,REDISMODULE_HASH_NONE,argv[1],&first,
                         argv[2],&second,NULL);

As with [`RedisModule_HashSet()`](#RedisModule_HashSet) the behavior of the command can be specified
passing flags different than `REDISMODULE_HASH_NONE`:

`REDISMODULE_HASH_CFIELDS`: field names as null terminated C strings.

`REDISMODULE_HASH_EXISTS`: instead of setting the value of the field
expecting a `RedisModuleString` pointer to pointer, the function just
reports if the field exists or not and expects an integer pointer
as the second element of each pair.

Example of `REDISMODULE_HASH_CFIELDS`:

     RedisModuleString *username, *hashedpass;
     RedisModule_HashGet(mykey,REDISMODULE_HASH_CFIELDS,"username",&username,"hp",&hashedpass, NULL);

Example of `REDISMODULE_HASH_EXISTS`:

     int exists;
     RedisModule_HashGet(mykey,REDISMODULE_HASH_EXISTS,argv[1],&exists,NULL);

The function returns `REDISMODULE_OK` on success and `REDISMODULE_ERR` if
the key is not a hash value.

Memory management:

The returned `RedisModuleString` objects should be released with
[`RedisModule_FreeString()`](#RedisModule_FreeString), or by enabling automatic memory management.

<span id="section-key-api-for-stream-type"></span>

## Key API for Stream type

For an introduction to streams, see [https://redis.io/topics/streams-intro](https://redis.io/topics/streams-intro).

The type `RedisModuleStreamID`, which is used in stream functions, is a struct
with two 64-bit fields and is defined as

    typedef struct RedisModuleStreamID {
        uint64_t ms;
        uint64_t seq;
    } RedisModuleStreamID;

See also [`RedisModule_ValueLength()`](#RedisModule_ValueLength), which returns the length of a stream, and the
conversion functions [`RedisModule_StringToStreamID()`](#RedisModule_StringToStreamID) and [`RedisModule_CreateStringFromStreamID()`](#RedisModule_CreateStringFromStreamID).

<span id="RedisModule_StreamAdd"></span>

### `RedisModule_StreamAdd`

    int RedisModule_StreamAdd(RedisModuleKey *key,
                              int flags,
                              RedisModuleStreamID *id,
                              RedisModuleString **argv,
                              long numfields);

**Available since:** 6.2.0

Adds an entry to a stream. Like XADD without trimming.

- `key`: The key where the stream is (or will be) stored
- `flags`: A bit field of
  - `REDISMODULE_STREAM_ADD_AUTOID`: Assign a stream ID automatically, like
    `*` in the XADD command.
- `id`: If the `AUTOID` flag is set, this is where the assigned ID is
  returned. Can be NULL if `AUTOID` is set, if you don't care to receive the
  ID. If `AUTOID` is not set, this is the requested ID.
- `argv`: A pointer to an array of size `numfields * 2` containing the
  fields and values.
- `numfields`: The number of field-value pairs in `argv`.

Returns `REDISMODULE_OK` if an entry has been added. On failure,
`REDISMODULE_ERR` is returned and `errno` is set as follows:

- EINVAL if called with invalid arguments
- ENOTSUP if the key refers to a value of a type other than stream
- EBADF if the key was not opened for writing
- EDOM if the given ID was 0-0 or not greater than all other IDs in the
  stream (only if the AUTOID flag is unset)
- EFBIG if the stream has reached the last possible ID
- ERANGE if the elements are too large to be stored.

<span id="RedisModule_StreamDelete"></span>

### `RedisModule_StreamDelete`

    int RedisModule_StreamDelete(RedisModuleKey *key, RedisModuleStreamID *id);

**Available since:** 6.2.0

Deletes an entry from a stream.

- `key`: A key opened for writing, with no stream iterator started.
- `id`: The stream ID of the entry to delete.

Returns `REDISMODULE_OK` on success. On failure, `REDISMODULE_ERR` is returned
and `errno` is set as follows:

- EINVAL if called with invalid arguments
- ENOTSUP if the key refers to a value of a type other than stream or if the
  key is empty
- EBADF if the key was not opened for writing or if a stream iterator is
  associated with the key
- ENOENT if no entry with the given stream ID exists

See also [`RedisModule_StreamIteratorDelete()`](#RedisModule_StreamIteratorDelete) for deleting the current entry while
iterating using a stream iterator.

<span id="RedisModule_StreamIteratorStart"></span>

### `RedisModule_StreamIteratorStart`

    int RedisModule_StreamIteratorStart(RedisModuleKey *key,
                                        int flags,
                                        RedisModuleStreamID *start,
                                        RedisModuleStreamID *end);

**Available since:** 6.2.0

Sets up a stream iterator.

- `key`: The stream key opened for reading using [`RedisModule_OpenKey()`](#RedisModule_OpenKey).
- `flags`:
  - `REDISMODULE_STREAM_ITERATOR_EXCLUSIVE`: Don't include `start` and `end`
    in the iterated range.
  - `REDISMODULE_STREAM_ITERATOR_REVERSE`: Iterate in reverse order, starting
    from the `end` of the range.
- `start`: The lower bound of the range. Use NULL for the beginning of the
  stream.
- `end`: The upper bound of the range. Use NULL for the end of the stream.

Returns `REDISMODULE_OK` on success. On failure, `REDISMODULE_ERR` is returned
and `errno` is set as follows:

- EINVAL if called with invalid arguments
- ENOTSUP if the key refers to a value of a type other than stream or if the
  key is empty
- EBADF if the key was not opened for writing or if a stream iterator is
  already associated with the key
- EDOM if `start` or `end` is outside the valid range

Returns `REDISMODULE_OK` on success and `REDISMODULE_ERR` if the key doesn't
refer to a stream or if invalid arguments were given.

The stream IDs are retrieved using [`RedisModule_StreamIteratorNextID()`](#RedisModule_StreamIteratorNextID) and
for each stream ID, the fields and values are retrieved using
[`RedisModule_StreamIteratorNextField()`](#RedisModule_StreamIteratorNextField). The iterator is freed by calling
[`RedisModule_StreamIteratorStop()`](#RedisModule_StreamIteratorStop).

Example (error handling omitted):

    RedisModule_StreamIteratorStart(key, 0, startid_ptr, endid_ptr);
    RedisModuleStreamID id;
    long numfields;
    while (RedisModule_StreamIteratorNextID(key, &id, &numfields) ==
           REDISMODULE_OK) {
        RedisModuleString *field, *value;
        while (RedisModule_StreamIteratorNextField(key, &field, &value) ==
               REDISMODULE_OK) {
            //
            // ... Do stuff ...
            //
            RedisModule_FreeString(ctx, field);
            RedisModule_FreeString(ctx, value);
        }
    }
    RedisModule_StreamIteratorStop(key);

<span id="RedisModule_StreamIteratorStop"></span>

### `RedisModule_StreamIteratorStop`

    int RedisModule_StreamIteratorStop(RedisModuleKey *key);

**Available since:** 6.2.0

Stops a stream iterator created using [`RedisModule_StreamIteratorStart()`](#RedisModule_StreamIteratorStart) and
reclaims its memory.

Returns `REDISMODULE_OK` on success. On failure, `REDISMODULE_ERR` is returned
and `errno` is set as follows:

- EINVAL if called with a NULL key
- ENOTSUP if the key refers to a value of a type other than stream or if the
  key is empty
- EBADF if the key was not opened for writing or if no stream iterator is
  associated with the key

<span id="RedisModule_StreamIteratorNextID"></span>

### `RedisModule_StreamIteratorNextID`

    int RedisModule_StreamIteratorNextID(RedisModuleKey *key,
                                         RedisModuleStreamID *id,
                                         long *numfields);

**Available since:** 6.2.0

Finds the next stream entry and returns its stream ID and the number of
fields.

- `key`: Key for which a stream iterator has been started using
  [`RedisModule_StreamIteratorStart()`](#RedisModule_StreamIteratorStart).
- `id`: The stream ID returned. NULL if you don't care.
- `numfields`: The number of fields in the found stream entry. NULL if you
  don't care.

Returns `REDISMODULE_OK` and sets `*id` and `*numfields` if an entry was found.
On failure, `REDISMODULE_ERR` is returned and `errno` is set as follows:

- EINVAL if called with a NULL key
- ENOTSUP if the key refers to a value of a type other than stream or if the
  key is empty
- EBADF if no stream iterator is associated with the key
- ENOENT if there are no more entries in the range of the iterator

In practice, if [`RedisModule_StreamIteratorNextID()`](#RedisModule_StreamIteratorNextID) is called after a successful call
to [`RedisModule_StreamIteratorStart()`](#RedisModule_StreamIteratorStart) and with the same key, it is safe to assume that
an `REDISMODULE_ERR` return value means that there are no more entries.

Use [`RedisModule_StreamIteratorNextField()`](#RedisModule_StreamIteratorNextField) to retrieve the fields and values.
See the example at [`RedisModule_StreamIteratorStart()`](#RedisModule_StreamIteratorStart).

<span id="RedisModule_StreamIteratorNextField"></span>

### `RedisModule_StreamIteratorNextField`

    int RedisModule_StreamIteratorNextField(RedisModuleKey *key,
                                            RedisModuleString **field_ptr,
                                            RedisModuleString **value_ptr);

**Available since:** 6.2.0

Retrieves the next field of the current stream ID and its corresponding value
in a stream iteration. This function should be called repeatedly after calling
[`RedisModule_StreamIteratorNextID()`](#RedisModule_StreamIteratorNextID) to fetch each field-value pair.

- `key`: Key where a stream iterator has been started.
- `field_ptr`: This is where the field is returned.
- `value_ptr`: This is where the value is returned.

Returns `REDISMODULE_OK` and points `*field_ptr` and `*value_ptr` to freshly
allocated `RedisModuleString` objects. The string objects are freed
automatically when the callback finishes if automatic memory is enabled. On
failure, `REDISMODULE_ERR` is returned and `errno` is set as follows:

- EINVAL if called with a NULL key
- ENOTSUP if the key refers to a value of a type other than stream or if the
  key is empty
- EBADF if no stream iterator is associated with the key
- ENOENT if there are no more fields in the current stream entry

In practice, if [`RedisModule_StreamIteratorNextField()`](#RedisModule_StreamIteratorNextField) is called after a successful
call to [`RedisModule_StreamIteratorNextID()`](#RedisModule_StreamIteratorNextID) and with the same key, it is safe to assume
that an `REDISMODULE_ERR` return value means that there are no more fields.

See the example at [`RedisModule_StreamIteratorStart()`](#RedisModule_StreamIteratorStart).

<span id="RedisModule_StreamIteratorDelete"></span>

### `RedisModule_StreamIteratorDelete`

    int RedisModule_StreamIteratorDelete(RedisModuleKey *key);

**Available since:** 6.2.0

Deletes the current stream entry while iterating.

This function can be called after [`RedisModule_StreamIteratorNextID()`](#RedisModule_StreamIteratorNextID) or after any
calls to [`RedisModule_StreamIteratorNextField()`](#RedisModule_StreamIteratorNextField).

Returns `REDISMODULE_OK` on success. On failure, `REDISMODULE_ERR` is returned
and `errno` is set as follows:

- EINVAL if key is NULL
- ENOTSUP if the key is empty or is of another type than stream
- EBADF if the key is not opened for writing, if no iterator has been started
- ENOENT if the iterator has no current stream entry

<span id="RedisModule_StreamTrimByLength"></span>

### `RedisModule_StreamTrimByLength`

    long long RedisModule_StreamTrimByLength(RedisModuleKey *key,
                                             int flags,
                                             long long length);

**Available since:** 6.2.0

Trim a stream by length, similar to XTRIM with MAXLEN.

- `key`: Key opened for writing.
- `flags`: A bitfield of
  - `REDISMODULE_STREAM_TRIM_APPROX`: Trim less if it improves performance,
    like XTRIM with `~`.
- `length`: The number of stream entries to keep after trimming.

Returns the number of entries deleted. On failure, a negative value is
returned and `errno` is set as follows:

- EINVAL if called with invalid arguments
- ENOTSUP if the key is empty or of a type other than stream
- EBADF if the key is not opened for writing

<span id="RedisModule_StreamTrimByID"></span>

### `RedisModule_StreamTrimByID`

    long long RedisModule_StreamTrimByID(RedisModuleKey *key,
                                         int flags,
                                         RedisModuleStreamID *id);

**Available since:** 6.2.0

Trim a stream by ID, similar to XTRIM with MINID.

- `key`: Key opened for writing.
- `flags`: A bitfield of
  - `REDISMODULE_STREAM_TRIM_APPROX`: Trim less if it improves performance,
    like XTRIM with `~`.
- `id`: The smallest stream ID to keep after trimming.

Returns the number of entries deleted. On failure, a negative value is
returned and `errno` is set as follows:

- EINVAL if called with invalid arguments
- ENOTSUP if the key is empty or of a type other than stream
- EBADF if the key is not opened for writing

<span id="section-calling-redis-commands-from-modules"></span>

## Calling Redis commands from modules

[`RedisModule_Call()`](#RedisModule_Call) sends a command to Redis. The remaining functions handle the reply.

<span id="RedisModule_FreeCallReply"></span>

### `RedisModule_FreeCallReply`

    void RedisModule_FreeCallReply(RedisModuleCallReply *reply);

**Available since:** 4.0.0

Free a Call reply and all the nested replies it contains if it's an
array.

<span id="RedisModule_CallReplyType"></span>

### `RedisModule_CallReplyType`

    int RedisModule_CallReplyType(RedisModuleCallReply *reply);

**Available since:** 4.0.0

Return the reply type as one of the following:

- `REDISMODULE_REPLY_UNKNOWN`
- `REDISMODULE_REPLY_STRING`
- `REDISMODULE_REPLY_ERROR`
- `REDISMODULE_REPLY_INTEGER`
- `REDISMODULE_REPLY_ARRAY`
- `REDISMODULE_REPLY_NULL`
- `REDISMODULE_REPLY_MAP`
- `REDISMODULE_REPLY_SET`
- `REDISMODULE_REPLY_BOOL`
- `REDISMODULE_REPLY_DOUBLE`
- `REDISMODULE_REPLY_BIG_NUMBER`
- `REDISMODULE_REPLY_VERBATIM_STRING`
- `REDISMODULE_REPLY_ATTRIBUTE`

<span id="RedisModule_CallReplyLength"></span>

### `RedisModule_CallReplyLength`

    size_t RedisModule_CallReplyLength(RedisModuleCallReply *reply);

**Available since:** 4.0.0

Return the reply type length, where applicable.

<span id="RedisModule_CallReplyArrayElement"></span>

### `RedisModule_CallReplyArrayElement`

    RedisModuleCallReply *RedisModule_CallReplyArrayElement(RedisModuleCallReply *reply,
                                                            size_t idx);

**Available since:** 4.0.0

Return the 'idx'-th nested call reply element of an array reply, or NULL
if the reply type is wrong or the index is out of range.

<span id="RedisModule_CallReplyInteger"></span>

### `RedisModule_CallReplyInteger`

    long long RedisModule_CallReplyInteger(RedisModuleCallReply *reply);

**Available since:** 4.0.0

Return the `long long` of an integer reply.

<span id="RedisModule_CallReplyDouble"></span>

### `RedisModule_CallReplyDouble`

    double RedisModule_CallReplyDouble(RedisModuleCallReply *reply);

**Available since:** 7.0.0

Return the double value of a double reply.

<span id="RedisModule_CallReplyBigNumber"></span>

### `RedisModule_CallReplyBigNumber`

    const char *RedisModule_CallReplyBigNumber(RedisModuleCallReply *reply,
                                               size_t *len);

**Available since:** 7.0.0

Return the big number value of a big number reply.

<span id="RedisModule_CallReplyVerbatim"></span>

### `RedisModule_CallReplyVerbatim`

    const char *RedisModule_CallReplyVerbatim(RedisModuleCallReply *reply,
                                              size_t *len,
                                              const char **format);

**Available since:** 7.0.0

Return the value of a verbatim string reply,
An optional output argument can be given to get verbatim reply format.

<span id="RedisModule_CallReplyBool"></span>

### `RedisModule_CallReplyBool`

    int RedisModule_CallReplyBool(RedisModuleCallReply *reply);

**Available since:** 7.0.0

Return the Boolean value of a Boolean reply.

<span id="RedisModule_CallReplySetElement"></span>

### `RedisModule_CallReplySetElement`

    RedisModuleCallReply *RedisModule_CallReplySetElement(RedisModuleCallReply *reply,
                                                          size_t idx);

**Available since:** 7.0.0

Return the 'idx'-th nested call reply element of a set reply, or NULL
if the reply type is wrong or the index is out of range.

<span id="RedisModule_CallReplyMapElement"></span>

### `RedisModule_CallReplyMapElement`

    int RedisModule_CallReplyMapElement(RedisModuleCallReply *reply,
                                        size_t idx,
                                        RedisModuleCallReply **key,
                                        RedisModuleCallReply **val);

**Available since:** 7.0.0

Retrieve the 'idx'-th key and value of a map reply.

Returns:
- `REDISMODULE_OK` on success.
- `REDISMODULE_ERR` if idx out of range or if the reply type is wrong.

The `key` and `value` arguments are used to return by reference, and may be
NULL if not required.

<span id="RedisModule_CallReplyAttribute"></span>

### `RedisModule_CallReplyAttribute`

    RedisModuleCallReply *RedisModule_CallReplyAttribute(RedisModuleCallReply *reply);

**Available since:** 7.0.0

Return the attribute of the given reply, or NULL if no attribute exists.

<span id="RedisModule_CallReplyAttributeElement"></span>

### `RedisModule_CallReplyAttributeElement`

    int RedisModule_CallReplyAttributeElement(RedisModuleCallReply *reply,
                                              size_t idx,
                                              RedisModuleCallReply **key,
                                              RedisModuleCallReply **val);

**Available since:** 7.0.0

Retrieve the 'idx'-th key and value of an attribute reply.

Returns:
- `REDISMODULE_OK` on success.
- `REDISMODULE_ERR` if idx out of range or if the reply type is wrong.

The `key` and `value` arguments are used to return by reference, and may be
NULL if not required.

<span id="RedisModule_CallReplyStringPtr"></span>

### `RedisModule_CallReplyStringPtr`

    const char *RedisModule_CallReplyStringPtr(RedisModuleCallReply *reply,
                                               size_t *len);

**Available since:** 4.0.0

Return the pointer and length of a string or error reply.

<span id="RedisModule_CreateStringFromCallReply"></span>

### `RedisModule_CreateStringFromCallReply`

    RedisModuleString *RedisModule_CreateStringFromCallReply(RedisModuleCallReply *reply);

**Available since:** 4.0.0

Return a new string object from a call reply of type string, error or
integer. Otherwise (wrong reply type) return NULL.

<span id="RedisModule_Call"></span>

### `RedisModule_Call`

    RedisModuleCallReply *RedisModule_Call(RedisModuleCtx *ctx,
                                           const char *cmdname,
                                           const char *fmt,
                                           ...);

**Available since:** 4.0.0

Exported API to call any Redis command from modules.

* **cmdname**: The Redis command to call.
* **fmt**: A format specifier string for the command's arguments. Each
  of the arguments should be specified by a valid type specification. The
  format specifier can also contain the modifiers `!`, `A`, `3` and `R` which
  don't have a corresponding argument.

    * `b` -- The argument is a buffer and is immediately followed by another
             argument that is the buffer's length.
    * `c` -- The argument is a pointer to a plain C string (null-terminated).
    * `l` -- The argument is `long long` integer.
    * `s` -- The argument is a RedisModuleString.
    * `v` -- The argument(s) is a vector of RedisModuleString.
    * `!` -- Sends the Redis command and its arguments to replicas and AOF.
    * `A` -- Suppress AOF propagation, send only to replicas (requires `!`).
    * `R` -- Suppress replicas propagation, send only to AOF (requires `!`).
    * `3` -- Return a RESP3 reply. This will change the command reply.
             e.g., HGETALL returns a map instead of a flat array.
    * `0` -- Return the reply in auto mode, i.e. the reply format will be the
             same as the client attached to the given RedisModuleCtx. This will
             probably used when you want to pass the reply directly to the client.
    * `C` -- Check if command can be executed according to ACL rules.
    * 'S' -- Run the command in a script mode, this means that it will raise
             an error if a command which are not allowed inside a script
             (flagged with the `deny-script` flag) is invoked (like SHUTDOWN).
             In addition, on script mode, write commands are not allowed if there are
             not enough good replicas (as configured with `min-replicas-to-write`)
             or when the server is unable to persist to the disk.
    * 'W' -- Do not allow to run any write command (flagged with the `write` flag).
    * 'E' -- Return error as RedisModuleCallReply. If there is an error before
             invoking the command, the error is returned using errno mechanism.
             This flag allows to get the error also as an error CallReply with
             relevant error message.
* **...**: The actual arguments to the Redis command.

On success a `RedisModuleCallReply` object is returned, otherwise
NULL is returned and errno is set to the following values:

* EBADF: wrong format specifier.
* EINVAL: wrong command arity.
* ENOENT: command does not exist.
* EPERM: operation in Cluster instance with key in non local slot.
* EROFS: operation in Cluster instance when a write command is sent
         in a readonly state.
* ENETDOWN: operation in Cluster instance when cluster is down.
* ENOTSUP: No ACL user for the specified module context
* EACCES: Command cannot be executed, according to ACL rules
* ENOSPC: Write command is not allowed
* ESPIPE: Command not allowed on script mode

Example code fragment:

     reply = RedisModule_Call(ctx,"INCRBY","sc",argv[1],"10");
     if (RedisModule_CallReplyType(reply) == REDISMODULE_REPLY_INTEGER) {
       long long myval = RedisModule_CallReplyInteger(reply);
       // Do something with myval.
     }

This API is documented here: [https://redis.io/topics/modules-intro](https://redis.io/topics/modules-intro)

<span id="RedisModule_CallReplyProto"></span>

### `RedisModule_CallReplyProto`

    const char *RedisModule_CallReplyProto(RedisModuleCallReply *reply,
                                           size_t *len);

**Available since:** 4.0.0

Return a pointer, and a length, to the protocol returned by the command
that returned the reply object.

<span id="section-modules-data-types"></span>

## Modules data types

When String DMA or using existing data structures is not enough, it is
possible to create new data types from scratch and export them to
Redis. The module must provide a set of callbacks for handling the
new values exported (for example in order to provide RDB saving/loading,
AOF rewrite, and so forth). In this section we define this API.

<span id="RedisModule_CreateDataType"></span>

### `RedisModule_CreateDataType`

    moduleType *RedisModule_CreateDataType(RedisModuleCtx *ctx,
                                           const char *name,
                                           int encver,
                                           void *typemethods_ptr);

**Available since:** 4.0.0

Register a new data type exported by the module. The parameters are the
following. Please for in depth documentation check the modules API
documentation, especially [https://redis.io/topics/modules-native-types](https://redis.io/topics/modules-native-types).

* **name**: A 9 characters data type name that MUST be unique in the Redis
  Modules ecosystem. Be creative... and there will be no collisions. Use
  the charset A-Z a-z 9-0, plus the two "-_" characters. A good
  idea is to use, for example `<typename>-<vendor>`. For example
  "tree-AntZ" may mean "Tree data structure by @antirez". To use both
  lower case and upper case letters helps in order to prevent collisions.
* **encver**: Encoding version, which is, the version of the serialization
  that a module used in order to persist data. As long as the "name"
  matches, the RDB loading will be dispatched to the type callbacks
  whatever 'encver' is used, however the module can understand if
  the encoding it must load are of an older version of the module.
  For example the module "tree-AntZ" initially used encver=0. Later
  after an upgrade, it started to serialize data in a different format
  and to register the type with encver=1. However this module may
  still load old data produced by an older version if the `rdb_load`
  callback is able to check the encver value and act accordingly.
  The encver must be a positive value between 0 and 1023.

* **typemethods_ptr** is a pointer to a `RedisModuleTypeMethods` structure
  that should be populated with the methods callbacks and structure
  version, like in the following example:

        RedisModuleTypeMethods tm = {
            .version = REDISMODULE_TYPE_METHOD_VERSION,
            .rdb_load = myType_RDBLoadCallBack,
            .rdb_save = myType_RDBSaveCallBack,
            .aof_rewrite = myType_AOFRewriteCallBack,
            .free = myType_FreeCallBack,

            // Optional fields
            .digest = myType_DigestCallBack,
            .mem_usage = myType_MemUsageCallBack,
            .aux_load = myType_AuxRDBLoadCallBack,
            .aux_save = myType_AuxRDBSaveCallBack,
            .free_effort = myType_FreeEffortCallBack,
            .unlink = myType_UnlinkCallBack,
            .copy = myType_CopyCallback,
            .defrag = myType_DefragCallback

            // Enhanced optional fields
            .mem_usage2 = myType_MemUsageCallBack2,
            .free_effort2 = myType_FreeEffortCallBack2,
            .unlink2 = myType_UnlinkCallBack2,
            .copy2 = myType_CopyCallback2,
        }

* **rdb_load**: A callback function pointer that loads data from RDB files.
* **rdb_save**: A callback function pointer that saves data to RDB files.
* **aof_rewrite**: A callback function pointer that rewrites data as commands.
* **digest**: A callback function pointer that is used for `DEBUG DIGEST`.
* **free**: A callback function pointer that can free a type value.
* **aux_save**: A callback function pointer that saves out of keyspace data to RDB files.
  'when' argument is either `REDISMODULE_AUX_BEFORE_RDB` or `REDISMODULE_AUX_AFTER_RDB`.
* **aux_load**: A callback function pointer that loads out of keyspace data from RDB files.
  Similar to `aux_save`, returns `REDISMODULE_OK` on success, and ERR otherwise.
* **free_effort**: A callback function pointer that used to determine whether the module's
  memory needs to be lazy reclaimed. The module should return the complexity involved by
  freeing the value. for example: how many pointers are gonna be freed. Note that if it 
  returns 0, we'll always do an async free.
* **unlink**: A callback function pointer that used to notifies the module that the key has 
  been removed from the DB by redis, and may soon be freed by a background thread. Note that 
  it won't be called on FLUSHALL/FLUSHDB (both sync and async), and the module can use the 
  `RedisModuleEvent_FlushDB` to hook into that.
* **copy**: A callback function pointer that is used to make a copy of the specified key.
  The module is expected to perform a deep copy of the specified value and return it.
  In addition, hints about the names of the source and destination keys is provided.
  A NULL return value is considered an error and the copy operation fails.
  Note: if the target key exists and is being overwritten, the copy callback will be
  called first, followed by a free callback to the value that is being replaced.

* **defrag**: A callback function pointer that is used to request the module to defrag
  a key. The module should then iterate pointers and call the relevant `RedisModule_Defrag*()`
  functions to defragment pointers or complex types. The module should continue
  iterating as long as [`RedisModule_DefragShouldStop()`](#RedisModule_DefragShouldStop) returns a zero value, and return a
  zero value if finished or non-zero value if more work is left to be done. If more work
  needs to be done, [`RedisModule_DefragCursorSet()`](#RedisModule_DefragCursorSet) and [`RedisModule_DefragCursorGet()`](#RedisModule_DefragCursorGet) can be used to track
  this work across different calls.
  Normally, the defrag mechanism invokes the callback without a time limit, so
  [`RedisModule_DefragShouldStop()`](#RedisModule_DefragShouldStop) always returns zero. The "late defrag" mechanism which has
  a time limit and provides cursor support is used only for keys that are determined
  to have significant internal complexity. To determine this, the defrag mechanism
  uses the `free_effort` callback and the 'active-defrag-max-scan-fields' config directive.
  NOTE: The value is passed as a `void**` and the function is expected to update the
  pointer if the top-level value pointer is defragmented and consequently changes.

* **mem_usage2**: Similar to `mem_usage`, but provides the `RedisModuleKeyOptCtx` parameter
  so that meta information such as key name and db id can be obtained, and
  the `sample_size` for size estimation (see MEMORY USAGE command).
* **free_effort2**: Similar to `free_effort`, but provides the `RedisModuleKeyOptCtx` parameter
  so that meta information such as key name and db id can be obtained.
* **unlink2**: Similar to `unlink`, but provides the `RedisModuleKeyOptCtx` parameter
  so that meta information such as key name and db id can be obtained.
* **copy2**: Similar to `copy`, but provides the `RedisModuleKeyOptCtx` parameter
  so that meta information such as key names and db ids can be obtained.

Note: the module name "AAAAAAAAA" is reserved and produces an error, it
happens to be pretty lame as well.

If there is already a module registering a type with the same name,
and if the module name or encver is invalid, NULL is returned.
Otherwise the new type is registered into Redis, and a reference of
type `RedisModuleType` is returned: the caller of the function should store
this reference into a global variable to make future use of it in the
modules type API, since a single module may register multiple types.
Example code fragment:

     static RedisModuleType *BalancedTreeType;

     int RedisModule_OnLoad(RedisModuleCtx *ctx) {
         // some code here ...
         BalancedTreeType = RM_CreateDataType(...);
     }

<span id="RedisModule_ModuleTypeSetValue"></span>

### `RedisModule_ModuleTypeSetValue`

    int RedisModule_ModuleTypeSetValue(RedisModuleKey *key,
                                       moduleType *mt,
                                       void *value);

**Available since:** 4.0.0

If the key is open for writing, set the specified module type object
as the value of the key, deleting the old value if any.
On success `REDISMODULE_OK` is returned. If the key is not open for
writing or there is an active iterator, `REDISMODULE_ERR` is returned.

<span id="RedisModule_ModuleTypeGetType"></span>

### `RedisModule_ModuleTypeGetType`

    moduleType *RedisModule_ModuleTypeGetType(RedisModuleKey *key);

**Available since:** 4.0.0

Assuming [`RedisModule_KeyType()`](#RedisModule_KeyType) returned `REDISMODULE_KEYTYPE_MODULE` on
the key, returns the module type pointer of the value stored at key.

If the key is NULL, is not associated with a module type, or is empty,
then NULL is returned instead.

<span id="RedisModule_ModuleTypeGetValue"></span>

### `RedisModule_ModuleTypeGetValue`

    void *RedisModule_ModuleTypeGetValue(RedisModuleKey *key);

**Available since:** 4.0.0

Assuming [`RedisModule_KeyType()`](#RedisModule_KeyType) returned `REDISMODULE_KEYTYPE_MODULE` on
the key, returns the module type low-level value stored at key, as
it was set by the user via [`RedisModule_ModuleTypeSetValue()`](#RedisModule_ModuleTypeSetValue).

If the key is NULL, is not associated with a module type, or is empty,
then NULL is returned instead.

<span id="section-rdb-loading-and-saving-functions"></span>

## RDB loading and saving functions

<span id="RedisModule_IsIOError"></span>

### `RedisModule_IsIOError`

    int RedisModule_IsIOError(RedisModuleIO *io);

**Available since:** 6.0.0

Returns true if any previous IO API failed.
for `Load*` APIs the `REDISMODULE_OPTIONS_HANDLE_IO_ERRORS` flag must be set with
[`RedisModule_SetModuleOptions`](#RedisModule_SetModuleOptions) first.

<span id="RedisModule_SaveUnsigned"></span>

### `RedisModule_SaveUnsigned`

    void RedisModule_SaveUnsigned(RedisModuleIO *io, uint64_t value);

**Available since:** 4.0.0

Save an unsigned 64 bit value into the RDB file. This function should only
be called in the context of the `rdb_save` method of modules implementing new
data types.

<span id="RedisModule_LoadUnsigned"></span>

### `RedisModule_LoadUnsigned`

    uint64_t RedisModule_LoadUnsigned(RedisModuleIO *io);

**Available since:** 4.0.0

Load an unsigned 64 bit value from the RDB file. This function should only
be called in the context of the `rdb_load` method of modules implementing
new data types.

<span id="RedisModule_SaveSigned"></span>

### `RedisModule_SaveSigned`

    void RedisModule_SaveSigned(RedisModuleIO *io, int64_t value);

**Available since:** 4.0.0

Like [`RedisModule_SaveUnsigned()`](#RedisModule_SaveUnsigned) but for signed 64 bit values.

<span id="RedisModule_LoadSigned"></span>

### `RedisModule_LoadSigned`

    int64_t RedisModule_LoadSigned(RedisModuleIO *io);

**Available since:** 4.0.0

Like [`RedisModule_LoadUnsigned()`](#RedisModule_LoadUnsigned) but for signed 64 bit values.

<span id="RedisModule_SaveString"></span>

### `RedisModule_SaveString`

    void RedisModule_SaveString(RedisModuleIO *io, RedisModuleString *s);

**Available since:** 4.0.0

In the context of the `rdb_save` method of a module type, saves a
string into the RDB file taking as input a `RedisModuleString`.

The string can be later loaded with [`RedisModule_LoadString()`](#RedisModule_LoadString) or
other Load family functions expecting a serialized string inside
the RDB file.

<span id="RedisModule_SaveStringBuffer"></span>

### `RedisModule_SaveStringBuffer`

    void RedisModule_SaveStringBuffer(RedisModuleIO *io,
                                      const char *str,
                                      size_t len);

**Available since:** 4.0.0

Like [`RedisModule_SaveString()`](#RedisModule_SaveString) but takes a raw C pointer and length
as input.

<span id="RedisModule_LoadString"></span>

### `RedisModule_LoadString`

    RedisModuleString *RedisModule_LoadString(RedisModuleIO *io);

**Available since:** 4.0.0

In the context of the `rdb_load` method of a module data type, loads a string
from the RDB file, that was previously saved with [`RedisModule_SaveString()`](#RedisModule_SaveString)
functions family.

The returned string is a newly allocated `RedisModuleString` object, and
the user should at some point free it with a call to [`RedisModule_FreeString()`](#RedisModule_FreeString).

If the data structure does not store strings as `RedisModuleString` objects,
the similar function [`RedisModule_LoadStringBuffer()`](#RedisModule_LoadStringBuffer) could be used instead.

<span id="RedisModule_LoadStringBuffer"></span>

### `RedisModule_LoadStringBuffer`

    char *RedisModule_LoadStringBuffer(RedisModuleIO *io, size_t *lenptr);

**Available since:** 4.0.0

Like [`RedisModule_LoadString()`](#RedisModule_LoadString) but returns a heap allocated string that
was allocated with [`RedisModule_Alloc()`](#RedisModule_Alloc), and can be resized or freed with
[`RedisModule_Realloc()`](#RedisModule_Realloc) or [`RedisModule_Free()`](#RedisModule_Free).

The size of the string is stored at '*lenptr' if not NULL.
The returned string is not automatically NULL terminated, it is loaded
exactly as it was stored inside the RDB file.

<span id="RedisModule_SaveDouble"></span>

### `RedisModule_SaveDouble`

    void RedisModule_SaveDouble(RedisModuleIO *io, double value);

**Available since:** 4.0.0

In the context of the `rdb_save` method of a module data type, saves a double
value to the RDB file. The double can be a valid number, a NaN or infinity.
It is possible to load back the value with [`RedisModule_LoadDouble()`](#RedisModule_LoadDouble).

<span id="RedisModule_LoadDouble"></span>

### `RedisModule_LoadDouble`

    double RedisModule_LoadDouble(RedisModuleIO *io);

**Available since:** 4.0.0

In the context of the `rdb_save` method of a module data type, loads back the
double value saved by [`RedisModule_SaveDouble()`](#RedisModule_SaveDouble).

<span id="RedisModule_SaveFloat"></span>

### `RedisModule_SaveFloat`

    void RedisModule_SaveFloat(RedisModuleIO *io, float value);

**Available since:** 4.0.0

In the context of the `rdb_save` method of a module data type, saves a float
value to the RDB file. The float can be a valid number, a NaN or infinity.
It is possible to load back the value with [`RedisModule_LoadFloat()`](#RedisModule_LoadFloat).

<span id="RedisModule_LoadFloat"></span>

### `RedisModule_LoadFloat`

    float RedisModule_LoadFloat(RedisModuleIO *io);

**Available since:** 4.0.0

In the context of the `rdb_save` method of a module data type, loads back the
float value saved by [`RedisModule_SaveFloat()`](#RedisModule_SaveFloat).

<span id="RedisModule_SaveLongDouble"></span>

### `RedisModule_SaveLongDouble`

    void RedisModule_SaveLongDouble(RedisModuleIO *io, long double value);

**Available since:** 6.0.0

In the context of the `rdb_save` method of a module data type, saves a long double
value to the RDB file. The double can be a valid number, a NaN or infinity.
It is possible to load back the value with [`RedisModule_LoadLongDouble()`](#RedisModule_LoadLongDouble).

<span id="RedisModule_LoadLongDouble"></span>

### `RedisModule_LoadLongDouble`

    long double RedisModule_LoadLongDouble(RedisModuleIO *io);

**Available since:** 6.0.0

In the context of the `rdb_save` method of a module data type, loads back the
long double value saved by [`RedisModule_SaveLongDouble()`](#RedisModule_SaveLongDouble).

<span id="section-key-digest-api-debug-digest-interface-for-modules-types"></span>

## Key digest API (DEBUG DIGEST interface for modules types)

<span id="RedisModule_DigestAddStringBuffer"></span>

### `RedisModule_DigestAddStringBuffer`

    void RedisModule_DigestAddStringBuffer(RedisModuleDigest *md,
                                           const char *ele,
                                           size_t len);

**Available since:** 4.0.0

Add a new element to the digest. This function can be called multiple times
one element after the other, for all the elements that constitute a given
data structure. The function call must be followed by the call to
[`RedisModule_DigestEndSequence`](#RedisModule_DigestEndSequence) eventually, when all the elements that are
always in a given order are added. See the Redis Modules data types
documentation for more info. However this is a quick example that uses Redis
data types as an example.

To add a sequence of unordered elements (for example in the case of a Redis
Set), the pattern to use is:

    foreach element {
        AddElement(element);
        EndSequence();
    }

Because Sets are not ordered, so every element added has a position that
does not depend from the other. However if instead our elements are
ordered in pairs, like field-value pairs of an Hash, then one should
use:

    foreach key,value {
        AddElement(key);
        AddElement(value);
        EndSequence();
    }

Because the key and value will be always in the above order, while instead
the single key-value pairs, can appear in any position into a Redis hash.

A list of ordered elements would be implemented with:

    foreach element {
        AddElement(element);
    }
    EndSequence();

<span id="RedisModule_DigestAddLongLong"></span>

### `RedisModule_DigestAddLongLong`

    void RedisModule_DigestAddLongLong(RedisModuleDigest *md, long long ll);

**Available since:** 4.0.0

Like [`RedisModule_DigestAddStringBuffer()`](#RedisModule_DigestAddStringBuffer) but takes a `long long` as input
that gets converted into a string before adding it to the digest.

<span id="RedisModule_DigestEndSequence"></span>

### `RedisModule_DigestEndSequence`

    void RedisModule_DigestEndSequence(RedisModuleDigest *md);

**Available since:** 4.0.0

See the documentation for `RedisModule_DigestAddElement()`.

<span id="RedisModule_LoadDataTypeFromStringEncver"></span>

### `RedisModule_LoadDataTypeFromStringEncver`

    void *RedisModule_LoadDataTypeFromStringEncver(const RedisModuleString *str,
                                                   const moduleType *mt,
                                                   int encver);

**Available since:** 7.0.0

Decode a serialized representation of a module data type 'mt', in a specific encoding version 'encver'
from string 'str' and return a newly allocated value, or NULL if decoding failed.

This call basically reuses the '`rdb_load`' callback which module data types
implement in order to allow a module to arbitrarily serialize/de-serialize
keys, similar to how the Redis 'DUMP' and 'RESTORE' commands are implemented.

Modules should generally use the `REDISMODULE_OPTIONS_HANDLE_IO_ERRORS` flag and
make sure the de-serialization code properly checks and handles IO errors
(freeing allocated buffers and returning a NULL).

If this is NOT done, Redis will handle corrupted (or just truncated) serialized
data by producing an error message and terminating the process.

<span id="RedisModule_LoadDataTypeFromString"></span>

### `RedisModule_LoadDataTypeFromString`

    void *RedisModule_LoadDataTypeFromString(const RedisModuleString *str,
                                             const moduleType *mt);

**Available since:** 6.0.0

Similar to [`RedisModule_LoadDataTypeFromStringEncver`](#RedisModule_LoadDataTypeFromStringEncver), original version of the API, kept
for backward compatibility.

<span id="RedisModule_SaveDataTypeToString"></span>

### `RedisModule_SaveDataTypeToString`

    RedisModuleString *RedisModule_SaveDataTypeToString(RedisModuleCtx *ctx,
                                                        void *data,
                                                        const moduleType *mt);

**Available since:** 6.0.0

Encode a module data type 'mt' value 'data' into serialized form, and return it
as a newly allocated `RedisModuleString`.

This call basically reuses the '`rdb_save`' callback which module data types
implement in order to allow a module to arbitrarily serialize/de-serialize
keys, similar to how the Redis 'DUMP' and 'RESTORE' commands are implemented.

<span id="RedisModule_GetKeyNameFromDigest"></span>

### `RedisModule_GetKeyNameFromDigest`

    const RedisModuleString *RedisModule_GetKeyNameFromDigest(RedisModuleDigest *dig);

**Available since:** 7.0.0

Returns the name of the key currently being processed.

<span id="RedisModule_GetDbIdFromDigest"></span>

### `RedisModule_GetDbIdFromDigest`

    int RedisModule_GetDbIdFromDigest(RedisModuleDigest *dig);

**Available since:** 7.0.0

Returns the database id of the key currently being processed.

<span id="section-aof-api-for-modules-data-types"></span>

## AOF API for modules data types

<span id="RedisModule_EmitAOF"></span>

### `RedisModule_EmitAOF`

    void RedisModule_EmitAOF(RedisModuleIO *io,
                             const char *cmdname,
                             const char *fmt,
                             ...);

**Available since:** 4.0.0

Emits a command into the AOF during the AOF rewriting process. This function
is only called in the context of the `aof_rewrite` method of data types exported
by a module. The command works exactly like [`RedisModule_Call()`](#RedisModule_Call) in the way
the parameters are passed, but it does not return anything as the error
handling is performed by Redis itself.

<span id="section-io-context-handling"></span>

## IO context handling

<span id="RedisModule_GetKeyNameFromIO"></span>

### `RedisModule_GetKeyNameFromIO`

    const RedisModuleString *RedisModule_GetKeyNameFromIO(RedisModuleIO *io);

**Available since:** 5.0.5

Returns the name of the key currently being processed.
There is no guarantee that the key name is always available, so this may return NULL.

<span id="RedisModule_GetKeyNameFromModuleKey"></span>

### `RedisModule_GetKeyNameFromModuleKey`

    const RedisModuleString *RedisModule_GetKeyNameFromModuleKey(RedisModuleKey *key);

**Available since:** 6.0.0

Returns a `RedisModuleString` with the name of the key from `RedisModuleKey`.

<span id="RedisModule_GetDbIdFromModuleKey"></span>

### `RedisModule_GetDbIdFromModuleKey`

    int RedisModule_GetDbIdFromModuleKey(RedisModuleKey *key);

**Available since:** 7.0.0

Returns a database id of the key from `RedisModuleKey`.

<span id="RedisModule_GetDbIdFromIO"></span>

### `RedisModule_GetDbIdFromIO`

    int RedisModule_GetDbIdFromIO(RedisModuleIO *io);

**Available since:** 7.0.0

Returns the database id of the key currently being processed.
There is no guarantee that this info is always available, so this may return -1.

<span id="section-logging"></span>

## Logging

<span id="RedisModule_Log"></span>

### `RedisModule_Log`

    void RedisModule_Log(RedisModuleCtx *ctx,
                         const char *levelstr,
                         const char *fmt,
                         ...);

**Available since:** 4.0.0

Produces a log message to the standard Redis log, the format accepts
printf-alike specifiers, while level is a string describing the log
level to use when emitting the log, and must be one of the following:

* "debug" (`REDISMODULE_LOGLEVEL_DEBUG`)
* "verbose" (`REDISMODULE_LOGLEVEL_VERBOSE`)
* "notice" (`REDISMODULE_LOGLEVEL_NOTICE`)
* "warning" (`REDISMODULE_LOGLEVEL_WARNING`)

If the specified log level is invalid, verbose is used by default.
There is a fixed limit to the length of the log line this function is able
to emit, this limit is not specified but is guaranteed to be more than
a few lines of text.

The ctx argument may be NULL if cannot be provided in the context of the
caller for instance threads or callbacks, in which case a generic "module"
will be used instead of the module name.

<span id="RedisModule_LogIOError"></span>

### `RedisModule_LogIOError`

    void RedisModule_LogIOError(RedisModuleIO *io,
                                const char *levelstr,
                                const char *fmt,
                                ...);

**Available since:** 4.0.0

Log errors from RDB / AOF serialization callbacks.

This function should be used when a callback is returning a critical
error to the caller since cannot load or save the data for some
critical reason.

<span id="RedisModule__Assert"></span>

### `RedisModule__Assert`

    void RedisModule__Assert(const char *estr, const char *file, int line);

**Available since:** 6.0.0

Redis-like assert function.

The macro `RedisModule_Assert(expression)` is recommended, rather than
calling this function directly.

A failed assertion will shut down the server and produce logging information
that looks identical to information generated by Redis itself.

<span id="RedisModule_LatencyAddSample"></span>

### `RedisModule_LatencyAddSample`

    void RedisModule_LatencyAddSample(const char *event, mstime_t latency);

**Available since:** 6.0.0

Allows adding event to the latency monitor to be observed by the LATENCY
command. The call is skipped if the latency is smaller than the configured
latency-monitor-threshold.

<span id="section-blocking-clients-from-modules"></span>

## Blocking clients from modules

For a guide about blocking commands in modules, see
[https://redis.io/topics/modules-blocking-ops](https://redis.io/topics/modules-blocking-ops).

<span id="RedisModule_BlockClient"></span>

### `RedisModule_BlockClient`

    RedisModuleBlockedClient *RedisModule_BlockClient(RedisModuleCtx *ctx,
                                                      RedisModuleCmdFunc reply_callback,
                                                      RedisModuleCmdFunc timeout_callback,
                                                      void (*free_privdata)(RedisModuleCtx*, void*),
                                                      long long timeout_ms);

**Available since:** 4.0.0

Block a client in the context of a blocking command, returning a handle
which will be used, later, in order to unblock the client with a call to
[`RedisModule_UnblockClient()`](#RedisModule_UnblockClient). The arguments specify callback functions
and a timeout after which the client is unblocked.

The callbacks are called in the following contexts:

    reply_callback:   called after a successful RedisModule_UnblockClient()
                      call in order to reply to the client and unblock it.

    timeout_callback: called when the timeout is reached or if `CLIENT UNBLOCK`
                      is invoked, in order to send an error to the client.

    free_privdata:    called in order to free the private data that is passed
                      by RedisModule_UnblockClient() call.

Note: [`RedisModule_UnblockClient`](#RedisModule_UnblockClient) should be called for every blocked client,
      even if client was killed, timed-out or disconnected. Failing to do so
      will result in memory leaks.

There are some cases where [`RedisModule_BlockClient()`](#RedisModule_BlockClient) cannot be used:

1. If the client is a Lua script.
2. If the client is executing a MULTI block.

In these cases, a call to [`RedisModule_BlockClient()`](#RedisModule_BlockClient) will **not** block the
client, but instead produce a specific error reply.

A module that registers a `timeout_callback` function can also be unblocked
using the `CLIENT UNBLOCK` command, which will trigger the timeout callback.
If a callback function is not registered, then the blocked client will be
treated as if it is not in a blocked state and `CLIENT UNBLOCK` will return
a zero value.

Measuring background time: By default the time spent in the blocked command
is not account for the total command duration. To include such time you should
use [`RedisModule_BlockedClientMeasureTimeStart()`](#RedisModule_BlockedClientMeasureTimeStart) and [`RedisModule_BlockedClientMeasureTimeEnd()`](#RedisModule_BlockedClientMeasureTimeEnd) one,
or multiple times within the blocking command background work.

<span id="RedisModule_BlockClientOnKeys"></span>

### `RedisModule_BlockClientOnKeys`

    RedisModuleBlockedClient *RedisModule_BlockClientOnKeys(RedisModuleCtx *ctx,
                                                            RedisModuleCmdFunc reply_callback,
                                                            RedisModuleCmdFunc timeout_callback,
                                                            void (*free_privdata)(RedisModuleCtx*, void*),
                                                            long long timeout_ms,
                                                            RedisModuleString **keys,
                                                            int numkeys,
                                                            void *privdata);

**Available since:** 6.0.0

This call is similar to [`RedisModule_BlockClient()`](#RedisModule_BlockClient), however in this case we
don't just block the client, but also ask Redis to unblock it automatically
once certain keys become "ready", that is, contain more data.

Basically this is similar to what a typical Redis command usually does,
like BLPOP or BZPOPMAX: the client blocks if it cannot be served ASAP,
and later when the key receives new data (a list push for instance), the
client is unblocked and served.

However in the case of this module API, when the client is unblocked?

1. If you block on a key of a type that has blocking operations associated,
   like a list, a sorted set, a stream, and so forth, the client may be
   unblocked once the relevant key is targeted by an operation that normally
   unblocks the native blocking operations for that type. So if we block
   on a list key, an RPUSH command may unblock our client and so forth.
2. If you are implementing your native data type, or if you want to add new
   unblocking conditions in addition to "1", you can call the modules API
   [`RedisModule_SignalKeyAsReady()`](#RedisModule_SignalKeyAsReady).

Anyway we can't be sure if the client should be unblocked just because the
key is signaled as ready: for instance a successive operation may change the
key, or a client in queue before this one can be served, modifying the key
as well and making it empty again. So when a client is blocked with
[`RedisModule_BlockClientOnKeys()`](#RedisModule_BlockClientOnKeys) the reply callback is not called after
[`RedisModule_UnblockClient()`](#RedisModule_UnblockClient) is called, but every time a key is signaled as ready:
if the reply callback can serve the client, it returns `REDISMODULE_OK`
and the client is unblocked, otherwise it will return `REDISMODULE_ERR`
and we'll try again later.

The reply callback can access the key that was signaled as ready by
calling the API [`RedisModule_GetBlockedClientReadyKey()`](#RedisModule_GetBlockedClientReadyKey), that returns
just the string name of the key as a `RedisModuleString` object.

Thanks to this system we can setup complex blocking scenarios, like
unblocking a client only if a list contains at least 5 items or other
more fancy logics.

Note that another difference with [`RedisModule_BlockClient()`](#RedisModule_BlockClient), is that here
we pass the private data directly when blocking the client: it will
be accessible later in the reply callback. Normally when blocking with
[`RedisModule_BlockClient()`](#RedisModule_BlockClient) the private data to reply to the client is
passed when calling [`RedisModule_UnblockClient()`](#RedisModule_UnblockClient) but here the unblocking
is performed by Redis itself, so we need to have some private data before
hand. The private data is used to store any information about the specific
unblocking operation that you are implementing. Such information will be
freed using the `free_privdata` callback provided by the user.

However the reply callback will be able to access the argument vector of
the command, so the private data is often not needed.

Note: Under normal circumstances [`RedisModule_UnblockClient`](#RedisModule_UnblockClient) should not be
      called for clients that are blocked on keys (Either the key will
      become ready or a timeout will occur). If for some reason you do want
      to call RedisModule_UnblockClient it is possible: Client will be
      handled as if it were timed-out (You must implement the timeout
      callback in that case).

<span id="RedisModule_SignalKeyAsReady"></span>

### `RedisModule_SignalKeyAsReady`

    void RedisModule_SignalKeyAsReady(RedisModuleCtx *ctx, RedisModuleString *key);

**Available since:** 6.0.0

This function is used in order to potentially unblock a client blocked
on keys with [`RedisModule_BlockClientOnKeys()`](#RedisModule_BlockClientOnKeys). When this function is called,
all the clients blocked for this key will get their `reply_callback` called.

Note: The function has no effect if the signaled key doesn't exist.

<span id="RedisModule_UnblockClient"></span>

### `RedisModule_UnblockClient`

    int RedisModule_UnblockClient(RedisModuleBlockedClient *bc, void *privdata);

**Available since:** 4.0.0

Unblock a client blocked by `RedisModule_BlockedClient`. This will trigger
the reply callbacks to be called in order to reply to the client.
The 'privdata' argument will be accessible by the reply callback, so
the caller of this function can pass any value that is needed in order to
actually reply to the client.

A common usage for 'privdata' is a thread that computes something that
needs to be passed to the client, included but not limited some slow
to compute reply or some reply obtained via networking.

Note 1: this function can be called from threads spawned by the module.

Note 2: when we unblock a client that is blocked for keys using the API
[`RedisModule_BlockClientOnKeys()`](#RedisModule_BlockClientOnKeys), the privdata argument here is not used.
Unblocking a client that was blocked for keys using this API will still
require the client to get some reply, so the function will use the
"timeout" handler in order to do so (The privdata provided in
[`RedisModule_BlockClientOnKeys()`](#RedisModule_BlockClientOnKeys) is accessible from the timeout
callback via [`RedisModule_GetBlockedClientPrivateData`](#RedisModule_GetBlockedClientPrivateData)).

<span id="RedisModule_AbortBlock"></span>

### `RedisModule_AbortBlock`

    int RedisModule_AbortBlock(RedisModuleBlockedClient *bc);

**Available since:** 4.0.0

Abort a blocked client blocking operation: the client will be unblocked
without firing any callback.

<span id="RedisModule_SetDisconnectCallback"></span>

### `RedisModule_SetDisconnectCallback`

    void RedisModule_SetDisconnectCallback(RedisModuleBlockedClient *bc,
                                           RedisModuleDisconnectFunc callback);

**Available since:** 5.0.0

Set a callback that will be called if a blocked client disconnects
before the module has a chance to call [`RedisModule_UnblockClient()`](#RedisModule_UnblockClient)

Usually what you want to do there, is to cleanup your module state
so that you can call [`RedisModule_UnblockClient()`](#RedisModule_UnblockClient) safely, otherwise
the client will remain blocked forever if the timeout is large.

Notes:

1. It is not safe to call Reply* family functions here, it is also
   useless since the client is gone.

2. This callback is not called if the client disconnects because of
   a timeout. In such a case, the client is unblocked automatically
   and the timeout callback is called.

<span id="RedisModule_IsBlockedReplyRequest"></span>

### `RedisModule_IsBlockedReplyRequest`

    int RedisModule_IsBlockedReplyRequest(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Return non-zero if a module command was called in order to fill the
reply for a blocked client.

<span id="RedisModule_IsBlockedTimeoutRequest"></span>

### `RedisModule_IsBlockedTimeoutRequest`

    int RedisModule_IsBlockedTimeoutRequest(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Return non-zero if a module command was called in order to fill the
reply for a blocked client that timed out.

<span id="RedisModule_GetBlockedClientPrivateData"></span>

### `RedisModule_GetBlockedClientPrivateData`

    void *RedisModule_GetBlockedClientPrivateData(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Get the private data set by [`RedisModule_UnblockClient()`](#RedisModule_UnblockClient)

<span id="RedisModule_GetBlockedClientReadyKey"></span>

### `RedisModule_GetBlockedClientReadyKey`

    RedisModuleString *RedisModule_GetBlockedClientReadyKey(RedisModuleCtx *ctx);

**Available since:** 6.0.0

Get the key that is ready when the reply callback is called in the context
of a client blocked by [`RedisModule_BlockClientOnKeys()`](#RedisModule_BlockClientOnKeys).

<span id="RedisModule_GetBlockedClientHandle"></span>

### `RedisModule_GetBlockedClientHandle`

    RedisModuleBlockedClient *RedisModule_GetBlockedClientHandle(RedisModuleCtx *ctx);

**Available since:** 5.0.0

Get the blocked client associated with a given context.
This is useful in the reply and timeout callbacks of blocked clients,
before sometimes the module has the blocked client handle references
around, and wants to cleanup it.

<span id="RedisModule_BlockedClientDisconnected"></span>

### `RedisModule_BlockedClientDisconnected`

    int RedisModule_BlockedClientDisconnected(RedisModuleCtx *ctx);

**Available since:** 5.0.0

Return true if when the free callback of a blocked client is called,
the reason for the client to be unblocked is that it disconnected
while it was blocked.

<span id="section-thread-safe-contexts"></span>

## Thread Safe Contexts

<span id="RedisModule_GetThreadSafeContext"></span>

### `RedisModule_GetThreadSafeContext`

    RedisModuleCtx *RedisModule_GetThreadSafeContext(RedisModuleBlockedClient *bc);

**Available since:** 4.0.0

Return a context which can be used inside threads to make Redis context
calls with certain modules APIs. If 'bc' is not NULL then the module will
be bound to a blocked client, and it will be possible to use the
`RedisModule_Reply*` family of functions to accumulate a reply for when the
client will be unblocked. Otherwise the thread safe context will be
detached by a specific client.

To call non-reply APIs, the thread safe context must be prepared with:

    RedisModule_ThreadSafeContextLock(ctx);
    ... make your call here ...
    RedisModule_ThreadSafeContextUnlock(ctx);

This is not needed when using `RedisModule_Reply*` functions, assuming
that a blocked client was used when the context was created, otherwise
no `RedisModule_Reply`* call should be made at all.

NOTE: If you're creating a detached thread safe context (bc is NULL),
consider using `RM_GetDetachedThreadSafeContext` which will also retain
the module ID and thus be more useful for logging.

<span id="RedisModule_GetDetachedThreadSafeContext"></span>

### `RedisModule_GetDetachedThreadSafeContext`

    RedisModuleCtx *RedisModule_GetDetachedThreadSafeContext(RedisModuleCtx *ctx);

**Available since:** 6.0.9

Return a detached thread safe context that is not associated with any
specific blocked client, but is associated with the module's context.

This is useful for modules that wish to hold a global context over
a long term, for purposes such as logging.

<span id="RedisModule_FreeThreadSafeContext"></span>

### `RedisModule_FreeThreadSafeContext`

    void RedisModule_FreeThreadSafeContext(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Release a thread safe context.

<span id="RedisModule_ThreadSafeContextLock"></span>

### `RedisModule_ThreadSafeContextLock`

    void RedisModule_ThreadSafeContextLock(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Acquire the server lock before executing a thread safe API call.
This is not needed for `RedisModule_Reply*` calls when there is
a blocked client connected to the thread safe context.

<span id="RedisModule_ThreadSafeContextTryLock"></span>

### `RedisModule_ThreadSafeContextTryLock`

    int RedisModule_ThreadSafeContextTryLock(RedisModuleCtx *ctx);

**Available since:** 6.0.8

Similar to [`RedisModule_ThreadSafeContextLock`](#RedisModule_ThreadSafeContextLock) but this function
would not block if the server lock is already acquired.

If successful (lock acquired) `REDISMODULE_OK` is returned,
otherwise `REDISMODULE_ERR` is returned and errno is set
accordingly.

<span id="RedisModule_ThreadSafeContextUnlock"></span>

### `RedisModule_ThreadSafeContextUnlock`

    void RedisModule_ThreadSafeContextUnlock(RedisModuleCtx *ctx);

**Available since:** 4.0.0

Release the server lock after a thread safe API call was executed.

<span id="section-module-keyspace-notifications-api"></span>

## Module Keyspace Notifications API

<span id="RedisModule_SubscribeToKeyspaceEvents"></span>

### `RedisModule_SubscribeToKeyspaceEvents`

    int RedisModule_SubscribeToKeyspaceEvents(RedisModuleCtx *ctx,
                                              int types,
                                              RedisModuleNotificationFunc callback);

**Available since:** 4.0.9

Subscribe to keyspace notifications. This is a low-level version of the
keyspace-notifications API. A module can register callbacks to be notified
when keyspace events occur.

Notification events are filtered by their type (string events, set events,
etc), and the subscriber callback receives only events that match a specific
mask of event types.

When subscribing to notifications with [`RedisModule_SubscribeToKeyspaceEvents`](#RedisModule_SubscribeToKeyspaceEvents)
the module must provide an event type-mask, denoting the events the subscriber
is interested in. This can be an ORed mask of any of the following flags:

 - `REDISMODULE_NOTIFY_GENERIC`: Generic commands like DEL, EXPIRE, RENAME
 - `REDISMODULE_NOTIFY_STRING`: String events
 - `REDISMODULE_NOTIFY_LIST`: List events
 - `REDISMODULE_NOTIFY_SET`: Set events
 - `REDISMODULE_NOTIFY_HASH`: Hash events
 - `REDISMODULE_NOTIFY_ZSET`: Sorted Set events
 - `REDISMODULE_NOTIFY_EXPIRED`: Expiration events
 - `REDISMODULE_NOTIFY_EVICTED`: Eviction events
 - `REDISMODULE_NOTIFY_STREAM`: Stream events
 - `REDISMODULE_NOTIFY_MODULE`: Module types events
 - `REDISMODULE_NOTIFY_KEYMISS`: Key-miss events
 - `REDISMODULE_NOTIFY_ALL`: All events (Excluding `REDISMODULE_NOTIFY_KEYMISS`)
 - `REDISMODULE_NOTIFY_LOADED`: A special notification available only for modules,
                              indicates that the key was loaded from persistence.
                              Notice, when this event fires, the given key
                              can not be retained, use RM_CreateStringFromString
                              instead.

We do not distinguish between key events and keyspace events, and it is up
to the module to filter the actions taken based on the key.

The subscriber signature is:

    int (*RedisModuleNotificationFunc) (RedisModuleCtx *ctx, int type,
                                        const char *event,
                                        RedisModuleString *key);

`type` is the event type bit, that must match the mask given at registration
time. The event string is the actual command being executed, and key is the
relevant Redis key.

Notification callback gets executed with a redis context that can not be
used to send anything to the client, and has the db number where the event
occurred as its selected db number.

Notice that it is not necessary to enable notifications in redis.conf for
module notifications to work.

Warning: the notification callbacks are performed in a synchronous manner,
so notification callbacks must to be fast, or they would slow Redis down.
If you need to take long actions, use threads to offload them.

See [https://redis.io/topics/notifications](https://redis.io/topics/notifications) for more information.

<span id="RedisModule_GetNotifyKeyspaceEvents"></span>

### `RedisModule_GetNotifyKeyspaceEvents`

    int RedisModule_GetNotifyKeyspaceEvents();

**Available since:** 6.0.0

Get the configured bitmap of notify-keyspace-events (Could be used
for additional filtering in `RedisModuleNotificationFunc`)

<span id="RedisModule_NotifyKeyspaceEvent"></span>

### `RedisModule_NotifyKeyspaceEvent`

    int RedisModule_NotifyKeyspaceEvent(RedisModuleCtx *ctx,
                                        int type,
                                        const char *event,
                                        RedisModuleString *key);

**Available since:** 6.0.0

Expose notifyKeyspaceEvent to modules

<span id="section-modules-cluster-api"></span>

## Modules Cluster API

<span id="RedisModule_RegisterClusterMessageReceiver"></span>

### `RedisModule_RegisterClusterMessageReceiver`

    void RedisModule_RegisterClusterMessageReceiver(RedisModuleCtx *ctx,
                                                    uint8_t type,
                                                    RedisModuleClusterMessageReceiver callback);

**Available since:** 5.0.0

Register a callback receiver for cluster messages of type 'type'. If there
was already a registered callback, this will replace the callback function
with the one provided, otherwise if the callback is set to NULL and there
is already a callback for this function, the callback is unregistered
(so this API call is also used in order to delete the receiver).

<span id="RedisModule_SendClusterMessage"></span>

### `RedisModule_SendClusterMessage`

    int RedisModule_SendClusterMessage(RedisModuleCtx *ctx,
                                       const char *target_id,
                                       uint8_t type,
                                       const char *msg,
                                       uint32_t len);

**Available since:** 5.0.0

Send a message to all the nodes in the cluster if `target` is NULL, otherwise
at the specified target, which is a `REDISMODULE_NODE_ID_LEN` bytes node ID, as
returned by the receiver callback or by the nodes iteration functions.

The function returns `REDISMODULE_OK` if the message was successfully sent,
otherwise if the node is not connected or such node ID does not map to any
known cluster node, `REDISMODULE_ERR` is returned.

<span id="RedisModule_GetClusterNodesList"></span>

### `RedisModule_GetClusterNodesList`

    char **RedisModule_GetClusterNodesList(RedisModuleCtx *ctx, size_t *numnodes);

**Available since:** 5.0.0

Return an array of string pointers, each string pointer points to a cluster
node ID of exactly `REDISMODULE_NODE_ID_LEN` bytes (without any null term).
The number of returned node IDs is stored into `*numnodes`.
However if this function is called by a module not running an a Redis
instance with Redis Cluster enabled, NULL is returned instead.

The IDs returned can be used with [`RedisModule_GetClusterNodeInfo()`](#RedisModule_GetClusterNodeInfo) in order
to get more information about single node.

The array returned by this function must be freed using the function
[`RedisModule_FreeClusterNodesList()`](#RedisModule_FreeClusterNodesList).

Example:

    size_t count, j;
    char **ids = RedisModule_GetClusterNodesList(ctx,&count);
    for (j = 0; j < count; j++) {
        RedisModule_Log(ctx,"notice","Node %.*s",
            REDISMODULE_NODE_ID_LEN,ids[j]);
    }
    RedisModule_FreeClusterNodesList(ids);

<span id="RedisModule_FreeClusterNodesList"></span>

### `RedisModule_FreeClusterNodesList`

    void RedisModule_FreeClusterNodesList(char **ids);

**Available since:** 5.0.0

Free the node list obtained with [`RedisModule_GetClusterNodesList`](#RedisModule_GetClusterNodesList).

<span id="RedisModule_GetMyClusterID"></span>

### `RedisModule_GetMyClusterID`

    const char *RedisModule_GetMyClusterID(void);

**Available since:** 5.0.0

Return this node ID (`REDISMODULE_CLUSTER_ID_LEN` bytes) or NULL if the cluster
is disabled.

<span id="RedisModule_GetClusterSize"></span>

### `RedisModule_GetClusterSize`

    size_t RedisModule_GetClusterSize(void);

**Available since:** 5.0.0

Return the number of nodes in the cluster, regardless of their state
(handshake, noaddress, ...) so that the number of active nodes may actually
be smaller, but not greater than this number. If the instance is not in
cluster mode, zero is returned.

<span id="RedisModule_GetClusterNodeInfo"></span>

### `RedisModule_GetClusterNodeInfo`

    int RedisModule_GetClusterNodeInfo(RedisModuleCtx *ctx,
                                       const char *id,
                                       char *ip,
                                       char *master_id,
                                       int *port,
                                       int *flags);

**Available since:** 5.0.0

Populate the specified info for the node having as ID the specified 'id',
then returns `REDISMODULE_OK`. Otherwise if the format of node ID is invalid
or the node ID does not exist from the POV of this local node, `REDISMODULE_ERR`
is returned.

The arguments `ip`, `master_id`, `port` and `flags` can be NULL in case we don't
need to populate back certain info. If an `ip` and `master_id` (only populated
if the instance is a slave) are specified, they point to buffers holding
at least `REDISMODULE_NODE_ID_LEN` bytes. The strings written back as `ip`
and `master_id` are not null terminated.

The list of flags reported is the following:

* `REDISMODULE_NODE_MYSELF`:       This node
* `REDISMODULE_NODE_MASTER`:       The node is a master
* `REDISMODULE_NODE_SLAVE`:        The node is a replica
* `REDISMODULE_NODE_PFAIL`:        We see the node as failing
* `REDISMODULE_NODE_FAIL`:         The cluster agrees the node is failing
* `REDISMODULE_NODE_NOFAILOVER`:   The slave is configured to never failover

<span id="RedisModule_SetClusterFlags"></span>

### `RedisModule_SetClusterFlags`

    void RedisModule_SetClusterFlags(RedisModuleCtx *ctx, uint64_t flags);

**Available since:** 5.0.0

Set Redis Cluster flags in order to change the normal behavior of
Redis Cluster, especially with the goal of disabling certain functions.
This is useful for modules that use the Cluster API in order to create
a different distributed system, but still want to use the Redis Cluster
message bus. Flags that can be set:

* `CLUSTER_MODULE_FLAG_NO_FAILOVER`
* `CLUSTER_MODULE_FLAG_NO_REDIRECTION`

With the following effects:

* `NO_FAILOVER`: prevent Redis Cluster slaves from failing over a dead master.
               Also disables the replica migration feature.

* `NO_REDIRECTION`: Every node will accept any key, without trying to perform
                  partitioning according to the Redis Cluster algorithm.
                  Slots information will still be propagated across the
                  cluster, but without effect.

<span id="section-modules-timers-api"></span>

## Modules Timers API

Module timers are a high precision "green timers" abstraction where
every module can register even millions of timers without problems, even if
the actual event loop will just have a single timer that is used to awake the
module timers subsystem in order to process the next event.

All the timers are stored into a radix tree, ordered by expire time, when
the main Redis event loop timer callback is called, we try to process all
the timers already expired one after the other. Then we re-enter the event
loop registering a timer that will expire when the next to process module
timer will expire.

Every time the list of active timers drops to zero, we unregister the
main event loop timer, so that there is no overhead when such feature is
not used.

<span id="RedisModule_CreateTimer"></span>

### `RedisModule_CreateTimer`

    RedisModuleTimerID RedisModule_CreateTimer(RedisModuleCtx *ctx,
                                               mstime_t period,
                                               RedisModuleTimerProc callback,
                                               void *data);

**Available since:** 5.0.0

Create a new timer that will fire after `period` milliseconds, and will call
the specified function using `data` as argument. The returned timer ID can be
used to get information from the timer or to stop it before it fires.
Note that for the common use case of a repeating timer (Re-registration
of the timer inside the `RedisModuleTimerProc` callback) it matters when
this API is called:
If it is called at the beginning of 'callback' it means
the event will triggered every 'period'.
If it is called at the end of 'callback' it means
there will 'period' milliseconds gaps between events.
(If the time it takes to execute 'callback' is negligible the two
statements above mean the same)

<span id="RedisModule_StopTimer"></span>

### `RedisModule_StopTimer`

    int RedisModule_StopTimer(RedisModuleCtx *ctx,
                              RedisModuleTimerID id,
                              void **data);

**Available since:** 5.0.0

Stop a timer, returns `REDISMODULE_OK` if the timer was found, belonged to the
calling module, and was stopped, otherwise `REDISMODULE_ERR` is returned.
If not NULL, the data pointer is set to the value of the data argument when
the timer was created.

<span id="RedisModule_GetTimerInfo"></span>

### `RedisModule_GetTimerInfo`

    int RedisModule_GetTimerInfo(RedisModuleCtx *ctx,
                                 RedisModuleTimerID id,
                                 uint64_t *remaining,
                                 void **data);

**Available since:** 5.0.0

Obtain information about a timer: its remaining time before firing
(in milliseconds), and the private data pointer associated with the timer.
If the timer specified does not exist or belongs to a different module
no information is returned and the function returns `REDISMODULE_ERR`, otherwise
`REDISMODULE_OK` is returned. The arguments remaining or data can be NULL if
the caller does not need certain information.

<span id="section-modules-eventloop-api"></span>

## Modules EventLoop API

<span id="RedisModule_EventLoopAdd"></span>

### `RedisModule_EventLoopAdd`

    int RedisModule_EventLoopAdd(int fd,
                                 int mask,
                                 RedisModuleEventLoopFunc func,
                                 void *user_data);

**Available since:** 7.0.0

Add a pipe / socket event to the event loop.

* `mask` must be one of the following values:

    * `REDISMODULE_EVENTLOOP_READABLE`
    * `REDISMODULE_EVENTLOOP_WRITABLE`
    * `REDISMODULE_EVENTLOOP_READABLE | REDISMODULE_EVENTLOOP_WRITABLE`

On success `REDISMODULE_OK` is returned, otherwise
`REDISMODULE_ERR` is returned and errno is set to the following values:

* ERANGE: `fd` is negative or higher than `maxclients` Redis config.
* EINVAL: `callback` is NULL or `mask` value is invalid.

`errno` might take other values in case of an internal error.

Example:

    void onReadable(int fd, void *user_data, int mask) {
        char buf[32];
        int bytes = read(fd,buf,sizeof(buf));
        printf("Read %d bytes \n", bytes);
    }
    RM_EventLoopAdd(fd, REDISMODULE_EVENTLOOP_READABLE, onReadable, NULL);

<span id="RedisModule_EventLoopDel"></span>

### `RedisModule_EventLoopDel`

    int RedisModule_EventLoopDel(int fd, int mask);

**Available since:** 7.0.0

Delete a pipe / socket event from the event loop.

* `mask` must be one of the following values:

    * `REDISMODULE_EVENTLOOP_READABLE`
    * `REDISMODULE_EVENTLOOP_WRITABLE`
    * `REDISMODULE_EVENTLOOP_READABLE | REDISMODULE_EVENTLOOP_WRITABLE`

On success `REDISMODULE_OK` is returned, otherwise
`REDISMODULE_ERR` is returned and errno is set to the following values:

* ERANGE: `fd` is negative or higher than `maxclients` Redis config.
* EINVAL: `mask` value is invalid.

<span id="RedisModule_EventLoopAddOneShot"></span>

### `RedisModule_EventLoopAddOneShot`

    int RedisModule_EventLoopAddOneShot(RedisModuleEventLoopOneShotFunc func,
                                        void *user_data);

**Available since:** 7.0.0

This function can be called from other threads to trigger callback on Redis
main thread. On success `REDISMODULE_OK` is returned. If `func` is NULL
`REDISMODULE_ERR` is returned and errno is set to EINVAL.

<span id="section-modules-acl-api"></span>

## Modules ACL API

Implements a hook into the authentication and authorization within Redis.

<span id="RedisModule_CreateModuleUser"></span>

### `RedisModule_CreateModuleUser`

    RedisModuleUser *RedisModule_CreateModuleUser(const char *name);

**Available since:** 6.0.0

Creates a Redis ACL user that the module can use to authenticate a client.
After obtaining the user, the module should set what such user can do
using the `RedisModule_SetUserACL()` function. Once configured, the user
can be used in order to authenticate a connection, with the specified
ACL rules, using the `RedisModule_AuthClientWithUser()` function.

Note that:

* Users created here are not listed by the ACL command.
* Users created here are not checked for duplicated name, so it's up to
  the module calling this function to take care of not creating users
  with the same name.
* The created user can be used to authenticate multiple Redis connections.

The caller can later free the user using the function
[`RedisModule_FreeModuleUser()`](#RedisModule_FreeModuleUser). When this function is called, if there are
still clients authenticated with this user, they are disconnected.
The function to free the user should only be used when the caller really
wants to invalidate the user to define a new one with different
capabilities.

<span id="RedisModule_FreeModuleUser"></span>

### `RedisModule_FreeModuleUser`

    int RedisModule_FreeModuleUser(RedisModuleUser *user);

**Available since:** 6.0.0

Frees a given user and disconnects all of the clients that have been
authenticated with it. See [`RedisModule_CreateModuleUser`](#RedisModule_CreateModuleUser) for detailed usage.

<span id="RedisModule_SetModuleUserACL"></span>

### `RedisModule_SetModuleUserACL`

    int RedisModule_SetModuleUserACL(RedisModuleUser *user, const char* acl);

**Available since:** 6.0.0

Sets the permissions of a user created through the redis module
interface. The syntax is the same as ACL SETUSER, so refer to the
documentation in acl.c for more information. See [`RedisModule_CreateModuleUser`](#RedisModule_CreateModuleUser)
for detailed usage.

Returns `REDISMODULE_OK` on success and `REDISMODULE_ERR` on failure
and will set an errno describing why the operation failed.

<span id="RedisModule_GetCurrentUserName"></span>

### `RedisModule_GetCurrentUserName`

    RedisModuleString *RedisModule_GetCurrentUserName(RedisModuleCtx *ctx);

**Available since:** 7.0.0

Retrieve the user name of the client connection behind the current context.
The user name can be used later, in order to get a `RedisModuleUser`.
See more information in [`RedisModule_GetModuleUserFromUserName`](#RedisModule_GetModuleUserFromUserName).

The returned string must be released with [`RedisModule_FreeString()`](#RedisModule_FreeString) or by
enabling automatic memory management.

<span id="RedisModule_GetModuleUserFromUserName"></span>

### `RedisModule_GetModuleUserFromUserName`

    RedisModuleUser *RedisModule_GetModuleUserFromUserName(RedisModuleString *name);

**Available since:** 7.0.0

A `RedisModuleUser` can be used to check if command, key or channel can be executed or
accessed according to the ACLs rules associated with that user.
When a Module wants to do ACL checks on a general ACL user (not created by [`RedisModule_CreateModuleUser`](#RedisModule_CreateModuleUser)),
it can get the `RedisModuleUser` from this API, based on the user name retrieved by [`RedisModule_GetCurrentUserName`](#RedisModule_GetCurrentUserName).

Since a general ACL user can be deleted at any time, this `RedisModuleUser` should be used only in the context
where this function was called. In order to do ACL checks out of that context, the Module can store the user name,
and call this API at any other context.

Returns NULL if the user is disabled or the user does not exist.
The caller should later free the user using the function [`RedisModule_FreeModuleUser()`](#RedisModule_FreeModuleUser).

<span id="RedisModule_ACLCheckCommandPermissions"></span>

### `RedisModule_ACLCheckCommandPermissions`

    int RedisModule_ACLCheckCommandPermissions(RedisModuleUser *user,
                                               RedisModuleString **argv,
                                               int argc);

**Available since:** 7.0.0

Checks if the command can be executed by the user, according to the ACLs associated with it.

On success a `REDISMODULE_OK` is returned, otherwise
`REDISMODULE_ERR` is returned and errno is set to the following values:

* ENOENT: Specified command does not exist.
* EACCES: Command cannot be executed, according to ACL rules

<span id="RedisModule_ACLCheckKeyPermissions"></span>

### `RedisModule_ACLCheckKeyPermissions`

    int RedisModule_ACLCheckKeyPermissions(RedisModuleUser *user,
                                           RedisModuleString *key,
                                           int flags);

**Available since:** 7.0.0

Check if the key can be accessed by the user according to the ACLs attached to the user
and the flags representing the key access. The flags are the same that are used in the
keyspec for logical operations. These flags are documented in [`RedisModule_SetCommandInfo`](#RedisModule_SetCommandInfo) as
the `REDISMODULE_CMD_KEY_ACCESS`, `REDISMODULE_CMD_KEY_UPDATE`, `REDISMODULE_CMD_KEY_INSERT`,
and `REDISMODULE_CMD_KEY_DELETE` flags.

If no flags are supplied, the user is still required to have some access to the key for
this command to return successfully.

If the user is able to access the key then `REDISMODULE_OK` is returned, otherwise
`REDISMODULE_ERR` is returned and errno is set to one of the following values:

* EINVAL: The provided flags are invalid.
* EACCESS: The user does not have permission to access the key.

<span id="RedisModule_ACLCheckChannelPermissions"></span>

### `RedisModule_ACLCheckChannelPermissions`

    int RedisModule_ACLCheckChannelPermissions(RedisModuleUser *user,
                                               RedisModuleString *ch,
                                               int flags);

**Available since:** 7.0.0

Check if the pubsub channel can be accessed by the user based off of the given
access flags. See [`RedisModule_ChannelAtPosWithFlags`](#RedisModule_ChannelAtPosWithFlags) for more information about the
possible flags that can be passed in.

If the user is able to access the pubsub channel then `REDISMODULE_OK` is returned, otherwise
`REDISMODULE_ERR` is returned and errno is set to one of the following values:

* EINVAL: The provided flags are invalid.
* EACCESS: The user does not have permission to access the pubsub channel.

<span id="RedisModule_ACLAddLogEntry"></span>

### `RedisModule_ACLAddLogEntry`

    int RedisModule_ACLAddLogEntry(RedisModuleCtx *ctx,
                                   RedisModuleUser *user,
                                   RedisModuleString *object,
                                   RedisModuleACLLogEntryReason reason);

**Available since:** 7.0.0

Adds a new entry in the ACL log.
Returns `REDISMODULE_OK` on success and `REDISMODULE_ERR` on error.

For more information about ACL log, please refer to [https://redis.io/commands/acl-log](https://redis.io/commands/acl-log)

<span id="RedisModule_AuthenticateClientWithUser"></span>

### `RedisModule_AuthenticateClientWithUser`

    int RedisModule_AuthenticateClientWithUser(RedisModuleCtx *ctx,
                                               RedisModuleUser *module_user,
                                               RedisModuleUserChangedFunc callback,
                                               void *privdata,
                                               uint64_t *client_id);

**Available since:** 6.0.0

Authenticate the current context's user with the provided redis acl user.
Returns `REDISMODULE_ERR` if the user is disabled.

See authenticateClientWithUser for information about callback, `client_id`,
and general usage for authentication.

<span id="RedisModule_AuthenticateClientWithACLUser"></span>

### `RedisModule_AuthenticateClientWithACLUser`

    int RedisModule_AuthenticateClientWithACLUser(RedisModuleCtx *ctx,
                                                  const char *name,
                                                  size_t len,
                                                  RedisModuleUserChangedFunc callback,
                                                  void *privdata,
                                                  uint64_t *client_id);

**Available since:** 6.0.0

Authenticate the current context's user with the provided redis acl user.
Returns `REDISMODULE_ERR` if the user is disabled or the user does not exist.

See authenticateClientWithUser for information about callback, `client_id`,
and general usage for authentication.

<span id="RedisModule_DeauthenticateAndCloseClient"></span>

### `RedisModule_DeauthenticateAndCloseClient`

    int RedisModule_DeauthenticateAndCloseClient(RedisModuleCtx *ctx,
                                                 uint64_t client_id);

**Available since:** 6.0.0

Deauthenticate and close the client. The client resources will not
be immediately freed, but will be cleaned up in a background job. This is
the recommended way to deauthenticate a client since most clients can't
handle users becoming deauthenticated. Returns `REDISMODULE_ERR` when the
client doesn't exist and `REDISMODULE_OK` when the operation was successful.

The client ID is returned from the [`RedisModule_AuthenticateClientWithUser`](#RedisModule_AuthenticateClientWithUser) and
[`RedisModule_AuthenticateClientWithACLUser`](#RedisModule_AuthenticateClientWithACLUser) APIs, but can be obtained through
the CLIENT api or through server events.

This function is not thread safe, and must be executed within the context
of a command or thread safe context.

<span id="RedisModule_RedactClientCommandArgument"></span>

### `RedisModule_RedactClientCommandArgument`

    int RedisModule_RedactClientCommandArgument(RedisModuleCtx *ctx, int pos);

**Available since:** 7.0.0

Redact the client command argument specified at the given position. Redacted arguments 
are obfuscated in user facing commands such as SLOWLOG or MONITOR, as well as
never being written to server logs. This command may be called multiple times on the
same position.

Note that the command name, position 0, can not be redacted. 

Returns `REDISMODULE_OK` if the argument was redacted and `REDISMODULE_ERR` if there 
was an invalid parameter passed in or the position is outside the client 
argument range.

<span id="RedisModule_GetClientCertificate"></span>

### `RedisModule_GetClientCertificate`

    RedisModuleString *RedisModule_GetClientCertificate(RedisModuleCtx *ctx,
                                                        uint64_t client_id);

**Available since:** 6.0.9

Return the X.509 client-side certificate used by the client to authenticate
this connection.

The return value is an allocated `RedisModuleString` that is a X.509 certificate
encoded in PEM (Base64) format. It should be freed (or auto-freed) by the caller.

A NULL value is returned in the following conditions:

- Connection ID does not exist
- Connection is not a TLS connection
- Connection is a TLS connection but no client certificate was used

<span id="section-modules-dictionary-api"></span>

## Modules Dictionary API

Implements a sorted dictionary (actually backed by a radix tree) with
the usual get / set / del / num-items API, together with an iterator
capable of going back and forth.

<span id="RedisModule_CreateDict"></span>

### `RedisModule_CreateDict`

    RedisModuleDict *RedisModule_CreateDict(RedisModuleCtx *ctx);

**Available since:** 5.0.0

Create a new dictionary. The 'ctx' pointer can be the current module context
or NULL, depending on what you want. Please follow the following rules:

1. Use a NULL context if you plan to retain a reference to this dictionary
   that will survive the time of the module callback where you created it.
2. Use a NULL context if no context is available at the time you are creating
   the dictionary (of course...).
3. However use the current callback context as 'ctx' argument if the
   dictionary time to live is just limited to the callback scope. In this
   case, if enabled, you can enjoy the automatic memory management that will
   reclaim the dictionary memory, as well as the strings returned by the
   Next / Prev dictionary iterator calls.

<span id="RedisModule_FreeDict"></span>

### `RedisModule_FreeDict`

    void RedisModule_FreeDict(RedisModuleCtx *ctx, RedisModuleDict *d);

**Available since:** 5.0.0

Free a dictionary created with [`RedisModule_CreateDict()`](#RedisModule_CreateDict). You need to pass the
context pointer 'ctx' only if the dictionary was created using the
context instead of passing NULL.

<span id="RedisModule_DictSize"></span>

### `RedisModule_DictSize`

    uint64_t RedisModule_DictSize(RedisModuleDict *d);

**Available since:** 5.0.0

Return the size of the dictionary (number of keys).

<span id="RedisModule_DictSetC"></span>

### `RedisModule_DictSetC`

    int RedisModule_DictSetC(RedisModuleDict *d,
                             void *key,
                             size_t keylen,
                             void *ptr);

**Available since:** 5.0.0

Store the specified key into the dictionary, setting its value to the
pointer 'ptr'. If the key was added with success, since it did not
already exist, `REDISMODULE_OK` is returned. Otherwise if the key already
exists the function returns `REDISMODULE_ERR`.

<span id="RedisModule_DictReplaceC"></span>

### `RedisModule_DictReplaceC`

    int RedisModule_DictReplaceC(RedisModuleDict *d,
                                 void *key,
                                 size_t keylen,
                                 void *ptr);

**Available since:** 5.0.0

Like [`RedisModule_DictSetC()`](#RedisModule_DictSetC) but will replace the key with the new
value if the key already exists.

<span id="RedisModule_DictSet"></span>

### `RedisModule_DictSet`

    int RedisModule_DictSet(RedisModuleDict *d, RedisModuleString *key, void *ptr);

**Available since:** 5.0.0

Like [`RedisModule_DictSetC()`](#RedisModule_DictSetC) but takes the key as a `RedisModuleString`.

<span id="RedisModule_DictReplace"></span>

### `RedisModule_DictReplace`

    int RedisModule_DictReplace(RedisModuleDict *d,
                                RedisModuleString *key,
                                void *ptr);

**Available since:** 5.0.0

Like [`RedisModule_DictReplaceC()`](#RedisModule_DictReplaceC) but takes the key as a `RedisModuleString`.

<span id="RedisModule_DictGetC"></span>

### `RedisModule_DictGetC`

    void *RedisModule_DictGetC(RedisModuleDict *d,
                               void *key,
                               size_t keylen,
                               int *nokey);

**Available since:** 5.0.0

Return the value stored at the specified key. The function returns NULL
both in the case the key does not exist, or if you actually stored
NULL at key. So, optionally, if the 'nokey' pointer is not NULL, it will
be set by reference to 1 if the key does not exist, or to 0 if the key
exists.

<span id="RedisModule_DictGet"></span>

### `RedisModule_DictGet`

    void *RedisModule_DictGet(RedisModuleDict *d,
                              RedisModuleString *key,
                              int *nokey);

**Available since:** 5.0.0

Like [`RedisModule_DictGetC()`](#RedisModule_DictGetC) but takes the key as a `RedisModuleString`.

<span id="RedisModule_DictDelC"></span>

### `RedisModule_DictDelC`

    int RedisModule_DictDelC(RedisModuleDict *d,
                             void *key,
                             size_t keylen,
                             void *oldval);

**Available since:** 5.0.0

Remove the specified key from the dictionary, returning `REDISMODULE_OK` if
the key was found and deleted, or `REDISMODULE_ERR` if instead there was
no such key in the dictionary. When the operation is successful, if
'oldval' is not NULL, then '*oldval' is set to the value stored at the
key before it was deleted. Using this feature it is possible to get
a pointer to the value (for instance in order to release it), without
having to call [`RedisModule_DictGet()`](#RedisModule_DictGet) before deleting the key.

<span id="RedisModule_DictDel"></span>

### `RedisModule_DictDel`

    int RedisModule_DictDel(RedisModuleDict *d,
                            RedisModuleString *key,
                            void *oldval);

**Available since:** 5.0.0

Like [`RedisModule_DictDelC()`](#RedisModule_DictDelC) but gets the key as a `RedisModuleString`.

<span id="RedisModule_DictIteratorStartC"></span>

### `RedisModule_DictIteratorStartC`

    RedisModuleDictIter *RedisModule_DictIteratorStartC(RedisModuleDict *d,
                                                        const char *op,
                                                        void *key,
                                                        size_t keylen);

**Available since:** 5.0.0

Return an iterator, setup in order to start iterating from the specified
key by applying the operator 'op', which is just a string specifying the
comparison operator to use in order to seek the first element. The
operators available are:

* `^`   – Seek the first (lexicographically smaller) key.
* `$`   – Seek the last  (lexicographically bigger) key.
* `>`   – Seek the first element greater than the specified key.
* `>=`  – Seek the first element greater or equal than the specified key.
* `<`   – Seek the first element smaller than the specified key.
* `<=`  – Seek the first element smaller or equal than the specified key.
* `==`  – Seek the first element matching exactly the specified key.

Note that for `^` and `$` the passed key is not used, and the user may
just pass NULL with a length of 0.

If the element to start the iteration cannot be seeked based on the
key and operator passed, [`RedisModule_DictNext()`](#RedisModule_DictNext) / Prev() will just return
`REDISMODULE_ERR` at the first call, otherwise they'll produce elements.

<span id="RedisModule_DictIteratorStart"></span>

### `RedisModule_DictIteratorStart`

    RedisModuleDictIter *RedisModule_DictIteratorStart(RedisModuleDict *d,
                                                       const char *op,
                                                       RedisModuleString *key);

**Available since:** 5.0.0

Exactly like [`RedisModule_DictIteratorStartC`](#RedisModule_DictIteratorStartC), but the key is passed as a
`RedisModuleString`.

<span id="RedisModule_DictIteratorStop"></span>

### `RedisModule_DictIteratorStop`

    void RedisModule_DictIteratorStop(RedisModuleDictIter *di);

**Available since:** 5.0.0

Release the iterator created with [`RedisModule_DictIteratorStart()`](#RedisModule_DictIteratorStart). This call
is mandatory otherwise a memory leak is introduced in the module.

<span id="RedisModule_DictIteratorReseekC"></span>

### `RedisModule_DictIteratorReseekC`

    int RedisModule_DictIteratorReseekC(RedisModuleDictIter *di,
                                        const char *op,
                                        void *key,
                                        size_t keylen);

**Available since:** 5.0.0

After its creation with [`RedisModule_DictIteratorStart()`](#RedisModule_DictIteratorStart), it is possible to
change the currently selected element of the iterator by using this
API call. The result based on the operator and key is exactly like
the function [`RedisModule_DictIteratorStart()`](#RedisModule_DictIteratorStart), however in this case the
return value is just `REDISMODULE_OK` in case the seeked element was found,
or `REDISMODULE_ERR` in case it was not possible to seek the specified
element. It is possible to reseek an iterator as many times as you want.

<span id="RedisModule_DictIteratorReseek"></span>

### `RedisModule_DictIteratorReseek`

    int RedisModule_DictIteratorReseek(RedisModuleDictIter *di,
                                       const char *op,
                                       RedisModuleString *key);

**Available since:** 5.0.0

Like [`RedisModule_DictIteratorReseekC()`](#RedisModule_DictIteratorReseekC) but takes the key as a
`RedisModuleString`.

<span id="RedisModule_DictNextC"></span>

### `RedisModule_DictNextC`

    void *RedisModule_DictNextC(RedisModuleDictIter *di,
                                size_t *keylen,
                                void **dataptr);

**Available since:** 5.0.0

Return the current item of the dictionary iterator `di` and steps to the
next element. If the iterator already yield the last element and there
are no other elements to return, NULL is returned, otherwise a pointer
to a string representing the key is provided, and the `*keylen` length
is set by reference (if keylen is not NULL). The `*dataptr`, if not NULL
is set to the value of the pointer stored at the returned key as auxiliary
data (as set by the [`RedisModule_DictSet`](#RedisModule_DictSet) API).

Usage example:

     ... create the iterator here ...
     char *key;
     void *data;
     while((key = RedisModule_DictNextC(iter,&keylen,&data)) != NULL) {
         printf("%.*s %p\n", (int)keylen, key, data);
     }

The returned pointer is of type void because sometimes it makes sense
to cast it to a `char*` sometimes to an unsigned `char*` depending on the
fact it contains or not binary data, so this API ends being more
comfortable to use.

The validity of the returned pointer is until the next call to the
next/prev iterator step. Also the pointer is no longer valid once the
iterator is released.

<span id="RedisModule_DictPrevC"></span>

### `RedisModule_DictPrevC`

    void *RedisModule_DictPrevC(RedisModuleDictIter *di,
                                size_t *keylen,
                                void **dataptr);

**Available since:** 5.0.0

This function is exactly like [`RedisModule_DictNext()`](#RedisModule_DictNext) but after returning
the currently selected element in the iterator, it selects the previous
element (lexicographically smaller) instead of the next one.

<span id="RedisModule_DictNext"></span>

### `RedisModule_DictNext`

    RedisModuleString *RedisModule_DictNext(RedisModuleCtx *ctx,
                                            RedisModuleDictIter *di,
                                            void **dataptr);

**Available since:** 5.0.0

Like `RedisModuleNextC()`, but instead of returning an internally allocated
buffer and key length, it returns directly a module string object allocated
in the specified context 'ctx' (that may be NULL exactly like for the main
API [`RedisModule_CreateString`](#RedisModule_CreateString)).

The returned string object should be deallocated after use, either manually
or by using a context that has automatic memory management active.

<span id="RedisModule_DictPrev"></span>

### `RedisModule_DictPrev`

    RedisModuleString *RedisModule_DictPrev(RedisModuleCtx *ctx,
                                            RedisModuleDictIter *di,
                                            void **dataptr);

**Available since:** 5.0.0

Like [`RedisModule_DictNext()`](#RedisModule_DictNext) but after returning the currently selected
element in the iterator, it selects the previous element (lexicographically
smaller) instead of the next one.

<span id="RedisModule_DictCompareC"></span>

### `RedisModule_DictCompareC`

    int RedisModule_DictCompareC(RedisModuleDictIter *di,
                                 const char *op,
                                 void *key,
                                 size_t keylen);

**Available since:** 5.0.0

Compare the element currently pointed by the iterator to the specified
element given by key/keylen, according to the operator 'op' (the set of
valid operators are the same valid for [`RedisModule_DictIteratorStart`](#RedisModule_DictIteratorStart)).
If the comparison is successful the command returns `REDISMODULE_OK`
otherwise `REDISMODULE_ERR` is returned.

This is useful when we want to just emit a lexicographical range, so
in the loop, as we iterate elements, we can also check if we are still
on range.

The function return `REDISMODULE_ERR` if the iterator reached the
end of elements condition as well.

<span id="RedisModule_DictCompare"></span>

### `RedisModule_DictCompare`

    int RedisModule_DictCompare(RedisModuleDictIter *di,
                                const char *op,
                                RedisModuleString *key);

**Available since:** 5.0.0

Like [`RedisModule_DictCompareC`](#RedisModule_DictCompareC) but gets the key to compare with the current
iterator key as a `RedisModuleString`.

<span id="section-modules-info-fields"></span>

## Modules Info fields

<span id="RedisModule_InfoAddSection"></span>

### `RedisModule_InfoAddSection`

    int RedisModule_InfoAddSection(RedisModuleInfoCtx *ctx, const char *name);

**Available since:** 6.0.0

Used to start a new section, before adding any fields. the section name will
be prefixed by `<modulename>_` and must only include A-Z,a-z,0-9.
NULL or empty string indicates the default section (only `<modulename>`) is used.
When return value is `REDISMODULE_ERR`, the section should and will be skipped.

<span id="RedisModule_InfoBeginDictField"></span>

### `RedisModule_InfoBeginDictField`

    int RedisModule_InfoBeginDictField(RedisModuleInfoCtx *ctx, const char *name);

**Available since:** 6.0.0

Starts a dict field, similar to the ones in INFO KEYSPACE. Use normal
`RedisModule_InfoAddField`* functions to add the items to this field, and
terminate with [`RedisModule_InfoEndDictField`](#RedisModule_InfoEndDictField).

<span id="RedisModule_InfoEndDictField"></span>

### `RedisModule_InfoEndDictField`

    int RedisModule_InfoEndDictField(RedisModuleInfoCtx *ctx);

**Available since:** 6.0.0

Ends a dict field, see [`RedisModule_InfoBeginDictField`](#RedisModule_InfoBeginDictField)

<span id="RedisModule_InfoAddFieldString"></span>

### `RedisModule_InfoAddFieldString`

    int RedisModule_InfoAddFieldString(RedisModuleInfoCtx *ctx,
                                       const char *field,
                                       RedisModuleString *value);

**Available since:** 6.0.0

Used by `RedisModuleInfoFunc` to add info fields.
Each field will be automatically prefixed by `<modulename>_`.
Field names or values must not include `\r\n` or `:`.

<span id="RedisModule_InfoAddFieldCString"></span>

### `RedisModule_InfoAddFieldCString`

    int RedisModule_InfoAddFieldCString(RedisModuleInfoCtx *ctx,
                                        const char *field,
                                        const char *value);

**Available since:** 6.0.0

See [`RedisModule_InfoAddFieldString()`](#RedisModule_InfoAddFieldString).

<span id="RedisModule_InfoAddFieldDouble"></span>

### `RedisModule_InfoAddFieldDouble`

    int RedisModule_InfoAddFieldDouble(RedisModuleInfoCtx *ctx,
                                       const char *field,
                                       double value);

**Available since:** 6.0.0

See [`RedisModule_InfoAddFieldString()`](#RedisModule_InfoAddFieldString).

<span id="RedisModule_InfoAddFieldLongLong"></span>

### `RedisModule_InfoAddFieldLongLong`

    int RedisModule_InfoAddFieldLongLong(RedisModuleInfoCtx *ctx,
                                         const char *field,
                                         long long value);

**Available since:** 6.0.0

See [`RedisModule_InfoAddFieldString()`](#RedisModule_InfoAddFieldString).

<span id="RedisModule_InfoAddFieldULongLong"></span>

### `RedisModule_InfoAddFieldULongLong`

    int RedisModule_InfoAddFieldULongLong(RedisModuleInfoCtx *ctx,
                                          const char *field,
                                          unsigned long long value);

**Available since:** 6.0.0

See [`RedisModule_InfoAddFieldString()`](#RedisModule_InfoAddFieldString).

<span id="RedisModule_RegisterInfoFunc"></span>

### `RedisModule_RegisterInfoFunc`

    int RedisModule_RegisterInfoFunc(RedisModuleCtx *ctx, RedisModuleInfoFunc cb);

**Available since:** 6.0.0

Registers callback for the INFO command. The callback should add INFO fields
by calling the `RedisModule_InfoAddField*()` functions.

<span id="RedisModule_GetServerInfo"></span>

### `RedisModule_GetServerInfo`

    RedisModuleServerInfoData *RedisModule_GetServerInfo(RedisModuleCtx *ctx,
                                                         const char *section);

**Available since:** 6.0.0

Get information about the server similar to the one that returns from the
INFO command. This function takes an optional 'section' argument that may
be NULL. The return value holds the output and can be used with
[`RedisModule_ServerInfoGetField`](#RedisModule_ServerInfoGetField) and alike to get the individual fields.
When done, it needs to be freed with [`RedisModule_FreeServerInfo`](#RedisModule_FreeServerInfo) or with the
automatic memory management mechanism if enabled.

<span id="RedisModule_FreeServerInfo"></span>

### `RedisModule_FreeServerInfo`

    void RedisModule_FreeServerInfo(RedisModuleCtx *ctx,
                                    RedisModuleServerInfoData *data);

**Available since:** 6.0.0

Free data created with [`RedisModule_GetServerInfo()`](#RedisModule_GetServerInfo). You need to pass the
context pointer 'ctx' only if the dictionary was created using the
context instead of passing NULL.

<span id="RedisModule_ServerInfoGetField"></span>

### `RedisModule_ServerInfoGetField`

    RedisModuleString *RedisModule_ServerInfoGetField(RedisModuleCtx *ctx,
                                                      RedisModuleServerInfoData *data,
                                                      const char* field);

**Available since:** 6.0.0

Get the value of a field from data collected with [`RedisModule_GetServerInfo()`](#RedisModule_GetServerInfo). You
need to pass the context pointer 'ctx' only if you want to use auto memory
mechanism to release the returned string. Return value will be NULL if the
field was not found.

<span id="RedisModule_ServerInfoGetFieldC"></span>

### `RedisModule_ServerInfoGetFieldC`

    const char *RedisModule_ServerInfoGetFieldC(RedisModuleServerInfoData *data,
                                                const char* field);

**Available since:** 6.0.0

Similar to [`RedisModule_ServerInfoGetField`](#RedisModule_ServerInfoGetField), but returns a char* which should not be freed but the caller.

<span id="RedisModule_ServerInfoGetFieldSigned"></span>

### `RedisModule_ServerInfoGetFieldSigned`

    long long RedisModule_ServerInfoGetFieldSigned(RedisModuleServerInfoData *data,
                                                   const char* field,
                                                   int *out_err);

**Available since:** 6.0.0

Get the value of a field from data collected with [`RedisModule_GetServerInfo()`](#RedisModule_GetServerInfo). If the
field is not found, or is not numerical or out of range, return value will be
0, and the optional `out_err` argument will be set to `REDISMODULE_ERR`.

<span id="RedisModule_ServerInfoGetFieldUnsigned"></span>

### `RedisModule_ServerInfoGetFieldUnsigned`

    unsigned long long RedisModule_ServerInfoGetFieldUnsigned(RedisModuleServerInfoData *data,
                                                              const char* field,
                                                              int *out_err);

**Available since:** 6.0.0

Get the value of a field from data collected with [`RedisModule_GetServerInfo()`](#RedisModule_GetServerInfo). If the
field is not found, or is not numerical or out of range, return value will be
0, and the optional `out_err` argument will be set to `REDISMODULE_ERR`.

<span id="RedisModule_ServerInfoGetFieldDouble"></span>

### `RedisModule_ServerInfoGetFieldDouble`

    double RedisModule_ServerInfoGetFieldDouble(RedisModuleServerInfoData *data,
                                                const char* field,
                                                int *out_err);

**Available since:** 6.0.0

Get the value of a field from data collected with [`RedisModule_GetServerInfo()`](#RedisModule_GetServerInfo). If the
field is not found, or is not a double, return value will be 0, and the
optional `out_err` argument will be set to `REDISMODULE_ERR`.

<span id="section-modules-utility-apis"></span>

## Modules utility APIs

<span id="RedisModule_GetRandomBytes"></span>

### `RedisModule_GetRandomBytes`

    void RedisModule_GetRandomBytes(unsigned char *dst, size_t len);

**Available since:** 5.0.0

Return random bytes using SHA1 in counter mode with a /dev/urandom
initialized seed. This function is fast so can be used to generate
many bytes without any effect on the operating system entropy pool.
Currently this function is not thread safe.

<span id="RedisModule_GetRandomHexChars"></span>

### `RedisModule_GetRandomHexChars`

    void RedisModule_GetRandomHexChars(char *dst, size_t len);

**Available since:** 5.0.0

Like [`RedisModule_GetRandomBytes()`](#RedisModule_GetRandomBytes) but instead of setting the string to
random bytes the string is set to random characters in the in the
hex charset [0-9a-f].

<span id="section-modules-api-exporting-importing"></span>

## Modules API exporting / importing

<span id="RedisModule_ExportSharedAPI"></span>

### `RedisModule_ExportSharedAPI`

    int RedisModule_ExportSharedAPI(RedisModuleCtx *ctx,
                                    const char *apiname,
                                    void *func);

**Available since:** 5.0.4

This function is called by a module in order to export some API with a
given name. Other modules will be able to use this API by calling the
symmetrical function [`RedisModule_GetSharedAPI()`](#RedisModule_GetSharedAPI) and casting the return value to
the right function pointer.

The function will return `REDISMODULE_OK` if the name is not already taken,
otherwise `REDISMODULE_ERR` will be returned and no operation will be
performed.

IMPORTANT: the apiname argument should be a string literal with static
lifetime. The API relies on the fact that it will always be valid in
the future.

<span id="RedisModule_GetSharedAPI"></span>

### `RedisModule_GetSharedAPI`

    void *RedisModule_GetSharedAPI(RedisModuleCtx *ctx, const char *apiname);

**Available since:** 5.0.4

Request an exported API pointer. The return value is just a void pointer
that the caller of this function will be required to cast to the right
function pointer, so this is a private contract between modules.

If the requested API is not available then NULL is returned. Because
modules can be loaded at different times with different order, this
function calls should be put inside some module generic API registering
step, that is called every time a module attempts to execute a
command that requires external APIs: if some API cannot be resolved, the
command should return an error.

Here is an example:

    int ... myCommandImplementation() {
       if (getExternalAPIs() == 0) {
            reply with an error here if we cannot have the APIs
       }
       // Use the API:
       myFunctionPointer(foo);
    }

And the function registerAPI() is:

    int getExternalAPIs(void) {
        static int api_loaded = 0;
        if (api_loaded != 0) return 1; // APIs already resolved.

        myFunctionPointer = RedisModule_GetOtherModuleAPI("...");
        if (myFunctionPointer == NULL) return 0;

        return 1;
    }

<span id="section-module-command-filter-api"></span>

## Module Command Filter API

<span id="RedisModule_RegisterCommandFilter"></span>

### `RedisModule_RegisterCommandFilter`

    RedisModuleCommandFilter *RedisModule_RegisterCommandFilter(RedisModuleCtx *ctx,
                                                                RedisModuleCommandFilterFunc callback,
                                                                int flags);

**Available since:** 5.0.5

Register a new command filter function.

Command filtering makes it possible for modules to extend Redis by plugging
into the execution flow of all commands.

A registered filter gets called before Redis executes *any* command.  This
includes both core Redis commands and commands registered by any module.  The
filter applies in all execution paths including:

1. Invocation by a client.
2. Invocation through [`RedisModule_Call()`](#RedisModule_Call) by any module.
3. Invocation through Lua `redis.call()`.
4. Replication of a command from a master.

The filter executes in a special filter context, which is different and more
limited than a `RedisModuleCtx`.  Because the filter affects any command, it
must be implemented in a very efficient way to reduce the performance impact
on Redis.  All Redis Module API calls that require a valid context (such as
[`RedisModule_Call()`](#RedisModule_Call), [`RedisModule_OpenKey()`](#RedisModule_OpenKey), etc.) are not supported in a
filter context.

The `RedisModuleCommandFilterCtx` can be used to inspect or modify the
executed command and its arguments.  As the filter executes before Redis
begins processing the command, any change will affect the way the command is
processed.  For example, a module can override Redis commands this way:

1. Register a `MODULE.SET` command which implements an extended version of
   the Redis `SET` command.
2. Register a command filter which detects invocation of `SET` on a specific
   pattern of keys.  Once detected, the filter will replace the first
   argument from `SET` to `MODULE.SET`.
3. When filter execution is complete, Redis considers the new command name
   and therefore executes the module's own command.

Note that in the above use case, if `MODULE.SET` itself uses
[`RedisModule_Call()`](#RedisModule_Call) the filter will be applied on that call as well.  If
that is not desired, the `REDISMODULE_CMDFILTER_NOSELF` flag can be set when
registering the filter.

The `REDISMODULE_CMDFILTER_NOSELF` flag prevents execution flows that
originate from the module's own `RM_Call()` from reaching the filter.  This
flag is effective for all execution flows, including nested ones, as long as
the execution begins from the module's command context or a thread-safe
context that is associated with a blocking command.

Detached thread-safe contexts are *not* associated with the module and cannot
be protected by this flag.

If multiple filters are registered (by the same or different modules), they
are executed in the order of registration.

<span id="RedisModule_UnregisterCommandFilter"></span>

### `RedisModule_UnregisterCommandFilter`

    int RedisModule_UnregisterCommandFilter(RedisModuleCtx *ctx,
                                            RedisModuleCommandFilter *filter);

**Available since:** 5.0.5

Unregister a command filter.

<span id="RedisModule_CommandFilterArgsCount"></span>

### `RedisModule_CommandFilterArgsCount`

    int RedisModule_CommandFilterArgsCount(RedisModuleCommandFilterCtx *fctx);

**Available since:** 5.0.5

Return the number of arguments a filtered command has.  The number of
arguments include the command itself.

<span id="RedisModule_CommandFilterArgGet"></span>

### `RedisModule_CommandFilterArgGet`

    RedisModuleString *RedisModule_CommandFilterArgGet(RedisModuleCommandFilterCtx *fctx,
                                                       int pos);

**Available since:** 5.0.5

Return the specified command argument.  The first argument (position 0) is
the command itself, and the rest are user-provided args.

<span id="RedisModule_CommandFilterArgInsert"></span>

### `RedisModule_CommandFilterArgInsert`

    int RedisModule_CommandFilterArgInsert(RedisModuleCommandFilterCtx *fctx,
                                           int pos,
                                           RedisModuleString *arg);

**Available since:** 5.0.5

Modify the filtered command by inserting a new argument at the specified
position.  The specified `RedisModuleString` argument may be used by Redis
after the filter context is destroyed, so it must not be auto-memory
allocated, freed or used elsewhere.

<span id="RedisModule_CommandFilterArgReplace"></span>

### `RedisModule_CommandFilterArgReplace`

    int RedisModule_CommandFilterArgReplace(RedisModuleCommandFilterCtx *fctx,
                                            int pos,
                                            RedisModuleString *arg);

**Available since:** 5.0.5

Modify the filtered command by replacing an existing argument with a new one.
The specified `RedisModuleString` argument may be used by Redis after the
filter context is destroyed, so it must not be auto-memory allocated, freed
or used elsewhere.

<span id="RedisModule_CommandFilterArgDelete"></span>

### `RedisModule_CommandFilterArgDelete`

    int RedisModule_CommandFilterArgDelete(RedisModuleCommandFilterCtx *fctx,
                                           int pos);

**Available since:** 5.0.5

Modify the filtered command by deleting an argument at the specified
position.

<span id="RedisModule_MallocSize"></span>

### `RedisModule_MallocSize`

    size_t RedisModule_MallocSize(void* ptr);

**Available since:** 6.0.0

For a given pointer allocated via [`RedisModule_Alloc()`](#RedisModule_Alloc) or
[`RedisModule_Realloc()`](#RedisModule_Realloc), return the amount of memory allocated for it.
Note that this may be different (larger) than the memory we allocated
with the allocation calls, since sometimes the underlying allocator
will allocate more memory.

<span id="RedisModule_MallocSizeString"></span>

### `RedisModule_MallocSizeString`

    size_t RedisModule_MallocSizeString(RedisModuleString* str);

**Available since:** 7.0.0

Same as [`RedisModule_MallocSize`](#RedisModule_MallocSize), except it works on `RedisModuleString` pointers.

<span id="RedisModule_MallocSizeDict"></span>

### `RedisModule_MallocSizeDict`

    size_t RedisModule_MallocSizeDict(RedisModuleDict* dict);

**Available since:** 7.0.0

Same as [`RedisModule_MallocSize`](#RedisModule_MallocSize), except it works on `RedisModuleDict` pointers.
Note that the returned value is only the overhead of the underlying structures,
it does not include the allocation size of the keys and values.

<span id="RedisModule_GetUsedMemoryRatio"></span>

### `RedisModule_GetUsedMemoryRatio`

    float RedisModule_GetUsedMemoryRatio();

**Available since:** 6.0.0

Return the a number between 0 to 1 indicating the amount of memory
currently used, relative to the Redis "maxmemory" configuration.

* 0 - No memory limit configured.
* Between 0 and 1 - The percentage of the memory used normalized in 0-1 range.
* Exactly 1 - Memory limit reached.
* Greater 1 - More memory used than the configured limit.

<span id="section-scanning-keyspace-and-hashes"></span>

## Scanning keyspace and hashes

<span id="RedisModule_ScanCursorCreate"></span>

### `RedisModule_ScanCursorCreate`

    RedisModuleScanCursor *RedisModule_ScanCursorCreate();

**Available since:** 6.0.0

Create a new cursor to be used with [`RedisModule_Scan`](#RedisModule_Scan)

<span id="RedisModule_ScanCursorRestart"></span>

### `RedisModule_ScanCursorRestart`

    void RedisModule_ScanCursorRestart(RedisModuleScanCursor *cursor);

**Available since:** 6.0.0

Restart an existing cursor. The keys will be rescanned.

<span id="RedisModule_ScanCursorDestroy"></span>

### `RedisModule_ScanCursorDestroy`

    void RedisModule_ScanCursorDestroy(RedisModuleScanCursor *cursor);

**Available since:** 6.0.0

Destroy the cursor struct.

<span id="RedisModule_Scan"></span>

### `RedisModule_Scan`

    int RedisModule_Scan(RedisModuleCtx *ctx,
                         RedisModuleScanCursor *cursor,
                         RedisModuleScanCB fn,
                         void *privdata);

**Available since:** 6.0.0

Scan API that allows a module to scan all the keys and value in
the selected db.

Callback for scan implementation.

    void scan_callback(RedisModuleCtx *ctx, RedisModuleString *keyname,
                       RedisModuleKey *key, void *privdata);

- `ctx`: the redis module context provided to for the scan.
- `keyname`: owned by the caller and need to be retained if used after this
  function.
- `key`: holds info on the key and value, it is provided as best effort, in
  some cases it might be NULL, in which case the user should (can) use
  [`RedisModule_OpenKey()`](#RedisModule_OpenKey) (and CloseKey too).
  when it is provided, it is owned by the caller and will be free when the
  callback returns.
- `privdata`: the user data provided to [`RedisModule_Scan()`](#RedisModule_Scan).

The way it should be used:

     RedisModuleCursor *c = RedisModule_ScanCursorCreate();
     while(RedisModule_Scan(ctx, c, callback, privateData));
     RedisModule_ScanCursorDestroy(c);

It is also possible to use this API from another thread while the lock
is acquired during the actual call to [`RedisModule_Scan`](#RedisModule_Scan):

     RedisModuleCursor *c = RedisModule_ScanCursorCreate();
     RedisModule_ThreadSafeContextLock(ctx);
     while(RedisModule_Scan(ctx, c, callback, privateData)){
         RedisModule_ThreadSafeContextUnlock(ctx);
         // do some background job
         RedisModule_ThreadSafeContextLock(ctx);
     }
     RedisModule_ScanCursorDestroy(c);

The function will return 1 if there are more elements to scan and
0 otherwise, possibly setting errno if the call failed.

It is also possible to restart an existing cursor using [`RedisModule_ScanCursorRestart`](#RedisModule_ScanCursorRestart).

IMPORTANT: This API is very similar to the Redis SCAN command from the
point of view of the guarantees it provides. This means that the API
may report duplicated keys, but guarantees to report at least one time
every key that was there from the start to the end of the scanning process.

NOTE: If you do database changes within the callback, you should be aware
that the internal state of the database may change. For instance it is safe
to delete or modify the current key, but may not be safe to delete any
other key.
Moreover playing with the Redis keyspace while iterating may have the
effect of returning more duplicates. A safe pattern is to store the keys
names you want to modify elsewhere, and perform the actions on the keys
later when the iteration is complete. However this can cost a lot of
memory, so it may make sense to just operate on the current key when
possible during the iteration, given that this is safe.

<span id="RedisModule_ScanKey"></span>

### `RedisModule_ScanKey`

    int RedisModule_ScanKey(RedisModuleKey *key,
                            RedisModuleScanCursor *cursor,
                            RedisModuleScanKeyCB fn,
                            void *privdata);

**Available since:** 6.0.0

Scan api that allows a module to scan the elements in a hash, set or sorted set key

Callback for scan implementation.

    void scan_callback(RedisModuleKey *key, RedisModuleString* field, RedisModuleString* value, void *privdata);

- key - the redis key context provided to for the scan.
- field - field name, owned by the caller and need to be retained if used
  after this function.
- value - value string or NULL for set type, owned by the caller and need to
  be retained if used after this function.
- privdata - the user data provided to [`RedisModule_ScanKey`](#RedisModule_ScanKey).

The way it should be used:

     RedisModuleCursor *c = RedisModule_ScanCursorCreate();
     RedisModuleKey *key = RedisModule_OpenKey(...)
     while(RedisModule_ScanKey(key, c, callback, privateData));
     RedisModule_CloseKey(key);
     RedisModule_ScanCursorDestroy(c);

It is also possible to use this API from another thread while the lock is acquired during
the actual call to [`RedisModule_ScanKey`](#RedisModule_ScanKey), and re-opening the key each time:

     RedisModuleCursor *c = RedisModule_ScanCursorCreate();
     RedisModule_ThreadSafeContextLock(ctx);
     RedisModuleKey *key = RedisModule_OpenKey(...)
     while(RedisModule_ScanKey(ctx, c, callback, privateData)){
         RedisModule_CloseKey(key);
         RedisModule_ThreadSafeContextUnlock(ctx);
         // do some background job
         RedisModule_ThreadSafeContextLock(ctx);
         RedisModuleKey *key = RedisModule_OpenKey(...)
     }
     RedisModule_CloseKey(key);
     RedisModule_ScanCursorDestroy(c);

The function will return 1 if there are more elements to scan and 0 otherwise,
possibly setting errno if the call failed.
It is also possible to restart an existing cursor using [`RedisModule_ScanCursorRestart`](#RedisModule_ScanCursorRestart).

NOTE: Certain operations are unsafe while iterating the object. For instance
while the API guarantees to return at least one time all the elements that
are present in the data structure consistently from the start to the end
of the iteration (see HSCAN and similar commands documentation), the more
you play with the elements, the more duplicates you may get. In general
deleting the current element of the data structure is safe, while removing
the key you are iterating is not safe.

<span id="section-module-fork-api"></span>

## Module fork API

<span id="RedisModule_Fork"></span>

### `RedisModule_Fork`

    int RedisModule_Fork(RedisModuleForkDoneHandler cb, void *user_data);

**Available since:** 6.0.0

Create a background child process with the current frozen snapshot of the
main process where you can do some processing in the background without
affecting / freezing the traffic and no need for threads and GIL locking.
Note that Redis allows for only one concurrent fork.
When the child wants to exit, it should call [`RedisModule_ExitFromChild`](#RedisModule_ExitFromChild).
If the parent wants to kill the child it should call [`RedisModule_KillForkChild`](#RedisModule_KillForkChild)
The done handler callback will be executed on the parent process when the
child existed (but not when killed)
Return: -1 on failure, on success the parent process will get a positive PID
of the child, and the child process will get 0.

<span id="RedisModule_SendChildHeartbeat"></span>

### `RedisModule_SendChildHeartbeat`

    void RedisModule_SendChildHeartbeat(double progress);

**Available since:** 6.2.0

The module is advised to call this function from the fork child once in a while,
so that it can report progress and COW memory to the parent which will be
reported in INFO.
The `progress` argument should between 0 and 1, or -1 when not available.

<span id="RedisModule_ExitFromChild"></span>

### `RedisModule_ExitFromChild`

    int RedisModule_ExitFromChild(int retcode);

**Available since:** 6.0.0

Call from the child process when you want to terminate it.
retcode will be provided to the done handler executed on the parent process.

<span id="RedisModule_KillForkChild"></span>

### `RedisModule_KillForkChild`

    int RedisModule_KillForkChild(int child_pid);

**Available since:** 6.0.0

Can be used to kill the forked child process from the parent process.
`child_pid` would be the return value of [`RedisModule_Fork`](#RedisModule_Fork).

<span id="section-server-hooks-implementation"></span>

## Server hooks implementation

<span id="RedisModule_SubscribeToServerEvent"></span>

### `RedisModule_SubscribeToServerEvent`

    int RedisModule_SubscribeToServerEvent(RedisModuleCtx *ctx,
                                           RedisModuleEvent event,
                                           RedisModuleEventCallback callback);

**Available since:** 6.0.0

Register to be notified, via a callback, when the specified server event
happens. The callback is called with the event as argument, and an additional
argument which is a void pointer and should be cased to a specific type
that is event-specific (but many events will just use NULL since they do not
have additional information to pass to the callback).

If the callback is NULL and there was a previous subscription, the module
will be unsubscribed. If there was a previous subscription and the callback
is not null, the old callback will be replaced with the new one.

The callback must be of this type:

    int (*RedisModuleEventCallback)(RedisModuleCtx *ctx,
                                    RedisModuleEvent eid,
                                    uint64_t subevent,
                                    void *data);

The 'ctx' is a normal Redis module context that the callback can use in
order to call other modules APIs. The 'eid' is the event itself, this
is only useful in the case the module subscribed to multiple events: using
the 'id' field of this structure it is possible to check if the event
is one of the events we registered with this callback. The 'subevent' field
depends on the event that fired.

Finally the 'data' pointer may be populated, only for certain events, with
more relevant data.

Here is a list of events you can use as 'eid' and related sub events:

* `RedisModuleEvent_ReplicationRoleChanged`:

    This event is called when the instance switches from master
    to replica or the other way around, however the event is
    also called when the replica remains a replica but starts to
    replicate with a different master.

    The following sub events are available:

    * `REDISMODULE_SUBEVENT_REPLROLECHANGED_NOW_MASTER`
    * `REDISMODULE_SUBEVENT_REPLROLECHANGED_NOW_REPLICA`

    The 'data' field can be casted by the callback to a
    `RedisModuleReplicationInfo` structure with the following fields:

        int master; // true if master, false if replica
        char *masterhost; // master instance hostname for NOW_REPLICA
        int masterport; // master instance port for NOW_REPLICA
        char *replid1; // Main replication ID
        char *replid2; // Secondary replication ID
        uint64_t repl1_offset; // Main replication offset
        uint64_t repl2_offset; // Offset of replid2 validity

* `RedisModuleEvent_Persistence`

    This event is called when RDB saving or AOF rewriting starts
    and ends. The following sub events are available:

    * `REDISMODULE_SUBEVENT_PERSISTENCE_RDB_START`
    * `REDISMODULE_SUBEVENT_PERSISTENCE_AOF_START`
    * `REDISMODULE_SUBEVENT_PERSISTENCE_SYNC_RDB_START`
    * `REDISMODULE_SUBEVENT_PERSISTENCE_SYNC_AOF_START`
    * `REDISMODULE_SUBEVENT_PERSISTENCE_ENDED`
    * `REDISMODULE_SUBEVENT_PERSISTENCE_FAILED`

    The above events are triggered not just when the user calls the
    relevant commands like BGSAVE, but also when a saving operation
    or AOF rewriting occurs because of internal server triggers.
    The SYNC_RDB_START sub events are happening in the foreground due to
    SAVE command, FLUSHALL, or server shutdown, and the other RDB and
    AOF sub events are executed in a background fork child, so any
    action the module takes can only affect the generated AOF or RDB,
    but will not be reflected in the parent process and affect connected
    clients and commands. Also note that the AOF_START sub event may end
    up saving RDB content in case of an AOF with rdb-preamble.

* `RedisModuleEvent_FlushDB`

    The FLUSHALL, FLUSHDB or an internal flush (for instance
    because of replication, after the replica synchronization)
    happened. The following sub events are available:

    * `REDISMODULE_SUBEVENT_FLUSHDB_START`
    * `REDISMODULE_SUBEVENT_FLUSHDB_END`

    The data pointer can be casted to a RedisModuleFlushInfo
    structure with the following fields:

        int32_t async;  // True if the flush is done in a thread.
                        // See for instance FLUSHALL ASYNC.
                        // In this case the END callback is invoked
                        // immediately after the database is put
                        // in the free list of the thread.
        int32_t dbnum;  // Flushed database number, -1 for all the DBs
                        // in the case of the FLUSHALL operation.

    The start event is called *before* the operation is initiated, thus
    allowing the callback to call DBSIZE or other operation on the
    yet-to-free keyspace.

* `RedisModuleEvent_Loading`

    Called on loading operations: at startup when the server is
    started, but also after a first synchronization when the
    replica is loading the RDB file from the master.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_LOADING_RDB_START`
    * `REDISMODULE_SUBEVENT_LOADING_AOF_START`
    * `REDISMODULE_SUBEVENT_LOADING_REPL_START`
    * `REDISMODULE_SUBEVENT_LOADING_ENDED`
    * `REDISMODULE_SUBEVENT_LOADING_FAILED`

    Note that AOF loading may start with an RDB data in case of
    rdb-preamble, in which case you'll only receive an AOF_START event.

* `RedisModuleEvent_ClientChange`

    Called when a client connects or disconnects.
    The data pointer can be casted to a RedisModuleClientInfo
    structure, documented in RedisModule_GetClientInfoById().
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_CLIENT_CHANGE_CONNECTED`
    * `REDISMODULE_SUBEVENT_CLIENT_CHANGE_DISCONNECTED`

* `RedisModuleEvent_Shutdown`

    The server is shutting down. No subevents are available.

* `RedisModuleEvent_ReplicaChange`

    This event is called when the instance (that can be both a
    master or a replica) get a new online replica, or lose a
    replica since it gets disconnected.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_REPLICA_CHANGE_ONLINE`
    * `REDISMODULE_SUBEVENT_REPLICA_CHANGE_OFFLINE`

    No additional information is available so far: future versions
    of Redis will have an API in order to enumerate the replicas
    connected and their state.

* `RedisModuleEvent_CronLoop`

    This event is called every time Redis calls the serverCron()
    function in order to do certain bookkeeping. Modules that are
    required to do operations from time to time may use this callback.
    Normally Redis calls this function 10 times per second, but
    this changes depending on the "hz" configuration.
    No sub events are available.

    The data pointer can be casted to a RedisModuleCronLoop
    structure with the following fields:

        int32_t hz;  // Approximate number of events per second.

* `RedisModuleEvent_MasterLinkChange`

    This is called for replicas in order to notify when the
    replication link becomes functional (up) with our master,
    or when it goes down. Note that the link is not considered
    up when we just connected to the master, but only if the
    replication is happening correctly.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_MASTER_LINK_UP`
    * `REDISMODULE_SUBEVENT_MASTER_LINK_DOWN`

* `RedisModuleEvent_ModuleChange`

    This event is called when a new module is loaded or one is unloaded.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_MODULE_LOADED`
    * `REDISMODULE_SUBEVENT_MODULE_UNLOADED`

    The data pointer can be casted to a RedisModuleModuleChange
    structure with the following fields:

        const char* module_name;  // Name of module loaded or unloaded.
        int32_t module_version;  // Module version.

* `RedisModuleEvent_LoadingProgress`

    This event is called repeatedly called while an RDB or AOF file
    is being loaded.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_LOADING_PROGRESS_RDB`
    * `REDISMODULE_SUBEVENT_LOADING_PROGRESS_AOF`

    The data pointer can be casted to a RedisModuleLoadingProgress
    structure with the following fields:

        int32_t hz;  // Approximate number of events per second.
        int32_t progress;  // Approximate progress between 0 and 1024,
                           // or -1 if unknown.

* `RedisModuleEvent_SwapDB`

    This event is called when a SWAPDB command has been successfully
    Executed.
    For this event call currently there is no subevents available.

    The data pointer can be casted to a RedisModuleSwapDbInfo
    structure with the following fields:

        int32_t dbnum_first;    // Swap Db first dbnum
        int32_t dbnum_second;   // Swap Db second dbnum

* `RedisModuleEvent_ReplBackup`

    WARNING: Replication Backup events are deprecated since Redis 7.0 and are never fired.
    See RedisModuleEvent_ReplAsyncLoad for understanding how Async Replication Loading events
    are now triggered when repl-diskless-load is set to swapdb.

    Called when repl-diskless-load config is set to swapdb,
    And redis needs to backup the current database for the
    possibility to be restored later. A module with global data and
    maybe with aux_load and aux_save callbacks may need to use this
    notification to backup / restore / discard its globals.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_REPL_BACKUP_CREATE`
    * `REDISMODULE_SUBEVENT_REPL_BACKUP_RESTORE`
    * `REDISMODULE_SUBEVENT_REPL_BACKUP_DISCARD`

* `RedisModuleEvent_ReplAsyncLoad`

    Called when repl-diskless-load config is set to swapdb and a replication with a master of same
    data set history (matching replication ID) occurs.
    In which case redis serves current data set while loading new database in memory from socket.
    Modules must have declared they support this mechanism in order to activate it, through
    REDISMODULE_OPTIONS_HANDLE_REPL_ASYNC_LOAD flag.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_REPL_ASYNC_LOAD_STARTED`
    * `REDISMODULE_SUBEVENT_REPL_ASYNC_LOAD_ABORTED`
    * `REDISMODULE_SUBEVENT_REPL_ASYNC_LOAD_COMPLETED`

* `RedisModuleEvent_ForkChild`

    Called when a fork child (AOFRW, RDBSAVE, module fork...) is born/dies
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_FORK_CHILD_BORN`
    * `REDISMODULE_SUBEVENT_FORK_CHILD_DIED`

* `RedisModuleEvent_EventLoop`

    Called on each event loop iteration, once just before the event loop goes
    to sleep or just after it wakes up.
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_EVENTLOOP_BEFORE_SLEEP`
    * `REDISMODULE_SUBEVENT_EVENTLOOP_AFTER_SLEEP`

* `RedisModule_Event_Config`

    Called when a configuration event happens
    The following sub events are available:

    * `REDISMODULE_SUBEVENT_CONFIG_CHANGE`

    The data pointer can be casted to a RedisModuleConfigChange
    structure with the following fields:

        const char **config_names; // An array of C string pointers containing the
                                   // name of each modified configuration item 
        uint32_t num_changes;      // The number of elements in the config_names array

The function returns `REDISMODULE_OK` if the module was successfully subscribed
for the specified event. If the API is called from a wrong context or unsupported event
is given then `REDISMODULE_ERR` is returned.

<span id="RedisModule_IsSubEventSupported"></span>

### `RedisModule_IsSubEventSupported`

    int RedisModule_IsSubEventSupported(RedisModuleEvent event, int64_t subevent);

**Available since:** 6.0.9


For a given server event and subevent, return zero if the
subevent is not supported and non-zero otherwise.

<span id="section-module-configurations-api"></span>

## Module Configurations API

<span id="RedisModule_RegisterStringConfig"></span>

### `RedisModule_RegisterStringConfig`

    int RedisModule_RegisterStringConfig(RedisModuleCtx *ctx,
                                         const char *name,
                                         const char *default_val,
                                         unsigned int flags,
                                         RedisModuleConfigGetStringFunc getfn,
                                         RedisModuleConfigSetStringFunc setfn,
                                         RedisModuleConfigApplyFunc applyfn,
                                         void *privdata);

**Available since:** 7.0.0

Create a string config that Redis users can interact with via the Redis config file,
`CONFIG SET`, `CONFIG GET`, and `CONFIG REWRITE` commands.

The actual config value is owned by the module, and the `getfn`, `setfn` and optional
`applyfn` callbacks that are provided to Redis in order to access or manipulate the
value. The `getfn` callback retrieves the value from the module, while the `setfn`
callback provides a value to be stored into the module config.
The optional `applyfn` callback is called after a `CONFIG SET` command modified one or
more configs using the `setfn` callback and can be used to atomically apply a config
after several configs were changed together.
If there are multiple configs with `applyfn` callbacks set by a single `CONFIG SET`
command, they will be deduplicated if their `applyfn` function and `privdata` pointers
are identical, and the callback will only be run once.
Both the `setfn` and `applyfn` can return an error if the provided value is invalid or
cannot be used.
The config also declares a type for the value that is validated by Redis and
provided to the module. The config system provides the following types:

* Redis String: Binary safe string data.
* Enum: One of a finite number of string tokens, provided during registration.
* Numeric: 64 bit signed integer, which also supports min and max values.
* Bool: Yes or no value.

The `setfn` callback is expected to return `REDISMODULE_OK` when the value is successfully
applied. It can also return `REDISMODULE_ERR` if the value can't be applied, and the
*err pointer can be set with a `RedisModuleString` error message to provide to the client.
This `RedisModuleString` will be freed by redis after returning from the set callback.

All configs are registered with a name, a type, a default value, private data that is made
available in the callbacks, as well as several flags that modify the behavior of the config.
The name must only contain alphanumeric characters or dashes. The supported flags are:

* `REDISMODULE_CONFIG_DEFAULT`: The default flags for a config. This creates a config that can be modified after startup.
* `REDISMODULE_CONFIG_IMMUTABLE`: This config can only be provided loading time.
* `REDISMODULE_CONFIG_SENSITIVE`: The value stored in this config is redacted from all logging.
* `REDISMODULE_CONFIG_HIDDEN`: The name is hidden from `CONFIG GET` with pattern matching.
* `REDISMODULE_CONFIG_PROTECTED`: This config will be only be modifiable based off the value of enable-protected-configs.
* `REDISMODULE_CONFIG_DENY_LOADING`: This config is not modifiable while the server is loading data.
* `REDISMODULE_CONFIG_MEMORY`: For numeric configs, this config will convert data unit notations into their byte equivalent.
* `REDISMODULE_CONFIG_BITFLAGS`: For enum configs, this config will allow multiple entries to be combined as bit flags.

Default values are used on startup to set the value if it is not provided via the config file
or command line. Default values are also used to compare to on a config rewrite.

Notes:

 1. On string config sets that the string passed to the set callback will be freed after execution and the module must retain it.
 2. On string config gets the string will not be consumed and will be valid after execution.

Example implementation:

    RedisModuleString *strval;
    int adjustable = 1;
    RedisModuleString *getStringConfigCommand(const char *name, void *privdata) {
        return strval;
    }

    int setStringConfigCommand(const char *name, RedisModuleString *new, void *privdata, RedisModuleString **err) {
       if (adjustable) {
           RedisModule_Free(strval);
           RedisModule_RetainString(NULL, new);
           strval = new;
           return REDISMODULE_OK;
       }
       *err = RedisModule_CreateString(NULL, "Not adjustable.", 15);
       return REDISMODULE_ERR;
    }
    ...
    RedisModule_RegisterStringConfig(ctx, "string", NULL, REDISMODULE_CONFIG_DEFAULT, getStringConfigCommand, setStringConfigCommand, NULL, NULL);

If the registration fails, `REDISMODULE_ERR` is returned and one of the following
errno is set:
* EINVAL: The provided flags are invalid for the registration or the name of the config contains invalid characters.
* EALREADY: The provided configuration name is already used.

<span id="RedisModule_RegisterBoolConfig"></span>

### `RedisModule_RegisterBoolConfig`

    int RedisModule_RegisterBoolConfig(RedisModuleCtx *ctx,
                                       const char *name,
                                       int default_val,
                                       unsigned int flags,
                                       RedisModuleConfigGetBoolFunc getfn,
                                       RedisModuleConfigSetBoolFunc setfn,
                                       RedisModuleConfigApplyFunc applyfn,
                                       void *privdata);

**Available since:** 7.0.0

Create a bool config that server clients can interact with via the 
`CONFIG SET`, `CONFIG GET`, and `CONFIG REWRITE` commands. See 
[`RedisModule_RegisterStringConfig`](#RedisModule_RegisterStringConfig) for detailed information about configs.

<span id="RedisModule_RegisterEnumConfig"></span>

### `RedisModule_RegisterEnumConfig`

    int RedisModule_RegisterEnumConfig(RedisModuleCtx *ctx,
                                       const char *name,
                                       int default_val,
                                       unsigned int flags,
                                       const char **enum_values,
                                       const int *int_values,
                                       int num_enum_vals,
                                       RedisModuleConfigGetEnumFunc getfn,
                                       RedisModuleConfigSetEnumFunc setfn,
                                       RedisModuleConfigApplyFunc applyfn,
                                       void *privdata);

**Available since:** 7.0.0


Create an enum config that server clients can interact with via the 
`CONFIG SET`, `CONFIG GET`, and `CONFIG REWRITE` commands. 
Enum configs are a set of string tokens to corresponding integer values, where 
the string value is exposed to Redis clients but the value passed Redis and the
module is the integer value. These values are defined in `enum_values`, an array
of null-terminated c strings, and `int_vals`, an array of enum values who has an
index partner in `enum_values`.
Example Implementation:
     const char *enum_vals[3] = {"first", "second", "third"};
     const int int_vals[3] = {0, 2, 4};
     int enum_val = 0;

     int getEnumConfigCommand(const char *name, void *privdata) {
         return enum_val;
     }
      
     int setEnumConfigCommand(const char *name, int val, void *privdata, const char **err) {
         enum_val = val;
         return REDISMODULE_OK;
     }
     ...
     RedisModule_RegisterEnumConfig(ctx, "enum", 0, REDISMODULE_CONFIG_DEFAULT, enum_vals, int_vals, 3, getEnumConfigCommand, setEnumConfigCommand, NULL, NULL);

See [`RedisModule_RegisterStringConfig`](#RedisModule_RegisterStringConfig) for detailed general information about configs.

<span id="RedisModule_RegisterNumericConfig"></span>

### `RedisModule_RegisterNumericConfig`

    int RedisModule_RegisterNumericConfig(RedisModuleCtx *ctx,
                                          const char *name,
                                          long long default_val,
                                          unsigned int flags,
                                          long long min,
                                          long long max,
                                          RedisModuleConfigGetNumericFunc getfn,
                                          RedisModuleConfigSetNumericFunc setfn,
                                          RedisModuleConfigApplyFunc applyfn,
                                          void *privdata);

**Available since:** 7.0.0


Create an integer config that server clients can interact with via the 
`CONFIG SET`, `CONFIG GET`, and `CONFIG REWRITE` commands. See 
[`RedisModule_RegisterStringConfig`](#RedisModule_RegisterStringConfig) for detailed information about configs.

<span id="RedisModule_LoadConfigs"></span>

### `RedisModule_LoadConfigs`

    int RedisModule_LoadConfigs(RedisModuleCtx *ctx);

**Available since:** 7.0.0

Applies all pending configurations on the module load. This should be called
after all of the configurations have been registered for the module inside of `RedisModule_OnLoad`.
This API needs to be called when configurations are provided in either `MODULE LOADEX`
or provided as startup arguments.

<span id="section-key-eviction-api"></span>

## Key eviction API

<span id="RedisModule_SetLRU"></span>

### `RedisModule_SetLRU`

    int RedisModule_SetLRU(RedisModuleKey *key, mstime_t lru_idle);

**Available since:** 6.0.0

Set the key last access time for LRU based eviction. not relevant if the
servers's maxmemory policy is LFU based. Value is idle time in milliseconds.
returns `REDISMODULE_OK` if the LRU was updated, `REDISMODULE_ERR` otherwise.

<span id="RedisModule_GetLRU"></span>

### `RedisModule_GetLRU`

    int RedisModule_GetLRU(RedisModuleKey *key, mstime_t *lru_idle);

**Available since:** 6.0.0

Gets the key last access time.
Value is idletime in milliseconds or -1 if the server's eviction policy is
LFU based.
returns `REDISMODULE_OK` if when key is valid.

<span id="RedisModule_SetLFU"></span>

### `RedisModule_SetLFU`

    int RedisModule_SetLFU(RedisModuleKey *key, long long lfu_freq);

**Available since:** 6.0.0

Set the key access frequency. only relevant if the server's maxmemory policy
is LFU based.
The frequency is a logarithmic counter that provides an indication of
the access frequencyonly (must be <= 255).
returns `REDISMODULE_OK` if the LFU was updated, `REDISMODULE_ERR` otherwise.

<span id="RedisModule_GetLFU"></span>

### `RedisModule_GetLFU`

    int RedisModule_GetLFU(RedisModuleKey *key, long long *lfu_freq);

**Available since:** 6.0.0

Gets the key access frequency or -1 if the server's eviction policy is not
LFU based.
returns `REDISMODULE_OK` if when key is valid.

<span id="section-miscellaneous-apis"></span>

## Miscellaneous APIs

<span id="RedisModule_GetContextFlagsAll"></span>

### `RedisModule_GetContextFlagsAll`

    int RedisModule_GetContextFlagsAll();

**Available since:** 6.0.9


Returns the full ContextFlags mask, using the return value
the module can check if a certain set of flags are supported
by the redis server version in use.
Example:

       int supportedFlags = RM_GetContextFlagsAll();
       if (supportedFlags & REDISMODULE_CTX_FLAGS_MULTI) {
             // REDISMODULE_CTX_FLAGS_MULTI is supported
       } else{
             // REDISMODULE_CTX_FLAGS_MULTI is not supported
       }

<span id="RedisModule_GetKeyspaceNotificationFlagsAll"></span>

### `RedisModule_GetKeyspaceNotificationFlagsAll`

    int RedisModule_GetKeyspaceNotificationFlagsAll();

**Available since:** 6.0.9


Returns the full KeyspaceNotification mask, using the return value
the module can check if a certain set of flags are supported
by the redis server version in use.
Example:

       int supportedFlags = RM_GetKeyspaceNotificationFlagsAll();
       if (supportedFlags & REDISMODULE_NOTIFY_LOADED) {
             // REDISMODULE_NOTIFY_LOADED is supported
       } else{
             // REDISMODULE_NOTIFY_LOADED is not supported
       }

<span id="RedisModule_GetServerVersion"></span>

### `RedisModule_GetServerVersion`

    int RedisModule_GetServerVersion();

**Available since:** 6.0.9


Return the redis version in format of 0x00MMmmpp.
Example for 6.0.7 the return value will be 0x00060007.

<span id="RedisModule_GetTypeMethodVersion"></span>

### `RedisModule_GetTypeMethodVersion`

    int RedisModule_GetTypeMethodVersion();

**Available since:** 6.2.0


Return the current redis-server runtime value of `REDISMODULE_TYPE_METHOD_VERSION`.
You can use that when calling [`RedisModule_CreateDataType`](#RedisModule_CreateDataType) to know which fields of
`RedisModuleTypeMethods` are gonna be supported and which will be ignored.

<span id="RedisModule_ModuleTypeReplaceValue"></span>

### `RedisModule_ModuleTypeReplaceValue`

    int RedisModule_ModuleTypeReplaceValue(RedisModuleKey *key,
                                           moduleType *mt,
                                           void *new_value,
                                           void **old_value);

**Available since:** 6.0.0

Replace the value assigned to a module type.

The key must be open for writing, have an existing value, and have a moduleType
that matches the one specified by the caller.

Unlike [`RedisModule_ModuleTypeSetValue()`](#RedisModule_ModuleTypeSetValue) which will free the old value, this function
simply swaps the old value with the new value.

The function returns `REDISMODULE_OK` on success, `REDISMODULE_ERR` on errors
such as:

1. Key is not opened for writing.
2. Key is not a module data type key.
3. Key is a module datatype other than 'mt'.

If `old_value` is non-NULL, the old value is returned by reference.

<span id="RedisModule_GetCommandKeysWithFlags"></span>

### `RedisModule_GetCommandKeysWithFlags`

    int *RedisModule_GetCommandKeysWithFlags(RedisModuleCtx *ctx,
                                             RedisModuleString **argv,
                                             int argc,
                                             int *num_keys,
                                             int **out_flags);

**Available since:** 7.0.0

For a specified command, parse its arguments and return an array that
contains the indexes of all key name arguments. This function is
essentially a more efficient way to do `COMMAND GETKEYS`.

The `out_flags` argument is optional, and can be set to NULL.
When provided it is filled with `REDISMODULE_CMD_KEY_` flags in matching
indexes with the key indexes of the returned array.

A NULL return value indicates the specified command has no keys, or
an error condition. Error conditions are indicated by setting errno
as follows:

* ENOENT: Specified command does not exist.
* EINVAL: Invalid command arity specified.

NOTE: The returned array is not a Redis Module object so it does not
get automatically freed even when auto-memory is used. The caller
must explicitly call [`RedisModule_Free()`](#RedisModule_Free) to free it, same as the `out_flags` pointer if
used.

<span id="RedisModule_GetCommandKeys"></span>

### `RedisModule_GetCommandKeys`

    int *RedisModule_GetCommandKeys(RedisModuleCtx *ctx,
                                    RedisModuleString **argv,
                                    int argc,
                                    int *num_keys);

**Available since:** 6.0.9

Identinal to [`RedisModule_GetCommandKeysWithFlags`](#RedisModule_GetCommandKeysWithFlags) when flags are not needed.

<span id="RedisModule_GetCurrentCommandName"></span>

### `RedisModule_GetCurrentCommandName`

    const char *RedisModule_GetCurrentCommandName(RedisModuleCtx *ctx);

**Available since:** 6.2.5

Return the name of the command currently running

<span id="section-defrag-api"></span>

## Defrag API

<span id="RedisModule_RegisterDefragFunc"></span>

### `RedisModule_RegisterDefragFunc`

    int RedisModule_RegisterDefragFunc(RedisModuleCtx *ctx,
                                       RedisModuleDefragFunc cb);

**Available since:** 6.2.0

Register a defrag callback for global data, i.e. anything that the module
may allocate that is not tied to a specific data type.

<span id="RedisModule_DefragShouldStop"></span>

### `RedisModule_DefragShouldStop`

    int RedisModule_DefragShouldStop(RedisModuleDefragCtx *ctx);

**Available since:** 6.2.0

When the data type defrag callback iterates complex structures, this
function should be called periodically. A zero (false) return
indicates the callback may continue its work. A non-zero value (true)
indicates it should stop.

When stopped, the callback may use [`RedisModule_DefragCursorSet()`](#RedisModule_DefragCursorSet) to store its
position so it can later use [`RedisModule_DefragCursorGet()`](#RedisModule_DefragCursorGet) to resume defragging.

When stopped and more work is left to be done, the callback should
return 1. Otherwise, it should return 0.

NOTE: Modules should consider the frequency in which this function is called,
so it generally makes sense to do small batches of work in between calls.

<span id="RedisModule_DefragCursorSet"></span>

### `RedisModule_DefragCursorSet`

    int RedisModule_DefragCursorSet(RedisModuleDefragCtx *ctx,
                                    unsigned long cursor);

**Available since:** 6.2.0

Store an arbitrary cursor value for future re-use.

This should only be called if [`RedisModule_DefragShouldStop()`](#RedisModule_DefragShouldStop) has returned a non-zero
value and the defrag callback is about to exit without fully iterating its
data type.

This behavior is reserved to cases where late defrag is performed. Late
defrag is selected for keys that implement the `free_effort` callback and
return a `free_effort` value that is larger than the defrag
'active-defrag-max-scan-fields' configuration directive.

Smaller keys, keys that do not implement `free_effort` or the global
defrag callback are not called in late-defrag mode. In those cases, a
call to this function will return `REDISMODULE_ERR`.

The cursor may be used by the module to represent some progress into the
module's data type. Modules may also store additional cursor-related
information locally and use the cursor as a flag that indicates when
traversal of a new key begins. This is possible because the API makes
a guarantee that concurrent defragmentation of multiple keys will
not be performed.

<span id="RedisModule_DefragCursorGet"></span>

### `RedisModule_DefragCursorGet`

    int RedisModule_DefragCursorGet(RedisModuleDefragCtx *ctx,
                                    unsigned long *cursor);

**Available since:** 6.2.0

Fetch a cursor value that has been previously stored using [`RedisModule_DefragCursorSet()`](#RedisModule_DefragCursorSet).

If not called for a late defrag operation, `REDISMODULE_ERR` will be returned and
the cursor should be ignored. See [`RedisModule_DefragCursorSet()`](#RedisModule_DefragCursorSet) for more details on
defrag cursors.

<span id="RedisModule_DefragAlloc"></span>

### `RedisModule_DefragAlloc`

    void *RedisModule_DefragAlloc(RedisModuleDefragCtx *ctx, void *ptr);

**Available since:** 6.2.0

Defrag a memory allocation previously allocated by [`RedisModule_Alloc`](#RedisModule_Alloc), [`RedisModule_Calloc`](#RedisModule_Calloc), etc.
The defragmentation process involves allocating a new memory block and copying
the contents to it, like `realloc()`.

If defragmentation was not necessary, NULL is returned and the operation has
no other effect.

If a non-NULL value is returned, the caller should use the new pointer instead
of the old one and update any reference to the old pointer, which must not
be used again.

<span id="RedisModule_DefragRedisModuleString"></span>

### `RedisModule_DefragRedisModuleString`

    RedisModuleString *RedisModule_DefragRedisModuleString(RedisModuleDefragCtx *ctx,
                                                           RedisModuleString *str);

**Available since:** 6.2.0

Defrag a `RedisModuleString` previously allocated by [`RedisModule_Alloc`](#RedisModule_Alloc), [`RedisModule_Calloc`](#RedisModule_Calloc), etc.
See [`RedisModule_DefragAlloc()`](#RedisModule_DefragAlloc) for more information on how the defragmentation process
works.

NOTE: It is only possible to defrag strings that have a single reference.
Typically this means strings retained with [`RedisModule_RetainString`](#RedisModule_RetainString) or [`RedisModule_HoldString`](#RedisModule_HoldString)
may not be defragmentable. One exception is command argvs which, if retained
by the module, will end up with a single reference (because the reference
on the Redis side is dropped as soon as the command callback returns).

<span id="RedisModule_GetKeyNameFromDefragCtx"></span>

### `RedisModule_GetKeyNameFromDefragCtx`

    const RedisModuleString *RedisModule_GetKeyNameFromDefragCtx(RedisModuleDefragCtx *ctx);

**Available since:** 7.0.0

Returns the name of the key currently being processed.
There is no guarantee that the key name is always available, so this may return NULL.

<span id="RedisModule_GetDbIdFromDefragCtx"></span>

### `RedisModule_GetDbIdFromDefragCtx`

    int RedisModule_GetDbIdFromDefragCtx(RedisModuleDefragCtx *ctx);

**Available since:** 7.0.0

Returns the database id of the key currently being processed.
There is no guarantee that this info is always available, so this may return -1.

<span id="section-function-index"></span>

## Function index

* [`RedisModule_ACLAddLogEntry`](#RedisModule_ACLAddLogEntry)
* [`RedisModule_ACLCheckChannelPermissions`](#RedisModule_ACLCheckChannelPermissions)
* [`RedisModule_ACLCheckCommandPermissions`](#RedisModule_ACLCheckCommandPermissions)
* [`RedisModule_ACLCheckKeyPermissions`](#RedisModule_ACLCheckKeyPermissions)
* [`RedisModule_AbortBlock`](#RedisModule_AbortBlock)
* [`RedisModule_Alloc`](#RedisModule_Alloc)
* [`RedisModule_AuthenticateClientWithACLUser`](#RedisModule_AuthenticateClientWithACLUser)
* [`RedisModule_AuthenticateClientWithUser`](#RedisModule_AuthenticateClientWithUser)
* [`RedisModule_AutoMemory`](#RedisModule_AutoMemory)
* [`RedisModule_AvoidReplicaTraffic`](#RedisModule_AvoidReplicaTraffic)
* [`RedisModule_BlockClient`](#RedisModule_BlockClient)
* [`RedisModule_BlockClientOnKeys`](#RedisModule_BlockClientOnKeys)
* [`RedisModule_BlockedClientDisconnected`](#RedisModule_BlockedClientDisconnected)
* [`RedisModule_BlockedClientMeasureTimeEnd`](#RedisModule_BlockedClientMeasureTimeEnd)
* [`RedisModule_BlockedClientMeasureTimeStart`](#RedisModule_BlockedClientMeasureTimeStart)
* [`RedisModule_Call`](#RedisModule_Call)
* [`RedisModule_CallReplyArrayElement`](#RedisModule_CallReplyArrayElement)
* [`RedisModule_CallReplyAttribute`](#RedisModule_CallReplyAttribute)
* [`RedisModule_CallReplyAttributeElement`](#RedisModule_CallReplyAttributeElement)
* [`RedisModule_CallReplyBigNumber`](#RedisModule_CallReplyBigNumber)
* [`RedisModule_CallReplyBool`](#RedisModule_CallReplyBool)
* [`RedisModule_CallReplyDouble`](#RedisModule_CallReplyDouble)
* [`RedisModule_CallReplyInteger`](#RedisModule_CallReplyInteger)
* [`RedisModule_CallReplyLength`](#RedisModule_CallReplyLength)
* [`RedisModule_CallReplyMapElement`](#RedisModule_CallReplyMapElement)
* [`RedisModule_CallReplyProto`](#RedisModule_CallReplyProto)
* [`RedisModule_CallReplySetElement`](#RedisModule_CallReplySetElement)
* [`RedisModule_CallReplyStringPtr`](#RedisModule_CallReplyStringPtr)
* [`RedisModule_CallReplyType`](#RedisModule_CallReplyType)
* [`RedisModule_CallReplyVerbatim`](#RedisModule_CallReplyVerbatim)
* [`RedisModule_Calloc`](#RedisModule_Calloc)
* [`RedisModule_ChannelAtPosWithFlags`](#RedisModule_ChannelAtPosWithFlags)
* [`RedisModule_CloseKey`](#RedisModule_CloseKey)
* [`RedisModule_CommandFilterArgDelete`](#RedisModule_CommandFilterArgDelete)
* [`RedisModule_CommandFilterArgGet`](#RedisModule_CommandFilterArgGet)
* [`RedisModule_CommandFilterArgInsert`](#RedisModule_CommandFilterArgInsert)
* [`RedisModule_CommandFilterArgReplace`](#RedisModule_CommandFilterArgReplace)
* [`RedisModule_CommandFilterArgsCount`](#RedisModule_CommandFilterArgsCount)
* [`RedisModule_CreateCommand`](#RedisModule_CreateCommand)
* [`RedisModule_CreateDataType`](#RedisModule_CreateDataType)
* [`RedisModule_CreateDict`](#RedisModule_CreateDict)
* [`RedisModule_CreateModuleUser`](#RedisModule_CreateModuleUser)
* [`RedisModule_CreateString`](#RedisModule_CreateString)
* [`RedisModule_CreateStringFromCallReply`](#RedisModule_CreateStringFromCallReply)
* [`RedisModule_CreateStringFromDouble`](#RedisModule_CreateStringFromDouble)
* [`RedisModule_CreateStringFromLongDouble`](#RedisModule_CreateStringFromLongDouble)
* [`RedisModule_CreateStringFromLongLong`](#RedisModule_CreateStringFromLongLong)
* [`RedisModule_CreateStringFromStreamID`](#RedisModule_CreateStringFromStreamID)
* [`RedisModule_CreateStringFromString`](#RedisModule_CreateStringFromString)
* [`RedisModule_CreateStringPrintf`](#RedisModule_CreateStringPrintf)
* [`RedisModule_CreateSubcommand`](#RedisModule_CreateSubcommand)
* [`RedisModule_CreateTimer`](#RedisModule_CreateTimer)
* [`RedisModule_DbSize`](#RedisModule_DbSize)
* [`RedisModule_DeauthenticateAndCloseClient`](#RedisModule_DeauthenticateAndCloseClient)
* [`RedisModule_DefragAlloc`](#RedisModule_DefragAlloc)
* [`RedisModule_DefragCursorGet`](#RedisModule_DefragCursorGet)
* [`RedisModule_DefragCursorSet`](#RedisModule_DefragCursorSet)
* [`RedisModule_DefragRedisModuleString`](#RedisModule_DefragRedisModuleString)
* [`RedisModule_DefragShouldStop`](#RedisModule_DefragShouldStop)
* [`RedisModule_DeleteKey`](#RedisModule_DeleteKey)
* [`RedisModule_DictCompare`](#RedisModule_DictCompare)
* [`RedisModule_DictCompareC`](#RedisModule_DictCompareC)
* [`RedisModule_DictDel`](#RedisModule_DictDel)
* [`RedisModule_DictDelC`](#RedisModule_DictDelC)
* [`RedisModule_DictGet`](#RedisModule_DictGet)
* [`RedisModule_DictGetC`](#RedisModule_DictGetC)
* [`RedisModule_DictIteratorReseek`](#RedisModule_DictIteratorReseek)
* [`RedisModule_DictIteratorReseekC`](#RedisModule_DictIteratorReseekC)
* [`RedisModule_DictIteratorStart`](#RedisModule_DictIteratorStart)
* [`RedisModule_DictIteratorStartC`](#RedisModule_DictIteratorStartC)
* [`RedisModule_DictIteratorStop`](#RedisModule_DictIteratorStop)
* [`RedisModule_DictNext`](#RedisModule_DictNext)
* [`RedisModule_DictNextC`](#RedisModule_DictNextC)
* [`RedisModule_DictPrev`](#RedisModule_DictPrev)
* [`RedisModule_DictPrevC`](#RedisModule_DictPrevC)
* [`RedisModule_DictReplace`](#RedisModule_DictReplace)
* [`RedisModule_DictReplaceC`](#RedisModule_DictReplaceC)
* [`RedisModule_DictSet`](#RedisModule_DictSet)
* [`RedisModule_DictSetC`](#RedisModule_DictSetC)
* [`RedisModule_DictSize`](#RedisModule_DictSize)
* [`RedisModule_DigestAddLongLong`](#RedisModule_DigestAddLongLong)
* [`RedisModule_DigestAddStringBuffer`](#RedisModule_DigestAddStringBuffer)
* [`RedisModule_DigestEndSequence`](#RedisModule_DigestEndSequence)
* [`RedisModule_EmitAOF`](#RedisModule_EmitAOF)
* [`RedisModule_EventLoopAdd`](#RedisModule_EventLoopAdd)
* [`RedisModule_EventLoopAddOneShot`](#RedisModule_EventLoopAddOneShot)
* [`RedisModule_EventLoopDel`](#RedisModule_EventLoopDel)
* [`RedisModule_ExitFromChild`](#RedisModule_ExitFromChild)
* [`RedisModule_ExportSharedAPI`](#RedisModule_ExportSharedAPI)
* [`RedisModule_Fork`](#RedisModule_Fork)
* [`RedisModule_Free`](#RedisModule_Free)
* [`RedisModule_FreeCallReply`](#RedisModule_FreeCallReply)
* [`RedisModule_FreeClusterNodesList`](#RedisModule_FreeClusterNodesList)
* [`RedisModule_FreeDict`](#RedisModule_FreeDict)
* [`RedisModule_FreeModuleUser`](#RedisModule_FreeModuleUser)
* [`RedisModule_FreeServerInfo`](#RedisModule_FreeServerInfo)
* [`RedisModule_FreeString`](#RedisModule_FreeString)
* [`RedisModule_FreeThreadSafeContext`](#RedisModule_FreeThreadSafeContext)
* [`RedisModule_GetAbsExpire`](#RedisModule_GetAbsExpire)
* [`RedisModule_GetBlockedClientHandle`](#RedisModule_GetBlockedClientHandle)
* [`RedisModule_GetBlockedClientPrivateData`](#RedisModule_GetBlockedClientPrivateData)
* [`RedisModule_GetBlockedClientReadyKey`](#RedisModule_GetBlockedClientReadyKey)
* [`RedisModule_GetClientCertificate`](#RedisModule_GetClientCertificate)
* [`RedisModule_GetClientId`](#RedisModule_GetClientId)
* [`RedisModule_GetClientInfoById`](#RedisModule_GetClientInfoById)
* [`RedisModule_GetClientUserNameById`](#RedisModule_GetClientUserNameById)
* [`RedisModule_GetClusterNodeInfo`](#RedisModule_GetClusterNodeInfo)
* [`RedisModule_GetClusterNodesList`](#RedisModule_GetClusterNodesList)
* [`RedisModule_GetClusterSize`](#RedisModule_GetClusterSize)
* [`RedisModule_GetCommand`](#RedisModule_GetCommand)
* [`RedisModule_GetCommandKeys`](#RedisModule_GetCommandKeys)
* [`RedisModule_GetCommandKeysWithFlags`](#RedisModule_GetCommandKeysWithFlags)
* [`RedisModule_GetContextFlags`](#RedisModule_GetContextFlags)
* [`RedisModule_GetContextFlagsAll`](#RedisModule_GetContextFlagsAll)
* [`RedisModule_GetCurrentCommandName`](#RedisModule_GetCurrentCommandName)
* [`RedisModule_GetCurrentUserName`](#RedisModule_GetCurrentUserName)
* [`RedisModule_GetDbIdFromDefragCtx`](#RedisModule_GetDbIdFromDefragCtx)
* [`RedisModule_GetDbIdFromDigest`](#RedisModule_GetDbIdFromDigest)
* [`RedisModule_GetDbIdFromIO`](#RedisModule_GetDbIdFromIO)
* [`RedisModule_GetDbIdFromModuleKey`](#RedisModule_GetDbIdFromModuleKey)
* [`RedisModule_GetDbIdFromOptCtx`](#RedisModule_GetDbIdFromOptCtx)
* [`RedisModule_GetDetachedThreadSafeContext`](#RedisModule_GetDetachedThreadSafeContext)
* [`RedisModule_GetExpire`](#RedisModule_GetExpire)
* [`RedisModule_GetKeyNameFromDefragCtx`](#RedisModule_GetKeyNameFromDefragCtx)
* [`RedisModule_GetKeyNameFromDigest`](#RedisModule_GetKeyNameFromDigest)
* [`RedisModule_GetKeyNameFromIO`](#RedisModule_GetKeyNameFromIO)
* [`RedisModule_GetKeyNameFromModuleKey`](#RedisModule_GetKeyNameFromModuleKey)
* [`RedisModule_GetKeyNameFromOptCtx`](#RedisModule_GetKeyNameFromOptCtx)
* [`RedisModule_GetKeyspaceNotificationFlagsAll`](#RedisModule_GetKeyspaceNotificationFlagsAll)
* [`RedisModule_GetLFU`](#RedisModule_GetLFU)
* [`RedisModule_GetLRU`](#RedisModule_GetLRU)
* [`RedisModule_GetModuleUserFromUserName`](#RedisModule_GetModuleUserFromUserName)
* [`RedisModule_GetMyClusterID`](#RedisModule_GetMyClusterID)
* [`RedisModule_GetNotifyKeyspaceEvents`](#RedisModule_GetNotifyKeyspaceEvents)
* [`RedisModule_GetRandomBytes`](#RedisModule_GetRandomBytes)
* [`RedisModule_GetRandomHexChars`](#RedisModule_GetRandomHexChars)
* [`RedisModule_GetSelectedDb`](#RedisModule_GetSelectedDb)
* [`RedisModule_GetServerInfo`](#RedisModule_GetServerInfo)
* [`RedisModule_GetServerVersion`](#RedisModule_GetServerVersion)
* [`RedisModule_GetSharedAPI`](#RedisModule_GetSharedAPI)
* [`RedisModule_GetThreadSafeContext`](#RedisModule_GetThreadSafeContext)
* [`RedisModule_GetTimerInfo`](#RedisModule_GetTimerInfo)
* [`RedisModule_GetToDbIdFromOptCtx`](#RedisModule_GetToDbIdFromOptCtx)
* [`RedisModule_GetToKeyNameFromOptCtx`](#RedisModule_GetToKeyNameFromOptCtx)
* [`RedisModule_GetTypeMethodVersion`](#RedisModule_GetTypeMethodVersion)
* [`RedisModule_GetUsedMemoryRatio`](#RedisModule_GetUsedMemoryRatio)
* [`RedisModule_HashGet`](#RedisModule_HashGet)
* [`RedisModule_HashSet`](#RedisModule_HashSet)
* [`RedisModule_HoldString`](#RedisModule_HoldString)
* [`RedisModule_InfoAddFieldCString`](#RedisModule_InfoAddFieldCString)
* [`RedisModule_InfoAddFieldDouble`](#RedisModule_InfoAddFieldDouble)
* [`RedisModule_InfoAddFieldLongLong`](#RedisModule_InfoAddFieldLongLong)
* [`RedisModule_InfoAddFieldString`](#RedisModule_InfoAddFieldString)
* [`RedisModule_InfoAddFieldULongLong`](#RedisModule_InfoAddFieldULongLong)
* [`RedisModule_InfoAddSection`](#RedisModule_InfoAddSection)
* [`RedisModule_InfoBeginDictField`](#RedisModule_InfoBeginDictField)
* [`RedisModule_InfoEndDictField`](#RedisModule_InfoEndDictField)
* [`RedisModule_IsBlockedReplyRequest`](#RedisModule_IsBlockedReplyRequest)
* [`RedisModule_IsBlockedTimeoutRequest`](#RedisModule_IsBlockedTimeoutRequest)
* [`RedisModule_IsChannelsPositionRequest`](#RedisModule_IsChannelsPositionRequest)
* [`RedisModule_IsIOError`](#RedisModule_IsIOError)
* [`RedisModule_IsKeysPositionRequest`](#RedisModule_IsKeysPositionRequest)
* [`RedisModule_IsModuleNameBusy`](#RedisModule_IsModuleNameBusy)
* [`RedisModule_IsSubEventSupported`](#RedisModule_IsSubEventSupported)
* [`RedisModule_KeyAtPos`](#RedisModule_KeyAtPos)
* [`RedisModule_KeyAtPosWithFlags`](#RedisModule_KeyAtPosWithFlags)
* [`RedisModule_KeyExists`](#RedisModule_KeyExists)
* [`RedisModule_KeyType`](#RedisModule_KeyType)
* [`RedisModule_KillForkChild`](#RedisModule_KillForkChild)
* [`RedisModule_LatencyAddSample`](#RedisModule_LatencyAddSample)
* [`RedisModule_ListDelete`](#RedisModule_ListDelete)
* [`RedisModule_ListGet`](#RedisModule_ListGet)
* [`RedisModule_ListInsert`](#RedisModule_ListInsert)
* [`RedisModule_ListPop`](#RedisModule_ListPop)
* [`RedisModule_ListPush`](#RedisModule_ListPush)
* [`RedisModule_ListSet`](#RedisModule_ListSet)
* [`RedisModule_LoadConfigs`](#RedisModule_LoadConfigs)
* [`RedisModule_LoadDataTypeFromString`](#RedisModule_LoadDataTypeFromString)
* [`RedisModule_LoadDataTypeFromStringEncver`](#RedisModule_LoadDataTypeFromStringEncver)
* [`RedisModule_LoadDouble`](#RedisModule_LoadDouble)
* [`RedisModule_LoadFloat`](#RedisModule_LoadFloat)
* [`RedisModule_LoadLongDouble`](#RedisModule_LoadLongDouble)
* [`RedisModule_LoadSigned`](#RedisModule_LoadSigned)
* [`RedisModule_LoadString`](#RedisModule_LoadString)
* [`RedisModule_LoadStringBuffer`](#RedisModule_LoadStringBuffer)
* [`RedisModule_LoadUnsigned`](#RedisModule_LoadUnsigned)
* [`RedisModule_Log`](#RedisModule_Log)
* [`RedisModule_LogIOError`](#RedisModule_LogIOError)
* [`RedisModule_MallocSize`](#RedisModule_MallocSize)
* [`RedisModule_MallocSizeDict`](#RedisModule_MallocSizeDict)
* [`RedisModule_MallocSizeString`](#RedisModule_MallocSizeString)
* [`RedisModule_Milliseconds`](#RedisModule_Milliseconds)
* [`RedisModule_ModuleTypeGetType`](#RedisModule_ModuleTypeGetType)
* [`RedisModule_ModuleTypeGetValue`](#RedisModule_ModuleTypeGetValue)
* [`RedisModule_ModuleTypeReplaceValue`](#RedisModule_ModuleTypeReplaceValue)
* [`RedisModule_ModuleTypeSetValue`](#RedisModule_ModuleTypeSetValue)
* [`RedisModule_MonotonicMicroseconds`](#RedisModule_MonotonicMicroseconds)
* [`RedisModule_NotifyKeyspaceEvent`](#RedisModule_NotifyKeyspaceEvent)
* [`RedisModule_OpenKey`](#RedisModule_OpenKey)
* [`RedisModule_PoolAlloc`](#RedisModule_PoolAlloc)
* [`RedisModule_PublishMessage`](#RedisModule_PublishMessage)
* [`RedisModule_PublishMessageShard`](#RedisModule_PublishMessageShard)
* [`RedisModule_RandomKey`](#RedisModule_RandomKey)
* [`RedisModule_Realloc`](#RedisModule_Realloc)
* [`RedisModule_RedactClientCommandArgument`](#RedisModule_RedactClientCommandArgument)
* [`RedisModule_RegisterBoolConfig`](#RedisModule_RegisterBoolConfig)
* [`RedisModule_RegisterClusterMessageReceiver`](#RedisModule_RegisterClusterMessageReceiver)
* [`RedisModule_RegisterCommandFilter`](#RedisModule_RegisterCommandFilter)
* [`RedisModule_RegisterDefragFunc`](#RedisModule_RegisterDefragFunc)
* [`RedisModule_RegisterEnumConfig`](#RedisModule_RegisterEnumConfig)
* [`RedisModule_RegisterInfoFunc`](#RedisModule_RegisterInfoFunc)
* [`RedisModule_RegisterNumericConfig`](#RedisModule_RegisterNumericConfig)
* [`RedisModule_RegisterStringConfig`](#RedisModule_RegisterStringConfig)
* [`RedisModule_Replicate`](#RedisModule_Replicate)
* [`RedisModule_ReplicateVerbatim`](#RedisModule_ReplicateVerbatim)
* [`RedisModule_ReplySetArrayLength`](#RedisModule_ReplySetArrayLength)
* [`RedisModule_ReplySetAttributeLength`](#RedisModule_ReplySetAttributeLength)
* [`RedisModule_ReplySetMapLength`](#RedisModule_ReplySetMapLength)
* [`RedisModule_ReplySetSetLength`](#RedisModule_ReplySetSetLength)
* [`RedisModule_ReplyWithArray`](#RedisModule_ReplyWithArray)
* [`RedisModule_ReplyWithAttribute`](#RedisModule_ReplyWithAttribute)
* [`RedisModule_ReplyWithBigNumber`](#RedisModule_ReplyWithBigNumber)
* [`RedisModule_ReplyWithBool`](#RedisModule_ReplyWithBool)
* [`RedisModule_ReplyWithCString`](#RedisModule_ReplyWithCString)
* [`RedisModule_ReplyWithCallReply`](#RedisModule_ReplyWithCallReply)
* [`RedisModule_ReplyWithDouble`](#RedisModule_ReplyWithDouble)
* [`RedisModule_ReplyWithEmptyArray`](#RedisModule_ReplyWithEmptyArray)
* [`RedisModule_ReplyWithEmptyString`](#RedisModule_ReplyWithEmptyString)
* [`RedisModule_ReplyWithError`](#RedisModule_ReplyWithError)
* [`RedisModule_ReplyWithLongDouble`](#RedisModule_ReplyWithLongDouble)
* [`RedisModule_ReplyWithLongLong`](#RedisModule_ReplyWithLongLong)
* [`RedisModule_ReplyWithMap`](#RedisModule_ReplyWithMap)
* [`RedisModule_ReplyWithNull`](#RedisModule_ReplyWithNull)
* [`RedisModule_ReplyWithNullArray`](#RedisModule_ReplyWithNullArray)
* [`RedisModule_ReplyWithSet`](#RedisModule_ReplyWithSet)
* [`RedisModule_ReplyWithSimpleString`](#RedisModule_ReplyWithSimpleString)
* [`RedisModule_ReplyWithString`](#RedisModule_ReplyWithString)
* [`RedisModule_ReplyWithStringBuffer`](#RedisModule_ReplyWithStringBuffer)
* [`RedisModule_ReplyWithVerbatimString`](#RedisModule_ReplyWithVerbatimString)
* [`RedisModule_ReplyWithVerbatimStringType`](#RedisModule_ReplyWithVerbatimStringType)
* [`RedisModule_ResetDataset`](#RedisModule_ResetDataset)
* [`RedisModule_RetainString`](#RedisModule_RetainString)
* [`RedisModule_SaveDataTypeToString`](#RedisModule_SaveDataTypeToString)
* [`RedisModule_SaveDouble`](#RedisModule_SaveDouble)
* [`RedisModule_SaveFloat`](#RedisModule_SaveFloat)
* [`RedisModule_SaveLongDouble`](#RedisModule_SaveLongDouble)
* [`RedisModule_SaveSigned`](#RedisModule_SaveSigned)
* [`RedisModule_SaveString`](#RedisModule_SaveString)
* [`RedisModule_SaveStringBuffer`](#RedisModule_SaveStringBuffer)
* [`RedisModule_SaveUnsigned`](#RedisModule_SaveUnsigned)
* [`RedisModule_Scan`](#RedisModule_Scan)
* [`RedisModule_ScanCursorCreate`](#RedisModule_ScanCursorCreate)
* [`RedisModule_ScanCursorDestroy`](#RedisModule_ScanCursorDestroy)
* [`RedisModule_ScanCursorRestart`](#RedisModule_ScanCursorRestart)
* [`RedisModule_ScanKey`](#RedisModule_ScanKey)
* [`RedisModule_SelectDb`](#RedisModule_SelectDb)
* [`RedisModule_SendChildHeartbeat`](#RedisModule_SendChildHeartbeat)
* [`RedisModule_SendClusterMessage`](#RedisModule_SendClusterMessage)
* [`RedisModule_ServerInfoGetField`](#RedisModule_ServerInfoGetField)
* [`RedisModule_ServerInfoGetFieldC`](#RedisModule_ServerInfoGetFieldC)
* [`RedisModule_ServerInfoGetFieldDouble`](#RedisModule_ServerInfoGetFieldDouble)
* [`RedisModule_ServerInfoGetFieldSigned`](#RedisModule_ServerInfoGetFieldSigned)
* [`RedisModule_ServerInfoGetFieldUnsigned`](#RedisModule_ServerInfoGetFieldUnsigned)
* [`RedisModule_SetAbsExpire`](#RedisModule_SetAbsExpire)
* [`RedisModule_SetClusterFlags`](#RedisModule_SetClusterFlags)
* [`RedisModule_SetCommandInfo`](#RedisModule_SetCommandInfo)
* [`RedisModule_SetDisconnectCallback`](#RedisModule_SetDisconnectCallback)
* [`RedisModule_SetExpire`](#RedisModule_SetExpire)
* [`RedisModule_SetLFU`](#RedisModule_SetLFU)
* [`RedisModule_SetLRU`](#RedisModule_SetLRU)
* [`RedisModule_SetModuleOptions`](#RedisModule_SetModuleOptions)
* [`RedisModule_SetModuleUserACL`](#RedisModule_SetModuleUserACL)
* [`RedisModule_SignalKeyAsReady`](#RedisModule_SignalKeyAsReady)
* [`RedisModule_SignalModifiedKey`](#RedisModule_SignalModifiedKey)
* [`RedisModule_StopTimer`](#RedisModule_StopTimer)
* [`RedisModule_Strdup`](#RedisModule_Strdup)
* [`RedisModule_StreamAdd`](#RedisModule_StreamAdd)
* [`RedisModule_StreamDelete`](#RedisModule_StreamDelete)
* [`RedisModule_StreamIteratorDelete`](#RedisModule_StreamIteratorDelete)
* [`RedisModule_StreamIteratorNextField`](#RedisModule_StreamIteratorNextField)
* [`RedisModule_StreamIteratorNextID`](#RedisModule_StreamIteratorNextID)
* [`RedisModule_StreamIteratorStart`](#RedisModule_StreamIteratorStart)
* [`RedisModule_StreamIteratorStop`](#RedisModule_StreamIteratorStop)
* [`RedisModule_StreamTrimByID`](#RedisModule_StreamTrimByID)
* [`RedisModule_StreamTrimByLength`](#RedisModule_StreamTrimByLength)
* [`RedisModule_StringAppendBuffer`](#RedisModule_StringAppendBuffer)
* [`RedisModule_StringCompare`](#RedisModule_StringCompare)
* [`RedisModule_StringDMA`](#RedisModule_StringDMA)
* [`RedisModule_StringPtrLen`](#RedisModule_StringPtrLen)
* [`RedisModule_StringSet`](#RedisModule_StringSet)
* [`RedisModule_StringToDouble`](#RedisModule_StringToDouble)
* [`RedisModule_StringToLongDouble`](#RedisModule_StringToLongDouble)
* [`RedisModule_StringToLongLong`](#RedisModule_StringToLongLong)
* [`RedisModule_StringToStreamID`](#RedisModule_StringToStreamID)
* [`RedisModule_StringTruncate`](#RedisModule_StringTruncate)
* [`RedisModule_SubscribeToKeyspaceEvents`](#RedisModule_SubscribeToKeyspaceEvents)
* [`RedisModule_SubscribeToServerEvent`](#RedisModule_SubscribeToServerEvent)
* [`RedisModule_ThreadSafeContextLock`](#RedisModule_ThreadSafeContextLock)
* [`RedisModule_ThreadSafeContextTryLock`](#RedisModule_ThreadSafeContextTryLock)
* [`RedisModule_ThreadSafeContextUnlock`](#RedisModule_ThreadSafeContextUnlock)
* [`RedisModule_TrimStringAllocation`](#RedisModule_TrimStringAllocation)
* [`RedisModule_TryAlloc`](#RedisModule_TryAlloc)
* [`RedisModule_UnblockClient`](#RedisModule_UnblockClient)
* [`RedisModule_UnlinkKey`](#RedisModule_UnlinkKey)
* [`RedisModule_UnregisterCommandFilter`](#RedisModule_UnregisterCommandFilter)
* [`RedisModule_ValueLength`](#RedisModule_ValueLength)
* [`RedisModule_WrongArity`](#RedisModule_WrongArity)
* [`RedisModule_Yield`](#RedisModule_Yield)
* [`RedisModule_ZsetAdd`](#RedisModule_ZsetAdd)
* [`RedisModule_ZsetFirstInLexRange`](#RedisModule_ZsetFirstInLexRange)
* [`RedisModule_ZsetFirstInScoreRange`](#RedisModule_ZsetFirstInScoreRange)
* [`RedisModule_ZsetIncrby`](#RedisModule_ZsetIncrby)
* [`RedisModule_ZsetLastInLexRange`](#RedisModule_ZsetLastInLexRange)
* [`RedisModule_ZsetLastInScoreRange`](#RedisModule_ZsetLastInScoreRange)
* [`RedisModule_ZsetRangeCurrentElement`](#RedisModule_ZsetRangeCurrentElement)
* [`RedisModule_ZsetRangeEndReached`](#RedisModule_ZsetRangeEndReached)
* [`RedisModule_ZsetRangeNext`](#RedisModule_ZsetRangeNext)
* [`RedisModule_ZsetRangePrev`](#RedisModule_ZsetRangePrev)
* [`RedisModule_ZsetRangeStop`](#RedisModule_ZsetRangeStop)
* [`RedisModule_ZsetRem`](#RedisModule_ZsetRem)
* [`RedisModule_ZsetScore`](#RedisModule_ZsetScore)
* [`RedisModule__Assert`](#RedisModule__Assert)

