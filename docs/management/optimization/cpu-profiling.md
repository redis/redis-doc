---
title: "Redis CPU profiling"
linkTitle: "CPU profiling"
weight: 1
description: >
    Performance engineering guide for on-CPU profiling and tracing
aliases: [
    /topics/performance-on-cpu,
    /docs/reference/optimization/cpu-profiling
]
---

## Filling the performance checklist

Redis is developed with a great emphasis on performance. We do our best with
every release to make sure you'll experience a very stable and fast product. 

Nevertheless, if you're finding room to improve the efficiency of Redis or
are pursuing a performance regression investigation you will need a concise
methodical way of monitoring and analyzing Redis performance. 

To do so you can rely on different methodologies (some more suited than other 
depending on the class of issues/analysis we intend to make). A curated list
of methodologies and their steps are enumerated by Brendan Greg at the
[following link](http://www.brendangregg.com/methodology.html). 

We recommend the Utilization Saturation and Errors (USE) Method for answering
the question of what is your bottleneck. Check the following mapping between
system resource, metric, and tools for a practical deep dive:
[USE method](http://www.brendangregg.com/USEmethod/use-rosetta.html). 

### Ensuring the CPU is your bottleneck

This guide assumes you've followed one of the above methodologies to perform a 
complete check of system health, and identified the bottleneck being the CPU. 
**If you have identified that most of the time is spent blocked on I/O, locks,
timers, paging/swapping, etc., this guide is not for you**. 

### Build Prerequisites

For a proper On-CPU analysis, Redis (and any dynamically loaded library like
Redis Modules) requires stack traces to be available to tracers, which you may
need to fix first. 

By default, Redis is compiled with the `-O2` switch (which we intent to keep
during profiling). This means that compiler optimizations are enabled. Many
compilers omit the frame pointer as a runtime optimization (saving a register),
thus breaking frame pointer-based stack walking. This makes the Redis
executable faster, but at the same time it makes Redis (like any other program)
harder to trace, potentially wrongfully pinpointing on-CPU time to the last
available frame pointer of a call stack that can get a lot deeper (but
impossible to trace).

It's important that you ensure that:
- debug information is present: compile option `-g`
- frame pointer register is present: `-fno-omit-frame-pointer`
- we still run with optimizations to get an accurate representation of production run times, meaning we will keep: `-O2`

You can do it as follows within redis main repo:

    $ make REDIS_CFLAGS="-g -fno-omit-frame-pointer"

## A set of instruments to identify performance regressions and/or potential **on-CPU performance** improvements 

This document focuses specifically on **on-CPU** resource bottlenecks analysis,
meaning we're interested in understanding where threads are spending CPU cycles
while running on-CPU and, as importantly, whether those cycles are effectively
being used for computation or stalled waiting (not blocked!) for memory I/O,
and cache misses, etc.

For that we will rely on toolkits (perf, bcc tools), and hardware specific PMCs
(Performance Monitoring Counters), to proceed with:

- Hotspot analysis (perf or bcc tools): to profile code execution and determine which functions are consuming the most time and thus are targets for optimization. We'll present two options to collect, report, and visualize hotspots either with perf or bcc/BPF tracing tools.

- Call counts analysis: to count events including function calls, enabling us to correlate several calls/components at once, relying on bcc/BPF tracing tools.

- Hardware event sampling: crucial for understanding CPU behavior, including memory I/O, stall cycles, and cache misses.

### Tool prerequisites

The following steps rely on Linux perf_events (aka ["perf"](https://man7.org/linux/man-pages/man1/perf.1.html)), [bcc/BPF tracing tools](https://github.com/iovisor/bcc), and Brendan Greg’s [FlameGraph repo](https://github.com/brendangregg/FlameGraph).

We assume beforehand you have:

- Installed the perf tool on your system. Most Linux distributions will likely package this as a package related to the kernel. More information about the perf tool can be found at perf [wiki](https://perf.wiki.kernel.org/).
- Followed the install [bcc/BPF](https://github.com/iovisor/bcc/blob/master/INSTALL.md#installing-bcc) instructions to install bcc toolkit on your machine.
- Cloned Brendan Greg’s [FlameGraph repo](https://github.com/brendangregg/FlameGraph) and made accessible the `difffolded.pl` and `flamegraph.pl` files, to generated the collapsed stack traces and Flame Graphs.

## Hotspot analysis with perf or eBPF (stack traces sampling)

Profiling CPU usage by sampling stack traces at a timed interval is a fast and
easy way to identify performance-critical code sections (hotspots).

### Sampling stack traces using perf

To profile both user- and kernel-level stacks of redis-server for a specific
length of time, for example 60 seconds, at a sampling frequency of 999 samples
per second:

    $ perf record -g --pid $(pgrep redis-server) -F 999 -- sleep 60

#### Displaying the recorded profile information using perf report

By default perf record will generate a perf.data file in the current working
directory. 

You can then report with a call-graph output (call chain, stack backtrace),
with a minimum call graph inclusion threshold of 0.5%, with:

    $ perf report -g "graph,0.5,caller"

See the [perf report](https://man7.org/linux/man-pages/man1/perf-report.1.html)
documentation for advanced filtering, sorting and aggregation capabilities.

#### Visualizing the recorded profile information using Flame Graphs

[Flame graphs](http://www.brendangregg.com/flamegraphs.html) allow for a quick
and accurate visualization of frequent code-paths. They can be generated using
Brendan Greg's open source programs on [github](https://github.com/brendangregg/FlameGraph),
which create interactive SVGs from folded stack files.

Specifically, for perf we need to convert the generated perf.data into the
captured stacks, and fold each of them into single lines. You can then render
the on-CPU flame graph with:

    $ perf script > redis.perf.stacks
    $ stackcollapse-perf.pl redis.perf.stacks > redis.folded.stacks
    $ flamegraph.pl redis.folded.stacks > redis.svg

By default, perf script will generate a perf.data file in the current working
directory. See the [perf script](https://linux.die.net/man/1/perf-script)
documentation for advanced usage.

See [FlameGraph usage options](https://github.com/brendangregg/FlameGraph#options)
for more advanced stack trace visualizations (like the differential one).

#### Archiving and sharing recorded profile information

So that analysis of the perf.data contents can be possible on a machine other
than the one on which collection happened, you need to export along with the
perf.data file all object files with build-ids found in the record data file.
This can be easily done with the help of 
[perf-archive.sh](https://github.com/torvalds/linux/blob/master/tools/perf/perf-archive.sh)
script:

    $ perf-archive.sh perf.data

Now please run:

    $ tar xvf perf.data.tar.bz2 -C ~/.debug

on the machine where you need to run `perf report`.

### Sampling stack traces using bcc/BPF's profile
    
Similarly to perf, as of Linux kernel 4.9, BPF-optimized profiling is now fully
available with the promise of lower overhead on CPU (as stack traces are
frequency counted in kernel context) and disk I/O resources during profiling. 

Apart from that, and relying solely on bcc/BPF's profile tool, we have also
removed the perf.data and intermediate steps if stack traces analysis is our
main goal. You can use bcc's profile tool to output folded format directly, for
flame graph generation:

    $ /usr/share/bcc/tools/profile -F 999 -f --pid $(pgrep redis-server) --duration 60 > redis.folded.stacks

In that manner, we've remove any preprocessing and can render the on-CPU flame
graph with a single command:

    $ flamegraph.pl redis.folded.stacks > redis.svg

### Visualizing the recorded profile information using Flame Graphs

## Call counts analysis with bcc/BPF

A function may consume significant CPU cycles either because its code is slow
or because it's frequently called. To answer at what rate functions are being
called, you can rely upon call counts analysis using BCC's `funccount` tool:

    $ /usr/share/bcc/tools/funccount 'redis-server:(call*|*Read*|*Write*)' --pid $(pgrep redis-server) --duration 60
    Tracing 64 functions for "redis-server:(call*|*Read*|*Write*)"... Hit Ctrl-C to end.

    FUNC                                    COUNT
    call                                      334
    handleClientsWithPendingWrites            388
    clientInstallWriteHandler                 388
    postponeClientRead                        514
    handleClientsWithPendingReadsUsingThreads      735
    handleClientsWithPendingWritesUsingThreads      735
    prepareClientToWrite                     1442
    Detaching...


The above output shows that, while tracing, the Redis's call() function was
called 334 times, handleClientsWithPendingWrites() 388 times, etc.

## Hardware event counting with Performance Monitoring Counters (PMCs)

Many modern processors contain a performance monitoring unit (PMU) exposing
Performance Monitoring Counters (PMCs). PMCs are crucial for understanding CPU
behavior, including memory I/O, stall cycles, and cache misses, and provide
low-level CPU performance statistics that aren't available anywhere else.

The design and functionality of a PMU is CPU-specific and you should assess
your CPU supported counters and features by using `perf list`. 

To calculate the number of instructions per cycle, the number of micro ops
executed, the number of cycles during which no micro ops were dispatched, the
number stalled cycles on memory, including a per memory type stalls, for the
duration of 60s, specifically for redis process: 

    $ perf stat -e "cpu-clock,cpu-cycles,instructions,uops_executed.core,uops_executed.stall_cycles,cache-references,cache-misses,cycle_activity.stalls_total,cycle_activity.stalls_mem_any,cycle_activity.stalls_l3_miss,cycle_activity.stalls_l2_miss,cycle_activity.stalls_l1d_miss" --pid $(pgrep redis-server) -- sleep 60

    Performance counter stats for process id '3038':

      60046.411437      cpu-clock (msec)          #    1.001 CPUs utilized          
      168991975443      cpu-cycles                #    2.814 GHz                      (36.40%)
      388248178431      instructions              #    2.30  insn per cycle           (45.50%)
      443134227322      uops_executed.core        # 7379.862 M/sec                    (45.51%)
       30317116399      uops_executed.stall_cycles #  504.895 M/sec                    (45.51%)
         670821512      cache-references          #   11.172 M/sec                    (45.52%)
          23727619      cache-misses              #    3.537 % of all cache refs      (45.43%)
       30278479141      cycle_activity.stalls_total #  504.251 M/sec                    (36.33%)
       19981138777      cycle_activity.stalls_mem_any #  332.762 M/sec                    (36.33%)
         725708324      cycle_activity.stalls_l3_miss #   12.086 M/sec                    (36.33%)
        8487905659      cycle_activity.stalls_l2_miss #  141.356 M/sec                    (36.32%)
       10011909368      cycle_activity.stalls_l1d_miss #  166.736 M/sec                    (36.31%)

      60.002765665 seconds time elapsed

It's important to know that there are two very different ways in which PMCs can
be used (counting and sampling), and we've focused solely on PMCs counting for
the sake of this analysis. Brendan Greg clearly explains it on the following
[link](http://www.brendangregg.com/blog/2017-05-04/the-pmcs-of-ec2.html).

