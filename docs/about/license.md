---
title: "Redis license"
linkTitle: "License"
weight: 5
description: >
    Redis license and trademark information
aliases:
    - /topics/license
    - /docs/stack/license/
---


* Redis is source-available software, available under the terms of the RSALv2 and SSPLv1 licenses. Most of the Redis source code was written and is copyrighted by Salvatore Sanfilippo and Pieter Noordhuis. A list of other contributors can be found in the git history.

  The Redis trademark and logo are owned by Redis Ltd. and can be
used in accordance with the [Redis Trademark Guidelines](https://redis.com/legal/trademark-guidelines/).

* RedisInsight is licensed under the Server Side Public License (SSPL).

* Redis Stack Server, which combines open source Redis with Search and Query features, JSON, Time Series, and Probabilistic data structures is dual-licensed under the Redis Source Available License (RSALv2), as described below, and the [Server Side Public License](https://redis.com/legal/server-side-public-license-sspl/) (SSPL). For information about licensing per version, see [Versions and licenses](/docs/about/about-stack/#redis-stack-license).


## Licenses:

### REDIS SOURCE AVAILABLE LICENSE (RSAL) 2.0

Last updated: November 15, 2022

#### Acceptance

By using the software, you agree to all of the terms and conditions below.

#### Copyright License

The licensor grants you a non-exclusive, royalty-free, worldwide, non-sublicensable, non-transferable license to use, copy, distribute, make available, and prepare derivative works of the software, in each case subject to the limitations and conditions below.

#### Limitations

You may not make the functionality of the software or a modified version available to third parties as a service, or distribute the software or a modified version in a manner that makes the functionality of the software available to third parties. Making the functionality of the software or modified version available to third parties includes, without limitation, enabling third parties to interact with the functionality of the software or modified version in distributed form or remotely through a computer network, offering a product or service the value of which entirely or primarily derives from the value of the software or modified version, or offering a product or service that accomplishes for users the primary purpose of the software or modified version.

You may not alter, remove, or obscure any licensing, copyright, or other notices of the licensor in the software. Any use of the licensor’s trademarks is subject to applicable law.

#### Patents

The licensor grants you a license, under any patent claims the licensor can license, or becomes able to license, to make, have made, use, sell, offer for sale, import and have imported the software, in each case subject to the limitations and conditions in this license. This license does not cover any patent claims that you cause to be infringed by modifications or additions to the software. If you or your company make any written claim that the software infringes or contributes to infringement of any patent, your patent license for the software granted under these terms ends immediately. If your company makes such a claim, your patent license ends immediately for work on behalf of your company.

#### Notices

You must ensure that anyone who gets a copy of any part of the software from you also gets a copy of these terms. If you modify the software, you must include in any modified copies of the software prominent notices stating that you have modified the software.

#### No Other Rights

These terms do not imply any licenses other than those expressly granted in these terms.

#### Termination

If you use the software in violation of these terms, such use is not licensed, and your licenses will automatically terminate. If the licensor provides you with a notice of your violation, and you cease all violations of this license no later than 30 days after you receive that notice, your licenses will be reinstated retroactively. However, if you violate these terms after such reinstatement, any additional violation of these terms will cause your licenses to terminate automatically and permanently.

#### No Liability

As far as the law allows, the software comes as is, without any warranty or condition, and the licensor will not be liable to you for any damages arising out of these terms or the use or nature of the software, under any kind of legal claim.

#### Definitions

The licensor is the entity offering these terms, and the software is the software the licensor makes available under these terms, including any portion of it.

To modify a work means to copy from or adapt all or part of the work in a fashion requiring copyright permission other than making an exact copy. The resulting work is called a modified version of the earlier work.

**you** refers to the individual or entity agreeing to these terms.

**your company** is any legal entity, sole proprietorship, or other kind of organization that you work for, plus all organizations that have control over, are under the control of, or are under common control with that organization.

**control** means ownership of substantially all the assets of an entity, or the power to direct its management and policies by vote, contract, or otherwise. Control can be direct or indirect.

**your licenses** are all the licenses granted to you for the software under these terms. 

**use** means anything you do with the software requiring one of your licenses.

**trademark** means trademarks, service marks, and similar rights.

#### Third-party files and licenses

Redis uses source code from third parties. All this code contains a BSD or BSD-compatible license. The following is a list of third-party files and information about their copyright.

* Redis uses the [LHF compression library](http://oldhome.schmorp.de/marc/liblzf.html). LibLZF is copyright Marc Alexander Lehmann and is released under the terms of the two-clause BSD license.

* Redis uses the sha1.c file that is copyright by Steve Reid and released under the public domain. This file is extremely popular and used among open source and proprietary code.

* When compiled on Linux, Redis uses the [Jemalloc allocator](https://github.com/jemalloc/jemalloc), which is copyrighted by Jason Evans, Mozilla Foundation, and Facebook, Inc and released under the two-clause BSD license.

* Inside Jemalloc, the file pprof is copyrighted by Google Inc. and released under the three-clause BSD license.

* Inside Jemalloc the files inttypes.h, stdbool.h, stdint.h, strings.h under the msvc_compat directory are copyright Alexander Chemeris and released under the three-clause BSD license.

* The libraries hiredis and linenoise also included inside the Redis distribution are copyright Salvatore Sanfilippo and Pieter Noordhuis and released under the terms respectively of the three-clause BSD license and two-clause BSD license.