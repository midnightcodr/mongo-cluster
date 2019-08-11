# About
This is simple docker compose setting with one mongo cluster that is consisted of 3 nodes.

# Run
```bash
docker-compose up
```

# Confirm
```bash
docker exec -it mongo-1-1 bash
mongo
use app
db.list.find()
```

## Example output

```js
rs1:PRIMARY> use app
switched to db app
rs1:PRIMARY> db.list.find()
{ "_id" : ObjectId("5d506140875b7c82505db67d"), "title" : "one" }
{ "_id" : ObjectId("5d506140875b7c82505db67e"), "title" : "two" }
rs1:PRIMARY> 
```

# Test with a real nodejs program

### set up a shell function runnode
```bash
runnode () {
	[ $# -lt 1 ] && echo "Usage: $FUNCNAME script" && return
	scriptname=$1 
	shift
	others=$* 
	docker run -it --rm --name my-node-script -v "$PWD":/usr/src/app -w /usr/src/app $others node node $scriptname
}
```

### node application
```js
const MongoClient = require('mongodb').MongoClient

const url = 'mongodb://mongo-1-1:27017,mongo-1-2:27017,mongo-1-3:27017/app?replicaSet=rs1'
const db = 'app'

const main = async () => {
  console.log('start')
  const client = await MongoClient.connect(url, { useNewUrlParser: true })
  const col = client.db(db).collection('list')
  const res = await col.find({}, { limit: 5 }).toArray()
  console.log(res)
  await client.close()
  console.log('end')
}
main()
```

### test the application
```bash
npm i   # install from the host
runnode cluster-auth-test.js --net=mongo-cluster_default # this runs the nodejs script from within the node container, mongo-cluster is the directory name of this git repo
```

### example output
```bash
start
[ { _id: 5d506140875b7c82505db67d, title: 'one' },
  { _id: 5d506140875b7c82505db67e, title: 'two' } ]
end
```