DATADIR=/data/local-mongo
MONGO_HOME=~/programs/mongodb-4.2
MONGO=$MONGO_HOME/bin/mongo
MONGOD=$MONGO_HOME/bin/mongod
MONGOS=$MONGO_HOME/bin/mongos

# Per Mongo documentation ...
# 27017 The default port for mongod and mongos instances.
# 27018 The default port for mongod when running with --shardsvr 
# 27019 The default port for mongod when running with --configsvr
MONGOS_PORT=27017
CONFIG_SERVER_PORT=27019
SHARD_SERVER1_PORT=27011
SHARD_SERVER2_PORT=27012


# delete log files
rm *.log

# reset data dirs
rm -Rf /data/local-mongo/*
mkdir $DATADIR/config
mkdir $DATADIR/rs1
mkdir $DATADIR/rs2

# start config server 
$MONGOD --port $CONFIG_SERVER_PORT --configsvr --replSet cfg --dbpath=$DATADIR/config > config.out &
sleep 5

#start Mongos
$MONGOS -configdb cfg/localhost:$CONFIG_SERVER_PORT --port $MONGOS_PORT --bind_ip localhost  > mongos.out &
sleep 5

# init the replset for the config server - its still just a single node
$MONGO --port $CONFIG_SERVER_PORT --eval "rs.initiate()"

# start shard nodes
$MONGOD --port $SHARD_SERVER1_PORT --shardsvr --replSet rs1 --dbpath=$DATADIR/rs1 > rs1.out &
sleep 5

$MONGO --port $SHARD_SERVER1_PORT --eval "rs.initiate()"

$MONGOD --port $SHARD_SERVER2_PORT --shardsvr --replSet rs2 --dbpath=$DATADIR/rs2 > rs2.out &
sleep 5

$MONGO --port $SHARD_SERVER2_PORT --eval "rs.initiate()"

# add shard nodes to the cluser
$MONGO --port $MONGOS_PORT --eval "sh.addShard(\"rs1/localhost:${SHARD_SERVER1_PORT}\"); sh.addShard(\"rs2/localhost:${SHARD_SERVER2_PORT}\")"
