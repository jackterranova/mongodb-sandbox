## Sharding 

Sharding is a method of data paritioning that is intended to evenly distribute data in a distributed data storage system.  Sharding allows for massive horizontal scaling which is key to dealing with large (or even "Big") data.

## Sharding in MongoDB

In MongDB, a shard is typically (though not exlusively) a physical (or virtual) host that holds a portion of a collection's data.  

This allows for a truly distributed modern scalability.  Not only does this serve the purpose of performance of large data systems, it also allows for the geographic distribution of data, keeping data phyically near its typical consumer.  

MongDB achieves sharding via a shard key, a field or group of fields, that serve as a method of mapping documents to physical shards and may also serve as a primary document identifier.   For example, a shard key may be as simple as MongoDB's `_id` field - a surrogate primary key or it could be a combination of the document's field which may or may not uniquely identify the document.  An example of a non-pk shard key would be zip code.   A shard key of zip code would distribute documents by their zip code, but documents with the same zip would obviouly be in the same shard together.  This can cause a poor distribution of data IF the data itself does not represnet a good distribution of zip codes.  

MongoDB supports 2 types of sharding: `range sharding` and `hash sharding`.  

In `range sharding`, documents are placed in ranges inside data chunks which are distributed across shards.  A `balancer` is used to make sure chunks are balanced as best as possible, creating and splitting chunks and moving documents between them.   

The MongoDB documentation briefly touches on what makes a good shard key.   Generally a shard key should have a high cardinality (e.g. a completely unique set of data will have a cardinality equal to the number of items in the set) and should also change in a random fashion (it should not be monotomically inscreasing or decreasing like an Oracle sequence, for example).  If a selected shard key allows for frequent duplicates then you risk ending up with unblanced shards as duplicates will wind up on the same shard togther.  Even if the shard key is unique, it should not change in some type of inscreasing or decreasing pattern as the shards will be populated one at a time as chunks/shards are filled by incoming data.  

MongoDB documentation does NOT go in to great length about choosing a shard key.  But you may find yourself suprised (as I was) when first working with range sharding.  I went in assuming a random shard key would work well without a lot of (ok, without any) planning.  

## Range Sharding Demo

This is a really basic demo of how range sharding works in MongoDB, using MongoDB 4.2.  

The demo is bare bones (no use of Docker or any VMs) and uses a simple 2 shard cluster, single config server and single mongos with no replication.  

After the 4 mongo components are brought up, we create the 2 shards by connecting to Mongos ...

```
sh.addShard("rs1/localhost:27011"); 
sh.addShard("rs2/localhost:27012")
```

We set a very small global chunk size so we can more quickly see how the balancer will move data across the shards and reconfigure the chunk(s) ...

```
# create a 1MB chunksize (the smallest possible chunk size)
db.settings.save( { _id:"chunksize", value:  1} )

# confirm the chunksize
db.settings.find({_id:"chunksize"});
```

Create a `test` db and range shard it on some random field `x`

```bash
sh.enableSharding("test")
sh.shardCollection("test.test",{x:1})
sh.status()
```

Let's look at what the sharding looks like at the start.  


```bash
sh.status()

```


```json
--- Sharding Status --- 
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("5d8f8930a76645a15dd91245")
  }
  shards:
        {  "_id" : "rs1",  "host" : "rs1/localhost:27011",  "state" : 1 }
        {  "_id" : "rs2",  "host" : "rs2/localhost:27012",  "state" : 1 }
  active mongoses:
        "4.2.0" : 1
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours: 
                1 : Success
  databases:
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
                config.system.sessions
                        shard key: { "_id" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                rs1	1
                        { "_id" : { "$minKey" : 1 } } -->> { "_id" : { "$maxKey" : 1 } } on : rs1 Timestamp(1, 0) 
        {  "_id" : "test",  "primary" : "rs1",  "partitioned" : true,  "version" : {  "uuid" : UUID("2d88528b-55ab-451c-b168-901baa9507c2"),  "lastMod" : 1 } }
                test.test
                        shard key: { "x" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                rs1	1
                        { "x" : { "$minKey" : 1 } } -->> { "x" : { "$maxKey" : 1 } } on : rs1 Timestamp(1, 0) 
```

We can see the `test.test` currently has a single chunk residing on shard `rs1` =>  `{ "x" : { "$minKey" : 1 } } -->> { "x" : { "$maxKey" : 1 } } on : rs1 Timestamp(1, 0)`.   

This makes sense as MongoDB knows nothing about the shard key except its name.   Since we are not hashing the value, MongoDB simply creates a single chunk and it spans only one shard.  

Let's take a look at the shard distrbution

```bash
db.test.getShardDistribution()
```

```json
MongoDB shell version v4.2.0
connecting to: mongodb://localhost:27013/test?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("6693e899-4d87-47cd-8723-58013e5e5426") }
MongoDB server version: 4.2.0

Shard rs1 at rs1/localhost:27011
 data : 0B docs : 0 chunks : 1
 estimated data per chunk : 0B
 estimated docs per chunk : 0

Totals
 data : 0B docs : 0 chunks : 1
 Shard rs1 contains 0% data, 0% docs in cluster, avg obj size on shard : 0B
```


```
MongoDB shell version v4.2.0
connecting to: mongodb://localhost:27013/test?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("6693e899-4d87-47cd-8723-58013e5e5426") }
MongoDB server version: 4.2.0

Shard rs1 at rs1/localhost:27011
 data : 0B docs : 0 chunks : 1
 estimated data per chunk : 0B
 estimated docs per chunk : 0

Totals
 data : 0B docs : 0 chunks : 1
 Shard rs1 contains 0% data, 0% docs in cluster, avg obj size on shard : 0B
```

We have no data yet so all we see is no documents and a single chunk on shard rs1.

`Shard rs1 at rs1/localhost:27011` 
`docs: 0`  
`chunks: 1` 


Let's start adding some data using the following js code

```
var randomName = function() {
  // Base 36 uses letters and digits to represent a number
  // substring to only 6 chars
  return (Math.random()+1).toString(36).substring(2,8)
}

// adding about 200 bytes each time
// adding random data with some field y so that can eat up chunk space more quickly
for (var i = 0; i <= 5000; ++i) {
  db.test.insert({
      x: randomName(),
      y: "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  });
}

```

The `randomName` function generates 6 character random strings.  Should be a decent shard key.

Checking the shard status now 

```
--- Sharding Status --- 
  sharding version: {
  	"_id" : 1,
  	"minCompatibleVersion" : 5,
  	"currentVersion" : 6,
  	"clusterId" : ObjectId("5d8f8930a76645a15dd91245")
  }
  shards:
        {  "_id" : "rs1",  "host" : "rs1/localhost:27011",  "state" : 1 }
        {  "_id" : "rs2",  "host" : "rs2/localhost:27012",  "state" : 1 }
  active mongoses:
        "4.2.0" : 1
  autosplit:
        Currently enabled: yes
  balancer:
        Currently enabled:  yes
        Currently running:  no
        Failed balancer rounds in last 5 attempts:  0
        Migration Results for the last 24 hours: 
                1 : Success
  databases:
        {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
                config.system.sessions
                        shard key: { "_id" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                rs1	1
                        { "_id" : { "$minKey" : 1 } } -->> { "_id" : { "$maxKey" : 1 } } on : rs1 Timestamp(1, 0) 
        {  "_id" : "test",  "primary" : "rs1",  "partitioned" : true,  "version" : {  "uuid" : UUID("2d88528b-55ab-451c-b168-901baa9507c2"),  "lastMod" : 1 } }
                test.test
                        shard key: { "x" : 1 }
                        unique: false
                        balancing: true
                        chunks:
                                rs1	2
                                rs2	1
                        { "x" : { "$minKey" : 1 } } -->> { "x" : "00ikbe" } on : rs2 Timestamp(2, 0) 
                        { "x" : "00ikbe" } -->> { "x" : "zxd14k" } on : rs1 Timestamp(2, 1) 
                        { "x" : "zxd14k" } -->> { "x" : { "$maxKey" : 1 } } on : rs1 Timestamp(1, 3) 
```

And the shard distribution ...


```
MongoDB shell version v4.2.0
connecting to: mongodb://localhost:27013/test?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("54888370-8328-4e31-b71a-cb161135e264") }
MongoDB server version: 4.2.0

Shard rs1 at rs1/localhost:27011
 data : 1.16MiB docs : 4999 chunks : 2
 estimated data per chunk : 595KiB
 estimated docs per chunk : 2499

Shard rs2 at rs2/localhost:27012
 data : 488B docs : 2 chunks : 1
 estimated data per chunk : 488B
 estimated docs per chunk : 2

Totals
 data : 1.16MiB docs : 5001 chunks : 3
 Shard rs1 contains 99.96% data, 99.96% docs in cluster, avg obj size on shard : 244B
 Shard rs2 contains 0.03% data, 0.03% docs in cluster, avg obj size on shard : 244B
```

Pretty big difference.  
