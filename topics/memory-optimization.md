This page is a work in progress. Currently it is just a list of things you should check if you have problems with memory.

Special encoding of small aggregate data types
----------------------------------------------

Since Redis 2.2 many data types are optimized to use less space up to a certain size. Hashes, Lists of any kind and Sets composed of just integers, when smaller than a given number of elements, and up to a maximum element size, are encoded in a very memory efficient way that uses *up to 10 times less memory* (with 5 time less memory used being the average saving).

This is completely transparent from the point of view of the user and API.
Since this is a CPU / memory trade off it is possible to tune the maximum number of elements and maximum element size for special encoded types using the following redis.conf directives.

    hash-max-zipmap-entries 64
    hash-max-zipmap-value 512
    list-max-ziplist-entries 512
    list-max-ziplist-value 64
    set-max-intset-entries 512

If a specially encoded value will overflow the configured max size, Redis will automatically convert it into normal encoding. This operation is very fast for small values, but if you change the setting in order to use specially encoded values for much larger aggregate types the suggestin is to run some benchmark and test to check the convertion time.

Using 32 bit instances
----------------------

Redis compiled with 32 bit target uses a lot less memory per key, since pointers are small, but such an instance will be limited to 4 GB of maximum memory usage. To compile Redis as 32 bit binary use *make 32bit*. RDB and AOF files are compatible between 32 bit and 64 bit instances (and between little and big endian of course) so you can switch from 32 to 64 bit, or the contrary, without problems.

New 2.2 bit and byte level operations
-------------------------------------

Redis 2.2 introduced new bit and byte level operations: [GETRANGE](/commands/getrange), [SETRANGE](/commands/setrange), [GETBIT](/commands/getbit) and [SETBIT](/commands/setbit). Using this commands you can treat the Redis string type as a random access array. For instance if you have an application where users are identified by an unique progressive integer number, you can use a bitmap in order to save information about sex of users, setting the bit for females and clearing it for males, or the other way around. With 100 millions of users this data will take just 12 megabyte of RAM in a Redis instance. You can do the same using [GETRANGE](/commands/getrange) and [SETRANGE](/commands/setrange) in order to store one byte of information for user. This is just an example but it is actually possible to model a number of problems in very little space with this new primitives.

Use hashes when possible
------------------------

Small hashes are encoded in a very small space, so you should try representing your data using hashes every time it is possible. For instance if you have objects representing users in a web application, instead of using different keys for name, surname, email, password, use a single hash with all the required fields.

Work in progress
----------------

Work in progress... more tips will be added soon.
