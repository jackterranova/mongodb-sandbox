## Sharding in MongoDB

This directory gives an overview of Mongo sharding and some beginner pitfalls with concrete examples.  

[Intro to Mongo sharding](SHARDING.md) for a Mongo sharding overview
[Range Sharding Example](RANGE-SHARDING.md) for a range sharding example

###  How to use this directory

There are helper scripts in this directory that will bring up a simple, local 2-shard cluster and help interact with it.

The scripts avoid Docker use as its likely the quickest and easiest way to get started - although it  bit messy.

Note that the sharding examples (linked above) may not use the scripts as the exist currently.   Also note that some of the scripts are really simple (like `show-shard-state.sh`) and, if you are new to Mongo, I would avoid using, so that you can get comfortable with running commands against Mongo.

The sharding scripts ensure the smallest chunk size possible so you can more quickly see how Mongo distributes data as chunks/shards are filled.  `insert-some-data.sh` will add just enough data to fill an entire shard, using a randomly generated shard key.

### Using the scripts

Start with `mongo-up.sh`.  This brings up a config, Mongos and 2 Mongod shards (total of 4 Mongo processes).

Check that the 4 prcesses are all running: `ps -aef | grep mongo`

Shard the the `test` collection using `range-sharding.sh` or `range-sharding-with-tags.sh`.  

Check on shard status at any time: `show-shard-state.sh`

Add some data: `insert-some-data.sh` (check shard status again `show-shard-state.sh`)  

Shut everything down with `mongo-down.sh`
