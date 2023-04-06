Returns the string representation of the type of the value stored at _key_.
For core Redis data types, the type can be one of the following:

* **"string"**: for the [string](/docs/data-types/strings), [bitmap](/docs/data-types/bitmaps), [bitfield](/docs/data-types/bitfields) and [HyperLogLog](/docs/data-types/hyperloglogs) data types.
* **"list"**: for the [list data type](/docs/data-types/lists).
* **"set"**: for the [set data type](/docs/data-types/sets).
* **"zset"**: for the [sorted set](/docs/data-types/sorted-sets) and [geospatial](/docs/data-types/geospatial) data types.
* **"hash"**: for the [hash data type](/docs/data-types/hashes).
* **"stream"**: for the [stream data type](/docs/data-types/streams).

If the _key_'s value is implemented via a module, the returned type is the module's name.

@return

@simple-string-reply: type of _key_, or "none" when _key_ doesn't exist.

@examples

```cli
SET key1 "value"
LPUSH key2 "value"
SADD key3 "value"
TYPE key1
TYPE key2
TYPE key3
```
