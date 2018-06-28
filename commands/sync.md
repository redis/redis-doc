`SYNC` command is used to sync slave to master.

When a slave sends a `SYNC` command to master, master receives the `SYNC` command and starts background saving. It also stores all the commands that change the dataset among the newly requested commands. When background saving is complete, the master sends the database file stored in the disk to the slave. The slave that receives the file loads it into memory.

```
$ redis-cli sync
Entering slave output mode...  (press Ctrl-C to quit)
SYNC with master, discarding 175 bytes of bulk transfer...
SYNC done. Logging commands from master.
"PING"
```

@return

**Non standard return value**, just received commands from master in an infinite flow after print out default sync message.
