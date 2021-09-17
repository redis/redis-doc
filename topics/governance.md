# Redis Open Source Governance

## Introduction

Since 2009, the Redis open source project has become very successful and extremely popular.

During this time, Salvatore Sanfillipo has led, managed, and maintained the project. While contributors from Redis Ltd. and others have made significant contributions, the project never adopted a formal governance structure and de-facto was operating as a [BDFL](https://en.wikipedia.org/wiki/Benevolent_dictator_for_life)-style project.

As Redis grows, matures, and continues to expand its user base, it becomes increasingly important to  form a sustainable structure for the ongoing development and maintenance of Redis. We want to ensure the project’s continuity and reflect its larger community.

## The new governance structure, applicable from June 30, 2020

Redis has adopted a _light governance_ model that matches the current size of the project and minimizes the changes from its earlier model. The governance model is intended to be a meritocracy, aiming to empower individuals who demonstrate a long-term commitment and make significant contributions.

## The Redis core team

Salvatore Sanfilippo has stepped down as head of the project and named two successors to take over and lead the Redis project: Yossi Gottlieb ([yossigo](https://github.com/yossigo)) and Oran Agra ([oranagra](https://github.com/oranagra))

With the backing and blessing of Redis Ltd., we wish to use this opportunity and create a more open, scalable, and community-driven “core team” structure to run the project. The core team will consist of members selected based on demonstrated, long-term personal involvement and contributions.

The core team comprises of:

* Project Lead: Yossi Gottlieb ([yossigo](https://github.com/yossigo)) from Redis Ltd.
* Project Lead: Oran Agra  ([oranagra](https://github.com/oranagra)) from Redis Ltd.
* Community Lead: Itamar Haber ([itamarhaber](https://github.com/itamarhaber)) from Redis Ltd.
* Member: Zhao Zhao ([soloestoy](https://github.com/soloestoy)) from Alibaba
* Member: Madelyn Olson ([madolson](https://github.com/madolson)) from Amazon Web Services

The Redis core team members serve the Redis open source project and community. They are expected to set a good example of behavior, culture, and tone in accordance with the adopted [Code of Conduct](https://www.contributor-covenant.org/). They should also consider and act upon the best interests of the project and the community in a way that is free from foreign or conflicting interests.

The core team will be responsible for the Redis core project, which is the part of Redis that is hosted in the main Redis repository and is BSD licensed. It will also aim to maintain coordination and collaboration with other projects that make up the Redis ecosystem, including Redis clients, satellite projects, major middleware that relies on Redis, etc.

#### Roles and responsibilities of the core team

* Managing the core Redis code and documentation
* Managing new Redis releases
* Maintaining a high-level technical direction/roadmap
* Providing a fast response, including fixes/patches, to address security vulnerabilities and other major issues
* Project governance decisions and changes
* Coordination of Redis core with the rest of the Redis ecosystem
* Managing the membership of the core team

The core team will aim to form and empower a community of contributors by further delegating tasks to individuals who demonstrate commitment, know-how, and skills. In particular, we hope to see greater community involvement in the following areas:

* Support, troubleshooting, and bug fixes of reported issues
* Triage of contributions/pull requests

#### Decision making

* **Normal decisions** will be made by core team members based on a lazy consensus approach: each member may vote +1 (positive) or -1 (negative). A negative vote must include thorough reasoning and better yet, an alternative proposal. The core team will always attempt to reach a full consensus rather than a majority. Examples of normal decisions:
    * Day-to-day approval of pull requests and closing issues
    * Opening new issues for discussion
* **Major decisions** that have a significant impact on the Redis architecture, design, or philosophy as well as core-team structure or membership changes should preferably be determined by full consensus. If the team is not able to achieve a full consensus, a majority vote is required. Examples of major decisions:
    *   Fundamental changes to the Redis core
    *   Adding a new data structure
    *   The new version of RESP (Redis Serialization Protocol)
    *   Changes that affect backward compatibility
    *   Adding or changing core team members
* Project leads have a right to veto major decisions

#### Core team membership

* The core team is not expected to serve for life, however, long-term participation is desired to provide stability and consistency in the Redis programming style and the community.
* If a core-team member whose work is funded by Redis Ltd. must be replaced, the replacement will be designated by Redis Ltd. after consultation with the remaining core-team members.
* If a core-team member not funded by Redis Ltd. will no longer participate, for whatever reason, the other team members will select a replacement.

## Community forums and communications

We want the Redis community to be as welcoming and inclusive as possible. To that end, we have adopted a [Code of Conduct](https://www.contributor-covenant.org/) that we ask all community members to read and observe.

We encourage that all significant communications will be public, asynchronous, archived, and open for the community to actively participate in using the channels described [here](https://redis.io/community). The exception to that is sensitive security issues that require resolution prior to public disclosure.

For contacting the core team on sensitive matters, such as misconduct or security issues, please email [redis@redis.io](mailto:redis@redis.io).

## New Redis repository and commits approval process

The Redis core source repository is hosted under [https://github.com/redis/redis](https://github.com/redis/redis). Our target is to eventually host everything (the Redis core source and other ecosystem projects) under the Redis GitHub organization ([https://github.com/redis](https://github.com/redis)). Commits to the Redis source repository will require code review, approval of at least one core-team member who is not the author of the commit, and no objections.

## Project and development updates

Stay connected to the project and the community! For project and community updates, follow the project [channels](https://redis.io/community). Development announcements will be made via [the Redis mailing list](https://groups.google.com/forum/#!forum/redis-db).

## Updates to these governance rules

Any substantial changes to these rules will be treated as a major decision. Minor changes or ministerial corrections will be treated as normal decisions.
