Redis Persistence
===

Redis provides a wide range of persistence options:

* The RDB persistence performs point-in-time snapshots of your dataset at
specified intervals.
* The AOF persistence logs every write operation received by the server, that
would be replayed at the server at the startup time, reconstructing the
original dataset. Commands are logged using the same format as the Redis
protocol itself, in an append-only fashion. Redis is able to rewrite the log
in background when it gets too big.
* If you wish, you can disable persistence at all, in case you want your data
to exist for as long as the server runs.
* It is possible to combine both AOF and RDB on the same instance. In this
case, when Redis restarts the AOF file is used to reconstruct the original
dataset since it is guaranteed to be the most complete source of information.

The most important thing to understand is the different trade-offs between the
RDB and AOF persistence. Let's start with RDB:

RDB advantages
---

* RDB is a very compact single-file point-in-time representation of your Redis
data. RDB files are perfect for backups. For instance you may want to archive
your RDB files every hour for the latest 24 hours, and to save an RDB snapshot
every day for 30 days. This allows you to easily restore different versions of
the data set in case of disasters.
* RDB is very good for disaster recovery, being a single compact file it can be
transferred to a distant data center, or stored in Amazon S3 (possibly encrypted).
* RDB maximizes Redis performance since the only work the Redis parent process
needs to do in order to persist the data is to fork a child that would do all
the rest. The parent instance will never perform disk I/O or alike.
* RDB allows faster restarts with big datasets compared to AOF.

RDB disadvantages
---

* RDB is NOT good if you need to minimize the chances of the data loss in case
Redis stops working unexpectedly (for example after a power outage). You can
configure different *save points* when an RDB should be produced (for instance
if at least 100 writes have happened against the data set during the last five
minutes, and you can also configure multiple save points). However you would
usually create an RDB snapshot every five minutes or more, so that in case of
Redis stopping working without a correct shutdown for any reason you would be
prepared to loose only the latest five minutes of the data.
* RDB needs to invoke fork() call often in order to persist the data on a disk
using a child process. Fork calls can be time consuming if the dataset is big,
and may result in Redis stopping serving clients for some milliseconds or even
up to a second if the dataset is very big and the CPU performance is not that
great. AOF needs to fork() too, but you can tune how often you want to rewrite
your logs without any trade-offs on durability.

AOF advantages
---

* AOF persistence is much more durable: you can have different fsync policies:
no fsync at all, fsync every second, fsync at every query. With the default
policy of fsync every second write performances is still great because fsync is
run in a background thread and the main thread tries hard to perform writes
when no other fsync calla are in progress. You can only loose one second worth
of writes.
* The AOF log is an append only log, so there are no seeks, nor any corruption
problems if there is a power outage. Even if the log ends with a half-written
command for some reason (because of a full disk erorr or any other reasons) the
redis-check-aof tool can fix it easily.
* Redis is able to automatically rewrite the AOF in background when it gets too
big. The rewrite is completely safe because while Redis continues appending to the
old file, a completely new one file is produced with the minimal set of operations
needed to create the current data set, and once this second file is ready Redis
switches the two and starts appending to the new one.
* AOF contains a log of all the operations one after another in an easy to
understand and parse format. You can even easily export an AOF file. For
instance even if you flushed everything in an error using a FLUSHALL command,
provided no rewrite of the log file was performed in the meantime you can still save
your dataset just by stopping the server, removing the latest command from the
log, and restarting Redis again.

AOF disadvantages
---

* AOF files are usually bigger than the equivalent RDB files for the same
dataset.
* AOF can be slower than RDB depending on the exact fsync policy. In general,
with fsync mode set to *every second* performance is still very good, and with
fsync disabled it should be exactly as good as with RDB replication even under
high load. Still RDB can provide better guarantees about the maximum latency of
a restore operation even in the case of a huge write load.
* In the past we encountered rare bugs in the specific commands (for instance
there was one involving blocking commands like BRPOPLPUSH) causing the produced
AOF log file to not reproduce exactly the same dataset upon reloading. These
bugs are rare and we have tests in the test suite creating random complex
datasets automatically and reloading them to check if everything is ok, while
possibility of this kind of bugs with RDB persistence is almost negligible. To
make this point more clear: the Redis AOF is constructed by incrementally
updating an existing state, like MySQL or MongoDB does, while the RDB
snapshotting creates everything from the scratch again and again, which is
conceptually more robust. However, it should be noted that:
1. every time the AOF is rewritten by Redis it is recreated from the scratch
starting from an up to date information stored in the data set, making its
resistance to the bugs stronger comparing to a way if it would be written by
always appending data to the AOF file (or one rewritten by reading the old AOF
instead of reading the data from the memory).
2. we have never had a single report from users about an AOF corruption that
was detected in the wild.

Ok, so what should I use?
---

The general recommendation is that you should use both persistence methods if
you want a degree of data safety comparable to what PostgreSQL can provide to you.

If you care about your data a lot, but still can live with a few minutes worth of
data lost in case of a disaster, you can simply use RDB alone.

There are many users using AOF alone, but we discourage this since having an
RDB snapshot from time to time is a great aid for doing database backups,
faster restarts, and in the event of bugs in the AOF engine.

Note: for all this reasons we'll likely end unifying AOF and RDB into a single
persistence model in the future (long term plan).

The following sections will illustrate a few more details about the two
persistence models.

<a name="snapshotting"></a>
Snapshotting
---

By default Redis saves snapshots of the dataset on a disk, in a binary file
called `dump.rdb`. You can configure Redis to have it save the dataset every N
seconds if at least M changes has happened to the dataset, or you can manually
call the `SAVE` or `BGSAVE` commands.

For example, this configuration will make Redis automatically dump the dataset
to disk every 60 seconds if at least 1000 keys have been changed:

    save 60 1000

This strategy is known as _snapshotting_.

### How it works

Whenever Redis needs to dump the dataset to a disk, this is what happens:

* Redis [forks](http://linux.die.net/man/2/fork). We now have a child
and a parent process.

* The child starts to write the dataset to a temporary RDB file.

* When the child is done with writing the new RDB file, it replaces the old
one.

This method allows Redis to benefit from copy-on-write semantics.

<a name="append-only-file"></a>
Append-only file
---

Snapshotting is not very durable. If your computer running Redis stops, your
power line fails, or you accidentally `kill -9` your instance, the latest data
written to Redis will be lost. While this might not be a big deal for some
applications, there are use cases where a full durability is needed, and Redis
was not a viable option in these cases.

The _append-only file_ is an alternative, fully-durable strategy for Redis. It
is available since version 1.1.

You can turn on the AOF in your configuration file with help of the following
line:

    appendonly yes

From now on, every time Redis receives a command that changes the
dataset (e.g. `SET`) it will append it to the AOF. When you restart
Redis it will re-play the AOF to rebuild the state.

### Log rewriting

As you can guess, the AOF gets bigger and bigger as write operations are
performed. For example, if you increment a counter 100 times, you'll end up
with a single key in your dataset containing the final value, but with 100
entries in your AOF. 99 of those entries are not needed to rebuild the current
state.

So Redis supports an interesting feature: it can rebuild the AOF in the
background without interrupting the service to the clients. Whenever you issue
a `BGREWRITEAOF` Redis writes the shortest sequence of commands needed to
rebuild the current dataset in the memory. If you're using the AOF with Redid
2.2 you'll need to run `BGREWRITEAOF` from time to time. Redis 2.4 provides
possibility to trigger log rewriting automatically (see the example
configuration file from a 2.4 distributive for more information).

### How durable is the append only file?

You can configure how many times Redis will
[`fsync`](http://linux.die.net/man/2/fsync) data on the disk. There are
three options:

* `fsync` every time a new command is appended to the AOF. Very very
slow, very safe.

* `fsync` every second. Fast enough (in 2.4 likely to be as fast as snapshotting), and you can loose 1 second worth of data if there is a disaster.

* Never `fsync`, just put your data in the hands of the Operating
System. The fastest and the least safe method.

The suggested (and default) policy is to `fsync` every second. It is
both very fast and pretty safe. The `always` policy is very slow in
practice (although it was improved in Redis 2.0) – there is no way to
make `fsync` faster than it is.

### What should I do if my AOF gets corrupted?

It is possible that the server would crash while writing the AOF file (this
should still never lead to any inconsistencies), corrupting the file in a
way that would no longer be loadable by Redis. Should this happen you can fix
this problem by using the following procedure:

* Make a backup copy of your AOF file.

* Fix the original file using the `redis-check-aof` tool that ships with
Redis:

      $ redis-check-aof --fix <filename>
    
* Optionally use `diff -u` to check the difference between the two files.

* Restart the server with the fixed file.

### How it works

Log rewriting uses the same copy-on-write trick already in use for
the snapshotting. This is how it works:

* Redis [forks](http://linux.die.net/man/2/fork) creating a child
and a parent process.

* The child starts writing the new AOF into a temporary file.

* The parent accumulates all the new changes in an in-memory buffer (but
at the same time it writes the new changes into the old append-only file, so if
the rewriting fails, we are still safe).

* When the child is done with rewriting the file, the parent gets a signal,
and appends the in-memory buffer at the end of the file generated by the child.

* Profit! Now Redis atomically renames the old file into the new one,
and starts to append the new data to the new file.

### How I can switch to AOF, if I'm currently using dump.rdb snapshots?

There area two different ways to do this in Redis 2.0 and Redis 2.2. As you can
guess it's simpler in Redis 2.2 and the procedure does not require a restart.

**Redis >= 2.2**

* Make a backup of your latest dump.rdb file.
* Transfer this backup into a safe place.
* Issue the following two commands:
* `redis-cli config set appendonly yes`
* `redis-cli config set save ""`
* Make sure that your database contains the same number of keys it contained
before the switch.
* Make sure that writes are being appended to the AOF correctly.

The first CONFIG command enables the Append Only File. In order to do so
**Redis blocks** generation of the initial dump, then opens the file for
writing, and starts appending all the consequent write queries.

The second CONFIG command is used to turn off the snapshotting persistence.
It's optional, if you wish you can have both the persistence methods enabled.

**IMPORTANT:** remember to edit your redis.conf to turn on the AOF, otherwise
when you restart the server the configuration changes will be lost and the
server will start again with the old configuration.

**Redis 2.0**

* Make a backup of your latest dump.rdb file.
* Transfer this backup to a safe place.
* Stop all the writes against the database!
* Issue a `redis-cli bgrewriteaof`. This will create the append only file.
* Stop the server after Redis has finished generating the AOF dump.
* Edit redis.conf end enable append only file persistence.
* Restart the server.
* Make sure that your database contains the same number of keys it contained
before the switch.
* Make sure that writes are being appended to the AOF correctly.

Interactions between AOF and RDB persistence
---

Redis >= 2.4 makes sure to avoid triggering an AOF rewrite when an RDB
snapshotting operation is already in progress, or allowing a BGSAVE while the
AOF rewrite is in progress. This prevents two Redis background processes from
doing heavy disk I/O at the same time.

When snapshotting is in progress and the user explicitly requests a log rewrite
operation using BGREWRITEAOF the server replies with an OK status code telling
the user the operation is scheduled, and the rewrite starts once the
snapshotting has been completed.

In the case both AOF and RDB persistence are enabled and Redis restarts, the
AOF file is used to reconstruct the original dataset since it is guaranteed to
be the most complete.

Backing up Redis data
---

Before starting this section, please read the following sentence: **Make Sure
to Backup Your Database**. Disks break, instances in the cloud disappear, and
so forth: no backups means huge risk of data disappearing into /dev/null.

Redis is very data backup friendly since you can copy RDB files while the
database is running: the RDB is never modified once it has been produced, and
while it gets produced it uses a temporary name and is renamed into its final
destination atomically using `rename(2)` system call only when the new snapshot
is complete.

This means that copying the RDB file is completely safe while the server is
running. This is what we suggest:

* Create a cron job on your server creating hourly snapshots of the RDB file in
one directory, and daily snapshots in a separate directory.
* Every time the cron script runs, call the `find` command to delete too old snapshots:
for instance you can take hourly snapshots for the latest 48 hours, and daily
snapshots for one or two months. Make sure to name the snapshots with date and
time information.
* At least once in a day transfer an RDB snapshot *outside your data center* or
at least *outside the physical machine* running your Redis instance.

Disaster recovery
---

Disaster recovery in the context of Redis basically boils down to the same
operations as with the daily backups, plus the requirement to transfer those
backups to several separate external data centers. If you follow the
guidelines, your data will be safe and secure even in the case of some
catastrophic event affecting the main data center where Redis is running and
producing its snapshots.

Since many Redis users are in the startup scene and thus don't have plenty of
money to spend on the disaster recovery, we'll review the most affordable
techniques.

* Amazon S3 and other similar services are a good way to have a disaster
recovery system in place. Simply transfer your daily or hourly RDB snapshots to
S3 in an encrypted form. You can encrypt your data using `gpg -c` (symmetric
encryption mode). Make sure your store the password in a separate safe place
(for instance give a copy to the most important guys in your organization). It
is recommended to use multiple storage services for improved data safety.
* Transfer your snapshots using scp (a part of the ssh package) to a
geographically distributed server. Here is a fairly simple and safe route: get
a small VPS in a place that is very far from you (in a different geographical
zone), install ssh there, upload your publish ssh key to .ssh/authorized_keys
file on your small VPS and you are ready to transfer the backups in an
automated way. Hint: get at least two VPS servers from two different providers
for the best result.

It is important to note that this system can easily fail to provide data safety
if not done the right way. At least make absolutely sure that after the
transfer has been completed you have verified the backup files on all the
servers by comparing file sizes or/and SHA1 checksums.

You also may need some kind of an independent alert system if the transfer of fresh
backups is not working for some reason.
