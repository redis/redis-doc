This command copies the value stored at the _source_ key to the _destination_ key.

By default, the _destination_ key is created in the same logical database used by the connection.
The `DB` option allows specifying an alternative logical database index for the destination key.

The command returns an error when the _destination_ key already exists.
The `REPLACE` option removes the _destination_ key before copying the value to it.

@return

@integer-reply, specifically:

* `1` if _source_ was copied.
* `0` if _source_ was not copied.

@examples

```
SET dolly "sheep"
COPY dolly clone
GET clone
```