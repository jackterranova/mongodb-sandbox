# Normalize for integrity/Denormalize for performance

As the old saying goes, 'you can have fast or accurate but not both'.


## Denormalize 

If your context can manage inconsistent data for a short period of time, denormalization is fine.  An example would be a username and a discussion forum.  If the forum post contains username then that post will show an outdated username if the username is changed.  This is generally ok even if the all of the posts with that username would need to be updated.  Having the username on a post be inconsistent for a short period would, in general, be tolerable.  

When data is denormalized/embedded, only single queries are necessary to read and write data.  It is more performant.

## Normalize 

If your context absolutely requires data integrity at all times, then normalize the data.  This will make you data consitent at all times and immediately after any updates.  But having data in multiple places will slow down both reads and writes.  

## When to Denormalize/Normalize?

How often does the data change?  If not often then denormalization is probably the best route.  Are you normalizing simply to guard against the oft chance that data might change? Most application are read heavy, so denormalization is almost always the default choice.  

How important is consistency?  Consistency is often required in the financial space.  e.g. securities that can only be traded at certain times.  Be aware of cases where consistency could be a problem.  e.g. Normalize product and orders.  Orders will contain references to products.  We want to put a product on sale for 20% starting at a specific time.  We don't want all already-executed orders to be priced at the discount. 

Do reads NEED to be fast?  If not, demormalization may work


# PREALLOCATING SPACE ================

In general if you know you're going to use/need specific fields or some specified amount of space, pre-fill or pre-allocate ahead of time.

# Create needed but currently unused fields immediately

This not only yields a clearer picture of the schema, but will ensure contiguous space is properly allocated for those fields. 

# Avoid embedded documents that will grow to large sizes over time

A large embedded document is probably fine as long as you can create it up-front.  

Slowness may be an issues when constantly appending to a large embdedded document, for which the backend will constantly be working to find space.

# PREALLOCATING SPACE ================

# Arrays vs Subdocs

Be careful about using multiple sub-doc types that you might want to query on.  For example if you stored subdocs such as `fuel:{}`, `oil:{}`, `wiperfluid:{}` and you needed to query on which reservior was running low, you wouldn't be able to in a generic way.  In such a case, you would want to store these docs as annonomous arrays => `fluids:[{type:"fuel"},{type:"oil"},{type:"wiperfluid"}]`

# Use $inc to increment number fields

`db.food.update({--},{$inc:{apples:5,bananas:2}})`  -- increment apples by 5 and bananas by 2.

# Prefer $-operators to JavaScript (JS in Mongo is really slow)

Althought JS adds a ton of flexibility to Mongo queries, they are temendously slow.  Mongo stores objects as BSON.  When using JS in `$where` for example, Mongo needs to convert BSON documents to JS objects in order to apply the `$where`.  This is flexible but really slow.  Thus, if forced to use `$where`, use on the smallest set of documents possible.  

# Mongo as the big dumb data store

Mongo is designed to do one thing: persist large amounts of data and retreieve it efficiently.  How to implement data models and modes of updates depends on how consistent you want you data (or how fast you need your data to be consistent) and how fast you need to retrieve it.  

As a result you need to be prepared to create several batch jobs depending on needs that do asynchronous consistency checking and fixing.  This is just part of the Mongo/NoSQL deal.

# _id ===================

# Use your own id and override _id when you have unique data in your model

If you have a simple unique data point in your model, use that as `_id`.

This saves significant space since Mongo has one less field to index (_id/ObjectId).

Another consideration is how random your key is.  The beauty of ObjectId's are they are always increasing and hence are always inserted in the right edge of the B-Tree.  Thus Mongo only needs to keep the right edge in memory.  

# Avoid not use documents as _id

# _id ===================

# "Database reference" type is not magical

Mongo has a db reference type which allows a reference to a document in another collection.  But this is not some magical way to do joins.  Its just a datatype that still requires a second query to get the associated data for the reference.


# Be prepared for RS failover

When a master node fails, Mongo will hold an RS election for a new master.  While this is happening, clients will get "not master" failures until the new mater is elected.  

You application may need to handle this special case

* Is it ok for errors to occur when this happens?
* Could your application fall in to a read mode during this time?

# Disk is slow, RAM is fast (duh!)

This is a fundamental law of CS but if often forgetten when designing new systems when we often spending all of our time worrying about higher level things - do we use JSON or Yaml?, do we use AWS or GCP?, do we use RDBMS or NOSql?  

Designing your system so that most used data is most often in RAM is key.   

If your application accesses data randomly thoughout its life then it will consistently be hitting disk.  But most apps don't do this - recent data is accessed more frequently than old, some users are more active than others, etc.  

# Indexes ================================

# Don't forget that indexes make write slower

Not only does the record need to be added but the index needs to updated as well.  2 physical writes are being done for each logical.  

# Avoid following index pointers to collection documents

An index record will have a ptr to the actualy collection record.  If you ask for fields that are not in the index, Mongo will always follow the ptr and load the record from the collection.  You can avoid this overhead by only asking for fields that are in the index.  If you have a use case where only a couple of fields are needed based on an index lookup, then simply add those fields to the index.

```
db.foo.ensureIndex({x:1,y:1,z:1})
...
db.foo.find({x: some-criteria, y: some-criteria), {x:1, y:1, z:1, _id:0})   -- the _id field is always returned by default and id NOT in the index
```

# Create fewer indices with multiple fields to cover multiple use cases

Compund indexes of `n' fields can still be used in cases where fewer than `n` fields are used in a query.  As long as the query includes the first `n-i` fields the index will still be used

# Hierarchical data and/or field order can obviate the need for an index 

When Mongo scans, it is scanning both items and fields within items.  When creating a hierachy in a document you are limiting the number of fields that actually need to be compared.  

For example

```
{
	name: "foo",
	title: "king foo",
	street: "bar st",
	city: "baz york city",
	zip: "12345"
}
```

`db.person.find({zip: "12345"})`

vs.

```
{
	name: "foo",
	address: {
		zip: "12345",
		street: "bar st",
		city: "baz york city"
	},
	title: "king foo"
}
```

`db.person.find({addresss.zip: "12345"})`

In the second example not only did we move the zip in to a subdoc, but we move it up in the subdoc as well.  Now Mongo can more quickly find `zip` not only because the field has been moved up in the document but there are fewer top-level fields for mongo to search. 


# Indexes ================================

# AND queries should be constructed so that the fewest trues are defined to the left
# OR queries should be constructed in the opposite manner

Given a query `a & b & c`, it is most efficient when `a` returns the fewest documents and `b` returns fewer than `c`.  This way the boolean check will stop faster and more often whenever it encounters a false value.   OR is simply the converse.

# Replication ==========================

# Journaling vs Replica Sets

Replica Sets are a measure of data safety where data is replicated to secondary hosts.  

Journaling is a replication method where a single host writes to a journal which is periodically flushed to disk.  Mongo can automatically recover in the event of a crash using the journal barring any hardware disk issues.

Replication safety can be achieved by replica sets, journaling or both.  

But realize that any type of replication requires some overhead through additional writes.  If you use both replica sets and journaling you will have mulitple writes for the number of secondaries plus the additional writes for any of the hosts that have journaling enabled.  

# Do not use data as-is after a crash

When not using journaling, even if a host comes back up after a crash and seems ok, don't use its data as-is.  It is possible that things will be fine for a while until the backend encounters a corrupt record which could wind be being very hard to diagnose.  

Should always use journaling/RS (duh).  Doing so means hosts with in-tact hardware will recover automatically on startup.

# Repair is a last resort - always rely on backup 

Mongo repair will scan all documents it can and make a "clean" copy.  This not only takes a long time but it also takes up a lot of space and it will simply skip bad records and, even worse, some fields within records.  

# fsync is slow

If you have a use case where you absolutely must ensure that your writes make it the journal, you can use `fysnc`.  `fysnc` simply pauses the write transaction until that write in the journal is actually flushed to disk.  Note that `fsync` has no effect on the flushing of the journal - it simply holds up the write until its journal companion is flushed to disk.

# Replication ==========================

# Use --notablescan in development to identify problem queries

`--notablescan` throws an error anytime a full table scan is attempted.

This can be useful in early development to ensure queries are using indexes as intended.  

Should NOT be used in production as many admin commands will do table scans and this feature will break some admin features.

# Be aware of non-acknowledged writes

By default a write to an RS is not synchronous.  This, of course, can cause consistency issues across multiple connections due to the asynchronous nature of the replication.  

By using the same connection for multiple requests, the order of the requests are guaranteed.  Additionally this is great way to read your own writes.  This is very dependent on the driver used.  


