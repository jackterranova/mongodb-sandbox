MONGO_HOME=~/programs/mongodb-4.2
MONGO=$MONGO_HOME/bin/mongo
MONGOD=$MONGO_HOME/bin/mongod
MONGOS=$MONGO_HOME/bin/mongos

$MONGO localhost:27013/test --eval "db.test.getShardDistribution();  sh.status()"
