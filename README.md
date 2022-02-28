## Overview

This is a simple Sinatra app (mostly copied from [the tutorial](https://docs.mongodb.com/mongoid/current/tutorials/getting-started-sinatra/)) using Unicorn in front of it, with Mongoid.

## Reproduce steps

1. Boot up mongodb and ruby app by running `docker-compose up`
2. Make sure mongodb and ruby app are up and running:

```
mongo_1    | 2022-02-28T18:17:19.979+0000 I  NETWORK  [listener] Listening on /tmp/mongodb-27017.sock
mongo_1    | 2022-02-28T18:17:19.980+0000 I  NETWORK  [listener] Listening on 0.0.0.0
mongo_1    | 2022-02-28T18:17:19.980+0000 I  NETWORK  [listener] waiting for connections on port 27017

postapp_1  | I, [2022-02-28T18:17:20.710500 #8]  INFO -- : listening on addr=0.0.0.0:4567 fd=8
postapp_1  | I, [2022-02-28T18:17:20.711519 #8]  INFO -- : master process ready
postapp_1  | I, [2022-02-28T18:17:20.711997 #9]  INFO -- : worker=0 ready
```

3. Open up a separate terminal
4. Run `curl` to make sure the app is up and running. Below, there was no connection to the database yet, so the `Mongoid::Clients.clients` is empty

```
$ curl localhost:4567
Clients info: {}
```

5. Create a new post and use the default mongoid client. This will open up 2 new connections based on the mongodb log

```
$ curl localhost:4567/posts -d 'post[title]=hello&post[body]=hello+world'
```

```
mongo_1    | 2022-02-28T18:40:47.560+0000 I  NETWORK  [listener] connection accepted from 172.20.0.3:54818 #1 (1 connection now open)
mongo_1    | 2022-02-28T18:40:47.561+0000 I  NETWORK  [conn1] received client metadata from 172.20.0.3:54818 conn1: { driver: { name: "mongo-ruby-driver|Mongoid", version: "2.17.0|7.3.4" }, os: { type: "linux", name: "linux", architecture: "aarch64" }, platform: "mongoid-7.3.4, Ruby 2.7.4, aarch64-linux, aarch64-unknown-linux-gnu, M|" }
mongo_1    | 2022-02-28T18:40:47.565+0000 I  NETWORK  [listener] connection accepted from 172.20.0.3:54820 #2 (2 connections now open)
mongo_1    | 2022-02-28T18:40:47.566+0000 I  NETWORK  [conn2] received client metadata from 172.20.0.3:54820 conn2: { driver: { name: "mongo-ruby-driver|Mongoid", version: "2.17.0|7.3.4" }, os: { type: "linux", name: "linux", architecture: "aarch64" }, platform: "mongoid-7.3.4, Ruby 2.7.4, aarch64-linux, aarch64-unknown-linux-gnu, A|" }
```

6. Make sure that there is a default client defined now

```
$ curl localhost:4567
Clients info: {:default=>#<Mongo::Client:0x2640 cluster=#<Cluster topology=Single[mongo:27017] servers=[#<Server address=mongo:27017 STANDALONE pool=#<ConnectionPool size=1 (0-5) used=0 avail=1 pending=0>>]>>}
```

7. Get the list of the post, which will use the client called `secondary`. This will open up 2 new connections based on the mongodb log (based on the `secondary` definition), then closes these 2 connections at the end (Runtime Persistence behavior)

```
$ curl localhost:4567/posts
[{"_id":{"$oid":"621d14f432e5b000098b59a9"},"body":"hello world","title":"hello"}]
```

```
mongo_1    | 2022-02-28T18:42:01.173+0000 I  NETWORK  [listener] connection accepted from 172.20.0.3:54854 #3 (3 connections now open)
mongo_1    | 2022-02-28T18:42:01.174+0000 I  NETWORK  [conn3] received client metadata from 172.20.0.3:54854 conn3: { driver: { name: "mongo-ruby-driver|Mongoid", version: "2.17.0|7.3.4" }, os: { type: "linux", name: "linux", architecture: "aarch64" }, platform: "mongoid-7.3.4, Ruby 2.7.4, aarch64-linux, aarch64-unknown-linux-gnu, M|" }
mongo_1    | 2022-02-28T18:42:01.179+0000 I  NETWORK  [listener] connection accepted from 172.20.0.3:54856 #4 (4 connections now open)
mongo_1    | 2022-02-28T18:42:01.179+0000 I  NETWORK  [conn4] received client metadata from 172.20.0.3:54856 conn4: { driver: { name: "mongo-ruby-driver|Mongoid", version: "2.17.0|7.3.4" }, os: { type: "linux", name: "linux", architecture: "aarch64" }, platform: "mongoid-7.3.4, Ruby 2.7.4, aarch64-linux, aarch64-unknown-linux-gnu, A|" }
mongo_1    | 2022-02-28T18:42:01.187+0000 I  NETWORK  [conn3] end connection 172.20.0.3:54854 (3 connections now open)
mongo_1    | 2022-02-28T18:42:01.188+0000 I  NETWORK  [conn4] end connection 172.20.0.3:54856 (2 connections now open)
```

8. Check the clients list, confirm that the `secondary` client is in `NO-MONITORING` state

```
$ curl localhost:4567
Clients info: {:default=>#<Mongo::Client:0x2640 cluster=#<Cluster topology=Single[mongo:27017] servers=[#<Server address=mongo:27017 STANDALONE pool=#<ConnectionPool size=1 (0-5) used=0 avail=1 pending=0>>]>>, :secondary=>#<Mongo::Client:0x3480 cluster=#<Cluster topology=Single[mongo:27017] servers=[#<Server address=mongo:27017 STANDALONE NO-MONITORING pool=#<ConnectionPool size=0 (0-5) used=0 avail=0 pending=0>>]>>}
```

9. Get the list of the post again. This will open up one new connection and use it to make query. However, `secondary` client is still in `NO-MONITORING` state

```
$ curl localhost:4567/posts
[{"_id":{"$oid":"621d14f432e5b000098b59a9"},"body":"hello world","title":"hello"}]
$ curl localhost:4567
Clients info: {:default=>#<Mongo::Client:0x2640 cluster=#<Cluster topology=Single[mongo:27017] servers=[#<Server address=mongo:27017 STANDALONE pool=#<ConnectionPool size=1 (0-5) used=0 avail=1 pending=0>>]>>, :secondary=>#<Mongo::Client:0x3480 cluster=#<Cluster topology=Single[mongo:27017] servers=[#<Server address=mongo:27017 STANDALONE NO-MONITORING pool=#<ConnectionPool size=0 (0-5) used=0 avail=0 pending=0>>]>>}
```

```
mongo_1    | 2022-02-28T18:43:12.632+0000 I  NETWORK  [listener] connection accepted from 172.20.0.3:54890 #5 (3 connections now open)
mongo_1    | 2022-02-28T18:43:12.632+0000 I  NETWORK  [conn5] received client metadata from 172.20.0.3:54890 conn5: { driver: { name: "mongo-ruby-driver|Mongoid", version: "2.17.0|7.3.4" }, os: { type: "linux", name: "linux", architecture: "aarch64" }, platform: "mongoid-7.3.4, Ruby 2.7.4, aarch64-linux, aarch64-unknown-linux-gnu, A|" }
```

10. For any following requests (either using default or secondary clients), there is no new connection will be open, and the 3 open connections will be reused.