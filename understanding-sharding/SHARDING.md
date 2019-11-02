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


