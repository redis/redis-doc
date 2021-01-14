Flush the Lua scripts cache.

Please refer to the `EVAL` documentation for detailed information about Redis
Lua scripting.

`SYNC` and `ASYNC`
---

`SCRIPT FLUSH`：flushes the cache in an sync manner, but if **lazyfree-lazy-user-flush** (available since 6.2) is yes, it will be flushed asynchronously.  
`SCRIPT FLUSH SYNC`: flushes the cache in an sync manner.(available since 6.2)  
`SCRIPT FLUSH ASYNC`: flushes the cache in an async manner. (available since 6.2) 

@return

@simple-string-reply
