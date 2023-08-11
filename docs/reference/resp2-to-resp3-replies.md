---
title: "RESP2 to RESP3 replies migration guide"
linkTitle: "RESP2 to RESP3 migration"
weight: 4
description: RESP2 to RESP3 replies reference for clients developers
aliases:
    - /topics/resp2-to-resp3-replies/
---

In the journey from RESP2 to [RESP3](https://redis.io/docs/reference/protocol-spec/), one of the primary motivations was 
to streamline the developer experience by simplifying response parsing. Over time, it became evident that developers 
frequently performed specific data transformations on RESP2 replies. Addressing these transformations directly at the 
protocol level not only reduces the overhead for developers but also ensures a more consistent and efficient data 
handling process. This documentation provides a reference for developers to migrate their clients from RESP2 to RESP3.

### Command Replies Comparison
- If you see any missing commands, please [open an issue](https://github.com/redis/redis-doc/issues/new?title=RESP2-to-RESP3%20command%20is%20missing)
- `null` was "promoted" from a subtype of `BlobString` and `Array` to its own type, these changes are not included in this list.
- The types are described using [“TypeScript like” syntax](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html)


### Cluster Management
| Command        | RESP2 Reply                                                           | RESP3 Reply                                                                                  |
|----------------|-----------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| CLUSTER SLOTS  | Array<\[number, number, ...\[BlobString, number, BlobString, Array]]> | Array<\[number, number, ...\[BlobString, number, BlobString, Map\<BlobString, BlobString>]]> |
| CLUSTER SHARDS | Array                                                                 | Map                                                                                          |

### Connection management
| Command     | RESP2 Reply | RESP3 Reply    |
|-------------|-------------|----------------|
| CLIENT INFO | BlobString  | VerbatimString |
| CLIENT LIST | BlobString  | VerbatimString |


### Generic
| Command   | RESP2 Reply | RESP3 Reply            |
|-----------|-------------|------------------------|
| RANDOMKEY | BlobString  | null &#124; BlobString |

### Geo
| Command                     | RESP2 Reply        | RESP3 Reply    |
|-----------------------------|--------------------|----------------|
| GEORADIUS WITHCOORD         | \[..., BlobString] | \[..., Double] |
| GEORADIUSBYMEMBER WITHCOORD | \[..., BlobString] | \[..., Double] |
| GEOSEARCH WITHCOORD         | \[..., BlobString] | \[..., Double] |


### Hash
| Command              | RESP2 Reply        | RESP3 Reply                      |
|----------------------|--------------------|----------------------------------|
| HGETALL              | Array              | Map                              |
| HRANDFIELD WITHVALUE | Array\<BlobString> | Array<\[BlobString, BlobString]> |

### Scripting and Functions
| Command                | RESP2 Reply                                                                                                                                                                                             | RESP3 Reply                                                                                                                                                                                  |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FUNCTION LIST          | Array<\[‘library\_name’, BlobString, ‘engine’, BlobString, ‘functions’, Array<\[‘name’, BlobString, ‘description’, BlobString &#124; null, ‘flags’, Array\<BlobString>]>]>                              | Array<\[{ library\_name: BlobString, engine: BlobString, functions: Array<{ name: BlobString, description: BlobString &#124; null, flags: Set\<BlobString> }> }]>                            |
| FUNCTION LIST WITHCODE | Array<\[‘library\_name’, BlobString, ‘engine’, BlobString, ‘functions’, Array<\[‘name’, BlobString, ‘description’, BlobString &#124; null, ‘flags’, Array\<BlobString>]>, ‘library\_code’, BlobString]> | Array<\[{ library\_name: BlobString, engine: BlobString, functions: Array<{ name: BlobString, description: BlobString &#124; null, flags: Set\<BlobString> }>, library\_code: BlobString }]> |


### Server Management
| Command      | RESP2 Reply                                                                                                 | RESP3 Reply                                  |
|--------------|-------------------------------------------------------------------------------------------------------------|----------------------------------------------|
| MODULE LIST  | Array<\[BlobString<‘name’>, BlobString, BlobString<‘version’>, number]>                                     | Array<{ name: BlobString, version: number }> |
| MEMORY STATS | Array                                                                                                       | Map                                          |
| ACL LOG      | \[..., ‘age-seconds’, BlobString, …]                                                                        | { …, ‘age-seconds’: Double }                 |
| ACL GETUSER  | Array                                                                                                       | Map                                          |
| COMMAND      | Array<\[BlobString, number, Set\<BlobString>, number, number, number, Set\<BlobString>, Set\<BlobString>,]> |                                              |

### Sentinel
| Command             | RESP2 Reply | RESP3 Reply |
|---------------------|-------------|-------------|
| SENTINEL CONFIG GET | Array       | Map         |

### String
| Command | RESP2 Reply | RESP3 Reply |
|---------|-------------|-------------|
| LCS IDX | Array       | Map         |

### Set
| Command                                                              | RESP2 Reply | RESP3 Reply |
|----------------------------------------------------------------------|-------------|-------------|
| SINTER <br/>SPOP COUNT<br/>SMEMBERS<br/>SRANDMEMBER COUNT<br/>SUNION | Array       | Set         |

### Sorted Set
| Command                  | RESP2 Reply                                                 | RESP3 Reply                                             |
|--------------------------|-------------------------------------------------------------|---------------------------------------------------------|
| ZADD INCR                | BlobString                                                  | Double                                                  |
| ZDIFF WITHSCORES         | Array\<BlobString>                                          | Array<\[BlobString, Double]>                            |
| ZINCRBY                  | BlobString                                                  | Double                                                  |
| ZINTER WITHSCORES        | Array\<BlobString>                                          | Array<\[BlobString, Double]>                            |
| ZMPOP                    | null &#124; \[BlobString, Array<\[BlobString, BlobString]>] | null &#124; \[BlobString, Array<\[BlobString, Double]>] |
| ZMSCORE                  | Array\<null &#124; BlobString>                              | Array\<null &#124; Double>                              |
| ZRANDMEMBER WITHSCORES   | Array\<BlobString>                                          | Array<\[BlobString, Double]>                            |
| ZSCORE                   | BlobString                                                  | Double                                                  |
| ZUNION WITHSCORES        | Array\<BlobString>                                          | Array<\[BlobString, Double]>                            |
| ZRANK WITHSCORE          | \[number, BlobString]                                       | \[number, Double]                                       |
| ZREVRANK WITHSCORE       | \[number, BlobString]                                       | \[number, Double]                                       |
| ZRANGE WITHSCORES        | Array\<BlobString>                                          | Array<\[BlobString, Double]                             |
| ZRANGEBYSCORE WITHSCORES | Array\<BlobString>                                          | Array<\[BlobString, Double]                             |
| ZMPOP                    | \[BlobString, Array<\[BlobString, BlobString]>]             | \[BlobString, Array<\[BlobString, Double]>]             |
| BZPOPMAX                 | null &#124; \[BlobString, BlobString, BlobString]           | null &#124; \[BlobString, BlobString, Double]           |
| BZPOPMIN                 | null &#124; \[BlobString, BlobString, BlobString]           | null &#124; \[BlobString, BlobString, Double]           |
| ZPOPMIN                  | null &#124; \[BlobString, BlobString]                       | null &#124; \[BlobString, Double]                       |
| ZPOPMIN COUNT            | null &#124; Array\<BlobString\>                             | null &#124; Array<\[BlobString, Double]>                |
| ZPOPMAX                  | null &#124; \[BlobString, BlobString]                       | null &#124; \[BlobString, Double]                       |
| ZPOPMAX COUNT            | null &#124; Array\<BlobString\>                             | null &#124; Array<\[BlobString, Double]>                |

### Stream
| Command         | RESP2 Reply                                                           | RESP3 Reply                                                       |
|-----------------|-----------------------------------------------------------------------|-------------------------------------------------------------------|
| XINFO CONSUMERS | Array                                                                 | Map                                                               |
| XINFO GROUPS    | Array                                                                 | Map                                                               |
| XINFO STREAM    | Array                                                                 | Map                                                               |
| XREAD           | Array<\[BlobString, \[BlobString, Array<\[BlobString, BlobString]>]]> | Map\<BlobString, \[BlobString, Array<\[BlobString, BlobString]>]> |
| XREADGROUP      | Array<\[BlobString, \[BlobString, Array<\[BlobString, BlobString]>]]> | Map\<BlobString, \[BlobString, Array<\[BlobString, BlobString]>]> |
