---
title: "JSON"
linkTitle: "JSON"
weight: 30
description: >
    Introduction to RedisJSON
stack: true    
---

JSON (JavaScript Object Notation) is an open standard file and data interchange format that uses human-readable text to store and transmit data objects.

```json
{
    "model": "Hillcraft",
    "price": 1200,
    "type": ["Mountain Bikes", "Kids"],
    "specs": {
        "material": "carbon",
        "weight": "11"
    }
}
```

In the example JSON above we can see that the data object consists of **attribute–value pairs** (ex. `"model": "Hillcraft"`), arrays (`"type": ["Mountain Bikes", "Kids"]`) or other serialisable values. The attributes (`model`, `price`, `type` and `specs`) are always strings, while the values can be strings, numbers, booleans, null, objects or arrays. String, number, null or boolean values are also called **JSON scalars**.


Redis Stack implements JSON as a native data type. It allows storing, updating and fetching JSON values from Redis keys (documents) which makes it a perfect fit for a document store.

Primary features include:

- Full support of the JSON standard
- JSONPath syntax for selecting elements inside documents
- Documents are stored as binary data in a tree structure, allowing fast access to sub-elements
- Typed atomic operations for all JSON values types

The two main benefits of native JSON over using strings or hashes for storing JSON are:  
- **Access and retrieval of subvalues**: You can get nested values without having to pull the whole object out of memory, take it to the application layer, deserialize it, and serve the value you need. The overhead of this process is especially prominent for large JSON objects.  
- **Atomic partial updates**: JSON allows you to atomically run operations like incrementing a value, adding, or removing elements from an array, append strings and so on. To do the same with a serialised object you would have to pull the value out and then write the new value back, which is not atomic.


A JSONPath expression begins with the dollar sign (`$`) character, which refers to the root element of a query. The dollar sign is followed by a sequence of child elements, which are separated via dot (code) notation


Some important JSONPath syntax rules are:

|JSONPath|Description|
|---|---|
|`$` | the root object or element.|
|`@` | current object or element.|
|`.` | child operator, used to denote a child element of the current element.|
|`..` | recursive scan.|
|`*` | wildcard, returning all objects or elements regardless of their names.|
|`[]` | subscript operator / array operator|
|`,` | union operator, returns the union of the children or indexes indicated.|
|`:` | array slice operator; you can slice arrays using the syntax `[start:end:step]`.|
|`()` | lets you pass a script expression in the underlying implementation’s script language. It’s not supported by every implementation of |JSONPath, however.
|`?()` | applies a filter/script expression to query all items that meet certain criteria.|

## Examples

In the rest of this tutorial we'll work with the following example JSON document:

```
{
    "id": "B085LVV8R7",
    "name": "Hillcraft",
    "price": 1200,
    "type": ["Mountain Bikes", "Kids"],
    "specs": {
        "material": "carbon",
        "weight": "11"
    },
    "stock": [
        {
        "available_items": 573,
        "location_id": "storeYUC89",
        "location": "-9.149229, 38.731795",
        "name": "Warehouse 1" 
        },
        {
        "available_items": 110,
        "location_id": "storeBZP22",
        "location": "2.173404, 41.385063",
        "name": "Warehouse 2"  
        },
        {
        "available_items": 71,
        "location_id": "storePWB554",
        "location": "12.496365, 41.902782",
        "name": "Warehouse 3"  
        }
    ]
}
```


* Save a JSON document:

```
> JSON.SET bike:1 . '{"id":"B085LVV8R7","name":"Hillcraft","price":1200,"type":["Mountain Bikes","Kids"],"specs":{"material":"carbon","weight":"11"},"stock":[{"available_items":573,"location_id":"storeYUC89","location":"-9.149229, 38.731795","name":"Warehouse 1"},{"available_items":110,"location_id":"storeBZP22","location":"2.173404, 41.385063","name":"Warehouse 2"},{"available_items":71,"location_id":"storePWB554","location":"12.496365, 41.902782","name":"Warehouse 3"}]}'

"OK"
```

* Read the whole document:
```
> JSON.GET bike:1 $

"[{\"id\":\"B085LVV8R7\",\"name\":\"Hillcraft\",\"price\":1200,\"type\":[\"Mountain Bikes\",\"Kids\"],\"specs\":{\"material\":\"carbon\",\"weight\":\"11\"},\"stock\":[{\"available_items\":573,\"location_id\":\"storeYUC89\",\"location\":\"-9.149229, 38.731795\",\"name\":\"Warehouse 1\"},{\"available_items\":110,\"location_id\":\"storeBZP22\",\"location\":\"2.173404, 41.385063\",\"name\":\"Warehouse 2\"},{\"available_items\":71,\"location_id\":\"storePWB554\",\"location\":\"12.496365, 41.902782\",\"name\":\"Warehouse 3\"}]}]"
```

#### Get first-level elements (`$.attribute`)

To get a first-level element, you use the `$.` operator:

For example, to get the model of the bike:
```
> JSON.GET bike:1 $.id

"[\"B085LVV8R7\"]"
```

#### Get nested properties (tree traversal) (`$.parent.attribute`)

Get nested properties by following the JSON nested structure:

```
> JSON.GET bike:1 $.specs.material

"[\"carbon\"]"
```

#### Get all values for an element (`$..attribute`) 

You can get an array of all values for an element with a certain name with the `$..` notation. In our example JSON object the attribute `name` appears twice, once at top level and once in the `stock` array. With the `$..` operator we can get all of those properties in an array: 

```
> JSON.GET bike:1 $..name

"[\"Hillcraft\",\"Warehouse 1\",\"Warehouse 2\",\"Warehouse 3\"]"
```

#### Working with arrays

###### Get the whole array
```
> JSON.GET bike:1 $.stock

"[[{\"available_items\":573,\"location_id\":\"storeYUC89\",\"location\":\"-9.149229, 38.731795\",\"name\":\"Warehouse 1\"},{\"available_items\":110,\"location_id\":\"storeBZP22\",\"location\":\"2.173404, 41.385063\",\"name\":\"Warehouse 2\"},{\"available_items\":71,\"location_id\":\"storePWB554\",\"location\":\"12.496365, 41.902782\",\"name\":\"Warehouse 3\"}]]"
```

###### Get the first element of an array
```
> JSON.GET bike:1 $.stock[0]

"[{\"available_items\":573,\"location_id\":\"storeYUC89\",\"location\":\"-9.149229, 38.731795\",\"name\":\"Warehouse 1\"}]"
```

###### Get the last element of an array
```
> JSON.GET bike:1 $.stock[-1]

"[{\"available_items\":71,\"location_id\":\"storePWB554\",\"location\":\"12.496365, 41.902782\",\"name\":\"Warehouse 3\"}]"
```

###### Get an element at a specific position 
```
> JSON.GET bike:1 $.stock[1]

"[{\"available_items\":110,\"location_id\":\"storeBZP22\",\"location\":\"2.173404, 41.385063\",\"name\":\"Warehouse 2\"}]"
```

###### Get multiple elements at specific positions 
```
> JSON.GET bike:1 $.stock[0,2]

"[{\"available_items\":573,\"location_id\":\"storeYUC89\",\"location\":\"-9.149229, 38.731795\",\"name\":\"Warehouse 1\"},{\"available_items\":71,\"location_id\":\"storePWB554\",\"location\":\"12.496365, 41.902782\",\"name\":\"Warehouse 3\"}]"
```

###### Get elements in a range

Get elements of the `stock` array, starting at position 1 and ending at position 3(exclusive):

```
> JSON.GET bike:1 $.stock[1:3]

"[{\"available_items\":110,\"location_id\":\"storeBZP22\",\"location\":\"2.173404, 41.385063\",\"name\":\"Warehouse 2\"},{\"available_items\":71,\"location_id\":\"storePWB554\",\"location\":\"12.496365, 41.902782\",\"name\":\"Warehouse 3\"}]"
```


See the [complete list of JSON commands](https://redis.io/commands/?group=json).


## Limits

A JSON value passed to a command can have a depth of up to 128. If you pass to a command a JSON value that contains an object or an array with a nesting level of more than 128, the command returns an error.


## Learn more

TODO