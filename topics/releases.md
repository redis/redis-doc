Redis Release Cycle
===

Redis is system software and a type of system software that holds user data, so it is among the most critical pieces of a software stack.

For this reason, Redis' release cycle is such that it ensures highly-stable releases, even at the cost of slower cycles.

New releases are published in the [Redis GitHub repository](http://github.com/redis/redis) and are also available for [download](/download).
Announcements are sent to the [Redis mailing list](http://groups.google.com/group/redis-db) and by [@redisfeed on Twitter](https://twitter.com/redisfeed).

Release Cycle
---

A given version of Redis can be at three different levels of stability:

* Unstable
* Release Candidate
* Stable

### Unstable Tree

The unstable version of Redis is located in the `unstable` branch in the [Redis GitHub repository](http://github.com/redis/redis).

This branch is the source tree where most of the new features under development.
`unstable` is not considered production-ready: it may contain critical bugs, incomplete features, and is potentially unstable features.

However, we try hard to make sure that even the unstable branch is usable most of the time in a development environment without significant issues.

### Release Candidate

New minor and major versions of Redis begin as forks of the `unstable` branch.
The forked branch's name is the target release

For example, when Redis 6.0 was released as stable, the `unstable` branch was forked into the `6.2` branch. The new branch is the release candidate (RC) for that version.

Bug fixes and new features that can be stabilized during the release's time frame are committed to the release candidate branch.
That said, the `unstable` branch may include work that is not a part of the release candidate.

The first release candidate, or RC1, is released once it can be used for development purposes and for testing the new version.
At this stage, most of the new features and changes the new version brings are ready for review, and the release's purpose is collecting the public's feedback.

Subsequent release candidates are released every three weeks or so, primarily for fixing bugs.
These may also add new features and introduce changes, but at a decreasing rate towards the final release candidate.

### Stable Tree

Once development has ended and the frequency of critical bug reports for the release candidate wanes, it is ready for the final release.

At this point, the release is marked as stable.

Versioning
---

Stable releases liberally follow the usual `major.minor.patch` semantic versioning schema.
The primary goal is to provide explicit guarantees regarding backward compatibility.

### Patch-Level Versions

Patches primarily consist of bug fixes and never introduce any compatibility issues.

Upgrading from a previous patch-level version is always safe and seamless.

New features and configuration directives may be added, or default values changed, as long as these don’t carry significant impacts or introduce operations-related issues.

### Minor Versions

Minor versions usually deliver maturity and extended functionality.

Upgrading between minor versions does not introduce any application-level compatibility issues.

Minor releases may include new commands and data types that introduce operations-related incompatibilities, including changes in data persistence format and replication protocol.

### Major Versions

Major versions introduce new capabilities and significant changes.

Ideally, these don't introduce application-level compatibility issues.

Release Schedule
---

A new major version is planned for release at the beginning of every year.

Generally, every new major release is followed by a minor version after six months.

Patches are released to fix high-urgency issues, or once a stable version accumulates enough fixes to justify it.

For contacting the core team on sensitive matters and security issues, please email [redis@redis.io](mailto:redis@redis.io).

Support
---

As a rule, older versions are not supported as we try very hard to make the Redis API mostly backward compatible.

Upgrading to newer versions is the recommended approach and is usually trivial.

The last minor version of the latest major version is fully supported.

The previous minor version of the current major version and the latest minor version of the previous major version are partially supported.

Partial support means that fixes for critical bugs and major security issues are backported.

The above are guidelines rather than rules set in stone and will not replace common sense.