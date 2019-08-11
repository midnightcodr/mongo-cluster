#!/bin/bash 

mongodb1=`getent hosts ${MONGO1} | awk '{ print $1 }'`
mongodb2=`getent hosts ${MONGO2} | awk '{ print $1 }'`
mongodb3=`getent hosts ${MONGO3} | awk '{ print $1 }'`

port=${PORT:-27017}

echo "Waiting for startup.."
until mongo --host ${mongodb1}:${port} --eval 'quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)' &>/dev/null; do
  printf '.'
  sleep 1
done

echo "Started.."

echo setup.sh time now: `date +"%T" `
mongo --host ${mongodb1}:${port} <<EOF
   var cfg = {
        "_id": "${RS}",
        "protocolVersion": 1,
        "members": [
            {
                "_id": 0,
                "host": "${mongodb1}:${port}",
                "priority": 1
            },
            {
                "_id": 1,
                "host": "${mongodb2}:${port}",
                "priority": 0.5
            },
            {
                "_id": 2,
                "host": "${mongodb3}:${port}",
                "priority": 0.5
            }
        ]
    };
    rs.initiate(cfg, { force: true });
    rs.reconfig(cfg, { force: true });
EOF
echo "Waiting for ${mongodb1} to become master.."
until mongo --host ${mongodb1}:${port} --eval 'quit(db.runCommand({ isMaster: 1 }).ismaster ? 0 : 2)' &>/dev/null; do
  printf '.'
  sleep 1
done
sleep 5
mongo --host ${mongodb1}:${port} <<EOF2
    use app;
    db.list.insert([
        {title: 'one'},
        {title: 'two'}
    ]);
EOF2