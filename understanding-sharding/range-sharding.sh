MONGO_HOME=~/programs/mongodb-4.2
MONGO=$MONGO_HOME/bin/mongo
MONGOD=$MONGO_HOME/bin/mongod
MONGOS=$MONGO_HOME/bin/mongos


# setting chunk size to minimum value of 1 MB so that the chunks will fill up faster
$MONGO localhost/config --eval "db.settings.save( { _id:\"chunksize\", value:  1} ); db.settings.find({_id:\"chunksize\"});"

# When range sharding a single chunk is setup and in just a single shard
# The same shard will be written to until the inital chunk is full
$MONGO --eval "sh.enableSharding(\"test\"); sh.shardCollection(\"test.test\",{x:1}); sh.status();"
