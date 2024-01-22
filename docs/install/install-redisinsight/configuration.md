---
Title: Configure RedisInsight
date: 2024-01-30 10:00:00
weight: 60
categories: ["RI"]
path: install/install-redisinsight/configuration
altTag: Configure RedisInsight
---
You can configure RedisInsight with the following environment variables.


### RI_APP_PORT

**Description:** Port which RedisInsight should listen to.

**Type:** Number

**Default:** `5540`

**Example:** `-e RI_APP_PORT=5001`

### RI_APP_HOST

**Description:** Host which RedisInsight should listen to.

**Type:** String

**Default:** `0.0.0.0` on Docker and `127.0.0.1` on Windows, Mac, and Linux.

**Example:** `-e RI_APP_HOST=127.0.0.1`

### RI_LOG_LEVEL

**Description:** Configures the log level of the application. Possible values are - `"DEBUG"`, `"INFO"`, `"WARNING"`, `"ERROR`" and `"CRITICAL"`.

**Type:** String

**Default:** `"WARNING"`

**Example:** `-e RI_LOG_LEVEL="DEBUG"

### RI_FILES_LOGGER

**Description:** Allows to log to file.

**Type:** Boolean

**Default:** `true`

**Example:** `-e RI_FILES_LOGGER=false`

### RI_ENCRYPTION_KEY

**Description:** Enables encryption for storing sensitive information (database passwords, Workbench history, etc.) using an encryption key. <p> `Note:` Securely store the specified encryption key to be able to provide it in the future (e.g. during the startup process), otherwise RedisInsight will not be able to decrypt the information.

**Type:** String

**Default:** no defailt value

**Example:** `-e RI_ENCRYPTION_KEY=b3daa77b4c04a9551b8781d03191fe098f325e67`

### RI_SERVER_TLS_CERT

**Description:** Provides a path to a file with TLS certificate.

**Type:** String

**Default:** no defailt value

**Example:** `-e RI_SERVER_TLS_CERT="/certs/example.crt`

### RI_SERVER_TLS_KEY

**Description:** Provides a path to a file with TLS private key.

**Type:** String

**Default:** no defailt value

**Example:** `-e RI_SERVER_TLS_KEY="/certs/example.key`
