## Range Sharding Demo

This is a really basic demo of how range sharding works in MongoDB, using MongoDB 4.2.  

The demo is bare bones (no use of Docker or any VMs) and uses a simple 2 shard cluster, single config server and single mongos with no replication.  

__One of the big beginner pitfalls was an assumption that shards would be immediately balanced as new records were added.__ Hint: WRONG!

Mongo documentation and blog after blog will talk about how to create a good shard key and how that should lead to balanced shards.  So I simply plowed ahead and created a demo using tagless range sharding that would add records with random shard keys.  To my surprise and frustration, every record was initally just added to the first shard.  Mongo was making no attempt to distribute the incoming shard keys.  I then evolved the demo to attempt to fill up the first shard.  Then things started making sense.  Mongo started adding records to the second shard, and checking on the shard distribution, Mongo had automatically created shard tags for the 2 shards.  Now Mongo was *beginning* to write to both shards.  But the distribution was still 99% on shard 1 and 1% on shard 2.  

This highlights the danger of going with non-hashed sharding.  You simply can't expect Mongo to efficiently distribute shard keys on its own by analysing them as they are written.  Even when using tags to help Mongo distribute the incoming data, you're data may not come in the order and magnitude you expect, and you still may end up with unbalanced shards.   

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
connecting to: mongodb://localhost:27017/test?compressors=disabled&gssapiServiceName=mongodb
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
connecting to: mongodb://localhost:27017/test?compressors=disabled&gssapiServiceName=mongodb
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
connecting to: mongodb://localhost:27017/test?compressors=disabled&gssapiServiceName=mongodb
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

Mongo does not have a built-in magic wand.  Clearly, Mongo needs some help from you to understand your choice of shard key.  
