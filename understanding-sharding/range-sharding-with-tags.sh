MONGO_HOME=~/programs/mongodb-4.2
MONGO=$MONGO_HOME/bin/mongo
MONGOD=$MONGO_HOME/bin/mongod
MONGOS=$MONGO_HOME/bin/mongos

# When range sharding a single chunk is setup and in just a single shard
# The same shard will be written to until the inital chunk is full
$MONGO --eval "sh.enableSharding(\"test\"); sh.shardCollection("test.test",{x:1}); sh.status();"


sh.addTagRange("test.test", { x: "000000" }, { x: "bbbbbb" }, "low-shard")
sh.addTagRange("test.test", { x: "bbbbbc" }, { x: "zzzzzz" }, "high-shard")

//shard size
use config
db.settings.save( { _id:"chunksize", value:  1} )   //in MB
//check size
db.settings.find({_id:"chunksize"})
