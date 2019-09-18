DATADIR=/data/local-mongo
MONGO_HOME=~/programs/mongodb-4.2
MONGO=$MONGO_HOME/bin/mongo
MONGOD=$MONGO_HOME/bin/mongod
MONGOS=$MONGO_HOME/bin/mongos

# delete log files
rm *.log

# reset data dirs
rm -Rf /data/local-mongo/*
mkdir $DATADIR/config
mkdir $DATADIR/rs1
mkdir $DATADIR/rs2

# start config server on 27010
$MONGOD --port 27010 --configsvr --replSet cfg --dbpath=$DATADIR/config > config.out &
sleep 5

#start Mongos
$MONGOS -configdb cfg/localhost:27010 --port 27013 --bind_ip localhost  > mongos.out &
sleep 5

# init the replset for the config server - its still just a single node
$MONGO --port 27010 --eval "rs.initiate()"

# start shard nodes

$MONGOD --port 27011 --shardsvr --replSet rs1 --dbpath=$DATADIR/rs1 > rs1.out &
sleep 5

$MONGO --port 27011 --eval "rs.initiate()"

$MONGOD --port 27012 --shardsvr --replSet rs2 --dbpath=$DATADIR/rs2 > rs2.out &
sleep 5

$MONGO --port 27012 --eval "rs.initiate()"

# add shard nodes to the cluser
$MONGO --port 27013 --eval "sh.addShard(\"rs1/localhost:27011\"); sh.addShard(\"rs2/localhost:27012\")"
