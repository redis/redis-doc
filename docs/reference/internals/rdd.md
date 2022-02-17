---
title: "Redis design draft #2 (historical)"
linkTitle: "Redis design draft"
weight: 2
description: A design for the RDB format written in the early days of Redis
aliases:
  - /topics/rdd
  - /topics/rdd-1
  - /topics/rdd-2
---

**Note: this document was written by the creator of Redis, Salvatore Sanfilippo, early in the development of Redis (c. 2013), as part of a series of design drafts. This is preserved for historical interest.**

# Redis Design Draft 2 -- RDB version 7 info fields

* Author: Salvatore Sanfilippo `antirez@gmail.com`
* GitHub issue [#1048](https://github.com/redis/redis/issues/1048)

## History of revisions

1.0, 10 April 2013 - Initial draft.

## Overview

The Redis RDB format lacks a simple way to add info fields to an RDB file
without causing a backward compatibility issue even if the added meta data
is not required in order to load data from the RDB file.

For example thanks to the info fields specified in this document it will
be possible to add to RDB information like file creation time, Redis version
generating the file, and any other useful information, in a way that not
every field is required for an RDB version 7 file to be correctly processed.

Also with minimal changes it will be possible to add RDB version 7 support to
Redis 2.6 without actually supporting the additional fields but just skipping
them when loading an RDB file.

RDB info fields may have semantic meaning if needed, so that the presence
of the field may add information about the data set specified in the RDB
file format, however when an info field is required to be correctly decoded
in order to understand and load the data set content of the RDB file, the
RDB file format must be increased so that previous versions of Redis will not
attempt to load it.

However currently the info fields are designed to only hold additional
information that are not useful to load the dataset, but can better specify
how the RDB file was created.

## Info fields representation

The RDB format 6 has the following layout:

* A 9 bytes magic "REDIS0006"
* key-value pairs
* An EOF opcode
* CRC64 checksum

The proposal for RDB format 7 is to add the optional fields immediately
after the first 9 bytes magic, so that the new format will be:

* A 9 bytes magic "REDIS0007"
* Info field 1
* Info field 2
* ...
* Info field N
* Info field end-of-fields
* key-value pairs
* An EOF opcode
* CRC64 checksum

Every single info field has the following structure:

* A 16 bit identifier
* A 64 bit data length
* A data section of the exact length as specified

Both the identifier and the data length are stored in little endian byte
ordering.

The special identifier 0 means that there are no other info fields, and that
the remaining of the RDB file contains the key-value pairs.

## Handling of info fields

A program can simply skip every info field it does not understand, as long
as the RDB version matches the one that it is capable to load.

## Specification of info fields IDs and content.

### Info field 0 -- End of info fields

This just means there are no longer info fields to process.

### Info field 1 -- Creation date

This field represents the unix time at which the RDB file was created.
The format of the unix time is a 64 bit little endian integer representing
seconds since 1th January 1970.

### Info field 2 -- Redis version

This field represents a null-terminated string containing the Redis version
that generated the file, as displayed in the Redis version INFO field.
