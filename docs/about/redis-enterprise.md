---
title: "Redis Enterprise"
linkTitle: "Enterprise"
weight: 7
description: Learn about Redis Enterprise
aliases:

---

If building, deploying, and running open-source Redis is consuming your team’s resources and you would like to scale out your real-time apps in a cost-efficient, fully supported environment, consider trying out enterprise-level Redis implementations. Read on to learn about Redis Enterprise and the benefits of its extended offerings.

## About Redis the company

(Redis)[https://redis.com/] is the home of the OSS in-memory database platform. Redis also is a commercial provider of Redis Enterprise technology, platform, products, and services. Redis Enterprise maintains the simplicity and high performance of Redis, while adding many enterprise-grade capabilities: 

* Linear scaling to hundreds of millions of operations per second
* Improved high availability with up to 99.999% uptime
* Geo-replicated setups
* Data tiering
* Additional security features
* Several deployment options (managed cloud service, software packages, K8s)
* Additional data models via 'source code available' modules
* Enterprise-grade support

![Redis OSS vs. Redis Enterprise](/docs/about/images/comparison-oss-vs-re-circle.svg "Redis OSS vs. Redis Enterprise")

## Redis OSS vs. Redis Enterprise

Here are the key differences between open-source Redis and Redis Enterprise.

<table>
  <thead>
    <tr>
      <th>Phase</th>
      <th>Feature</th>
      <th>Open-source Redis</th>
      <th>Enterprise Redis</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan=5>Build</td>
      <td>Boost app performance with Redis cache</td>
      <td style="text-align:center">&check;</td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Support enterprise caching (read replica, write-behind, write-through)</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Build any real-time app on Redis with extended data model and processing engines support (JSON, Search, Time Series, Graph)</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Rapid development with out-of-the-box object mapping libraries for Spring, ASP.NET Core, FastAPI, and Express</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Redis UI with predefined developer guides and tools</td>
      <td style="text-align:center">&check;</td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td rowspan=3>Deploy</td>
      <td>Fully supported deployment on-premise or hybrid cloud</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Automated deployment on any cloud or multicloud</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Ingest data from external data sources with RedisConnect</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td rowspan=4>Run</td>
      <td>Deliver consistent real-time customer experience globally with geo-distributed Redis</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Automated database and cluster management (scaling, re-sharding, rebalancing)</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Built-in high-availability and disaster recovery management</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
    <tr>
      <td>Enterprise-grade customer support from the creators of Redis</td>
      <td> </td>
      <td style="text-align:center">&check;</td>
    </tr>
  </tbody>
</table>

For more information on the advantages of enterprise-level Redis, see _Redis Open Source vs. Redis Enterprise_
 [https://redis.com/wp-content/uploads/2022/06/comparison-redis-open-source-vs-redis-enterprise.pdf] (PDF).

## Redis Enterprise offerings

Redis Enterprise offers three types of implementations: 

* Self-managed options
* Fully managed options
* Hybrid deployments

### Self-managed options

#### Redis Enterprise Software (RS)

Redis Software is the cluster software, downloadable for an installation managed by you. You download, install, and manage a Redis Enterprise Software cluster wherever you like:

* IaaS cloud environments &mdash; Amazon Web Services (AWS), Google Cloud Platform (GCP), and Microsoft Azure
* On-premise servers in a private datacenter
• Physical servers, virtual machines (VMs), Kubernetes pods

#### Redis Enterprise Software deployed via Kubernetes

Redis provides a Kubernetes operator that deploys and manages a Redis Enterprise cluster. You can use the operator on premises or on a private or public cloud. You may choose a Kubernetes-based deployment:

* To simplify DevOps for internal Redis Enterprise clusters
* As part of a strategic organizational decision to adopt Kubernetes
* To integrate with applications that already run in Kubernetes

The [Google Cloud Marketplace](https://console.cloud.google.com/marketplace/product/endpoints/gcp.redisenterprise.com?pli=1&project=redislabs-university) offers Redis Enterprise as a Kubernetes app for easy deployment.

### Fully managed options

#### Redis Cloud

Redis Cloud is a Database-as-a-Service provided by Redis. The fully managed cloud service is based on Redis Enterprise and accessible via a self-service portal, which gives you access to the subscription/database control plane. Redis manages the Redis Enterprise clusters and the complexity of the underlying infrastructure, leaving most of the database management to you. This is designed to be a developer-friendly experience.

You can get started right now:

1. Navigate to [Redis Cloud Console](https://app.redislabs.com).
2. Register yourself (if not already done).
3. Select a plan (for example, the free Essentials plan).
4. Create a subscription.
5. Create a database.
6. Connect to your database endpoint via redis-cli.

Let [Support](https://redis.com/company/support/) know if you have any questions.

You can purchase and deploy Redis Enterprise Cloud directly through the cloud provider's marketplace:

* [Redis Enterprise Cloud Flexible - Pay as You Go](https://aws.amazon.com/marketplace/pp/prodview-mwscixe4ujhkq) (AWS)
* [Redis Enterprise Cloud](https://console.cloud.google.com/marketplace/product/endpoints/gcp.redisenterprise.com?project=redislabs-university) (GCP)
* [Azure Cache for Redis pricing](https://azure.microsoft.com/en-us/pricing/details/cache/#pricing) (Azure)

**NOTES:**

* Azure Cache is not managed by Redis but by Microsoft with a revenue-sharing arrangement.
* Redis provides second-level support to Microsoft customers.

### Hybrid options

If you're thinking about the Active-Active geo-distributed setup, it can combine different Redis Enterprise deployment options:

• Hybrid cloud with Active-Active &mdash; Combines self-managed on-prem clusters with Redis Cloud clusters
• Multicloud with Active-Active &mdash; Multiple fully-managed Redis Cloud clusters with a geo-replicated database across multiple cloud vendors (for example, AWS and GCP)

## Build real-time apps using Redis modules

Redis modules allow you to build real-time applications: 

* [RediSearch](https://redis.com/modules/redis-search/) adds a secondary index, a query engine, and a full-text search to Redis.
* [RedisJSON](https://redis.com/modules/redis-json/) adds native support for storing and retrieving JSON documents at the speed of Redis.
* [RedisGraph](https://redis.com/modules/redis-graph/) is a queryable property graph data structure designed for real-time use cases.
* [RedisTimeSeries](https://redis.com/modules/redis-timeseries/) adds native time-series database capabilities to Redis.
* [RedisBloom](https://redis.com/modules/redis-bloom/) adds Bloom filter, Cuckoo filter, Count-Min Sketch, and Top-K capabilities to Redis.
* [RedisGears](https://redis.com/modules/redis-gears/) is a distributed programmable engine in Redis. RedisGears makes it simple to execute server-side logic using functions, triggers, and control workflows across data-models/data-structures and shards.
* [RedisAI](https://redis.com/modules/redis-ai/) is a real-time AI inferencing/serving engine in Redis.

![Redis modules](/docs/about/images/redis-modules.svg "Redis modules")

Open-source Redis Stack [documentation](/docs/stack) provides concepts and tutorials on how to get started using Redis modules. For enterprise-level guidance, see [Redis Stack and modules](https://docs.redis.com/latest/modules/). 

## Redis tools

* [RedisInsight](https://redis.com/redis-enterprise/redis-insight/) provides a Redis admin UI that can help you optimize use of Redis in your applications. RedisInsight supports Redis OSS, Redis Stack, Redis Enterprise Software, and Redis Enterprise Cloud. It runs cross-platform on Linux, Windows, and MacOS. For open-source resources, see [RedisInsight](/docs/stack/insight/).
* [Clients and connectors](https://redis.com/redis-enterprise/clients-connectors/) &mdash; Redis Enterprise is fully compatible with Redis OSS. Any standard Redis client can be used with Redis Enterprise. Redis clients are available in over 60 programming languages and development environments.

## Support

Ask [Redis Customer Success Team](https://redis.com/deployment/customer-success/) for help with planning your project and implementation as well as maintaining and optimizing your solution. Redis Customer Success Team will work directly with you to deliver personalized account and product-lifecycle management, best practices, and expert guidance. 
## Redis University

* Gain Redis mastery. Redis multi-week courses will teach you how to build robust applications using the entire Redis feature set.
* These aren't just lectures. You'll work with Redis directly, running commands and writing code to build the fastest applications on the planet.
* Every course has an active Discord channel with instructors on-hand. You'll interact with other students and always get the answers you need quickly.

To sign up for Redis courses, see [Redis University](https://university.redis.com/)

## Learn more

* [Take control of your data with Redis Enterprise Software](https://redis.com/redis-enterprise-software/overview/)
* [Redis Backup and Restore](https://redis.com/redis-enterprise/technology/backup-disaster-recovery/)
* [Redis Enterprise Software Deployment Options](https://redis.com/redis-enterprise-software/deployment/)
* [Redis Enterprise vs. Redis Open Source: Why Make the Switch?](https://redis.com/redis-enterprise/advantages/)
* [Empowering dreamers to build real-time apps](https://redis.com/redis-enterprise-cloud/overview/)
* [Redis Enterprise Cloud: seamlessly deploy & manage your multicloud application](https://redis.com/redis-enterprise-cloud/multicloud/)
* [Take control of your data with Redis Enterprise Software](https://redis.com/redis-enterprise-software/overview/)
* [Running Redis in Kubernetes](https://redis.com/redis-enterprise-software/redis-enterprise-on-kubernetes/)
* [Introduction to Running Redis at Scale](https://developer.redis.com/operate/redis-at-scale/)
* [Operate Your Redis Database](https://developer.redis.com/operate/)
* [RedisInsight: The best Redis GUI](https://redis.com/redis-enterprise/redis-insight/)
* [A high-performance document store for modern applications](https://redis.com/modules/redis-json/)
* [Time series as a native data structure in Redis](https://redis.com/modules/redis-timeseries/)
* [Deliver search and analytics at the speed of transactions](https://redis.com/modules/redis-search/)
* [Fast graph processing powered by linear algebra and matrix multiplication](https://redis.com/modules/redis-graph/)
* [Build real-time applications with Redis modules](https://redis.com/modules/get-started/)
* [Intuitive Object Mapping and Fluent Queries for Redis](https://redis.com/blog/introducing-redis-om-client-libraries/)
* [Redis Security and Access Management: Build vs. Buy](https://redis.com/webinars-on-demand/redis-security-and-access-management-build-vs-buy/)
* [Get started with Redis Cloud, for free](https://redis.com/try-free/)
* [Download Center](https://redis.com/redis-enterprise-software/download-center/software/)
* [Redis Pricing](https://redis.com/redis-enterprise-cloud/pricing/)
* [Get started with Redis Cloud, for free](https://redis.com/try-free/)

