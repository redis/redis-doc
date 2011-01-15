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

If you want to know more about this, read the next section.

Using hashes to abstract a very memory efficient plain key-value store on top of Redis
--------------------------------------------------------------------------------------

I understand the title of this section is a bit scaring, but I'm going to explain very well what this is about. In short:

You can model a plain key-value store in Redis where values can just be
just strings, that is not just more memory efficient than Redis plain keys
but also much more memory efficient than memcached.

Let's start with some fact: five keys use a lot more memory than a single key
containing an hash with five fields. How is this possible? We use a trick.
In theory in order to guarantee that we perform lookups in constant time
(also known as O(1) in big O notation) there is the need to use a data structure
with a constant time complexity in the average case, like an hash table.

But many times hashes contain just a few fields. When hashes are small we can
instead just encode this hashes in an O(N) data structure, like a linear
array with length-prefixed key value pairs. Since we do this only when N
is small, the amortized time for HGET and HSET commands is still O(1): the
hash will be converted into a real hash table as soon as the number of elements
will grow too much.

This does not work well just from the point of view of time complexity, but
also from the point of view of constant time, since a linear array of key
value pairs happens to play very well with the CPU cache (it has a better
locality than an hash table).

Not everything is cool about that: since hash fields and values are not
(always) represented as full featured Redis objects, hash fields can't have
an associated time to live (expire) like a real key, and can only contain
a string. But we are ok with this, this was anyway the intention when the
hash data type API was designed (we trust simplicity more than features).

Ok so hashes are memory efficient. This is very useful when using hashes
to represent objects or to model other problems when there is an object
containing fields. But what about if we have a plain key value business?
We can still take advantage of hashes.

Imagine we want to use Redis as a cache for many small objects, that can be
JSON encoded objects, small HTML fragments, simple key -> boolean values
and so forth. Whatever is a string -> string map with small key and value.
Now let's assume the objects we want to cache are numbered, like:

 * object:102393
 * object:1234
 * object:5

And so forth. This is what we can do. Every time there is to perform a
SET operation to set a new value, we actually split the key into two parts,
one used as a key, and used as field name for the hash. For instance the
object named *object:1234" is actually split in:

* a Key named object:12
* a Field named 34

So we use all the characters but the latest two for the key, and the final
two characters for the hash field name. To set our key we use the following
command:

    HSET object:12 34 somevalue

As you can see every hash will end containing, more or less, 100 fields, that
is optimal as a compromise between CPU and memory saved.

There is another very important thing to note, every hash will have more or
less 100 fields regardless of the number of objects we cached. This is since
our objects will always end with a number, and not a random string. In some
way the final number can be considered as a form of implicit pre-sharding.

What about small numbers? Like object:2? We handle this case using just
"object:" as a key name, and the whole number as the hash field name.
So object:2 and object:10 will both end inside the key "object:", but one
as field name "2" and one as "10".

How much memory we save this way?

I used the following Ruby program to test how this works:

    require 'rubygems'
    require 'redis'

    UseOptimization = true

    def hash_get_key_field(key)
        s = key.split(":")
        if s[1].length > 2
            {:key => s[0]+":"+s[1][0..-3], :field => s[1][-2..-1]}
        else
            {:key => s[0]+":", :field => s[1]}
        end
    end

    def hash_set(r,key,value)
        kf = hash_get_key_field(key)
        r.hset(kf[:key],kf[:field],value)
    end

    def hash_get(r,key,value)
        kf = hash_get_key_field(key)
        r.hget(kf[:key],kf[:field],value)
    end

    r = Redis.new
    (0..100000).each{|id|
        key = "object:#{id}"
        if UseOptimization
            hash_set(r,key,"val")
        else
            r.set(key,"val")
        end
    }

This is the result against a 64 bit instance of Redis 2.2:

 * UseOptimization set to true: 1.7 MB of used memory
 * UseOptimization set to false; 11 MB of used memory

This is an order of magnitude, I think this makes Redis more or less the most
memory efficient plain key value store out there.

IMPORTANT, for this to work, make sure that in your redis.conf you have
something like this:

    hash-max-zipmap-entries 256

Work in progress
----------------

Work in progress... more tips will be added soon.
