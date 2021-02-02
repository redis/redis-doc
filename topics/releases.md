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
`unstable` is not considered production-ready: it may contain critical bugs, incomplete features, and is potentially unstable.

However, we try hard to make sure that even the unstable branch is usable most of the time in a development environment without significant issues.

### Release Candidate

New minor and major versions of Redis begin as forks of the `unstable` branch.
The forked branch's name is the target release

For example, when Redis 6.0 was released as a release candidate, the `unstable` branch was forked into the `6.0` branch. The new branch is the release candidate (RC) for that version.

Bug fixes and new features that can be stabilized during the release's time frame are committed to the unstable branch and backported to the release candidate branch.
The `unstable` branch may include additional work that is not a part of the release candidate and scheduled for future releases.

The first release candidate, or RC1, is released once it can be used for development purposes and for testing the new version.
At this stage, most of the new features and changes the new version brings are ready for review, and the release's purpose is collecting the public's feedback.

Subsequent release candidates are released every three weeks or so, primarily for fixing bugs.
These may also add new features and introduce changes, but at a decreasing rate and decreasing potential risk towards the final release candidate.

### Stable Tree

Once development has ended and the frequency of critical bug reports for the release candidate wanes, it is ready for the final release.
At this point, the release is marked as stable and is released with "0" as its patch-level version.

Versioning
---

Stable releases liberally follow the usual `major.minor.patch` semantic versioning schema.
The primary goal is to provide explicit guarantees regarding backward compatibility.

### Patch-Level Versions

Patches primarily consist of bug fixes and very rarely introduce any compatibility issues.

Upgrading from a previous patch-level version is almost always safe and seamless.

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

A new major version is planned for release once a year.

Generally, every major release is followed by a minor version after six months.

Patches are released as needed to fix high-urgency issues, or once a stable version accumulates enough fixes to justify it.

For contacting the core team on sensitive matters and security issues, please email [redis@redis.io](mailto:redis@redis.io).

Support
---

As a rule, older versions are not supported as we try very hard to make the Redis API mostly backward compatible.

Upgrading to newer versions is the recommended approach and is usually trivial.

The latest stable release is always fully supported and maintained.

Two additional versions receive maintenance only, meaning that only fixes for critical bugs and major security issues are committed and released as patches:

* The previous minor version of the latest stable release.
* The previous stable major release.
 
For example, consider the following hypothetical versions: 1.2, 2.0, 2.2, 3.0, 3.2, ...

When version 2.2 is the latest stable release, both 2.0 and 1.2 are maintained.

Once version 3.0.0 replaces 2.2 as the latest stable, versions 2.0 and 2.2 are maintained, whereas version 1.x reaches its end of life.

This process repeats with version 3.2.0, after which only versions 2.2 and 3.0 are maintained.

The above are guidelines rather than rules set in stone and will not replace common sense.
