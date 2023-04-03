Returns the length of the string value stored at _key_.
An error is returned if the value of _key_ isn't a string.

@return

@integer-reply: the length of the string at _key_, or `0` when _key_ doesn't exist.

{{% alert title="Note" color="info" %}}
The empty string ("") is a valid Redis value, and also has a length of `0`.
{{% /alert %}}

@examples

```cli
SET mykey "Hello world"
STRLEN mykey
STRLEN nonexisting
```
