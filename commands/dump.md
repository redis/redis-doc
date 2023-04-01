The reply can be synthesized back into a Redis key using the `RESTORE` command.

The serialization format is opaque and non-standard.
However, it has a few semantic characteristics:

* It contains a 64-bit checksum that is used to make sure errors will be
  detected.
  The `RESTORE` command makes sure to check the checksum before synthesizing a
  key using the serialized value.
* Values are encoded in the same format used by RDB.
* An RDB version is encoded inside the serialized value, so that different Redis
  versions with incompatible RDB formats will refuse to process the serialized
  value.

The serialized value does **NOT** contain expire information.
To capture the time-to-live of the current value the `PTTL` command should be used.

If _key_ doesn't exist a `nil` reply is returned.

@return

@bulk-string-reply: the serialized value.

@examples

```
> SET mykey 10
OK
> DUMP mykey
"\x00\xc0\n\n\x00n\x9fWE\x0e\xaec\xbb"
```
