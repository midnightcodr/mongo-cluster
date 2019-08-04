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
                "host": "${mongodb1}:${port}"
            },
            {
                "_id": 1,
                "host": "${mongodb2}:${port}"
            },
            {
                "_id": 2,
                "host": "${mongodb3}:${port}"
            }
        ]
    };
    rs.initiate(cfg, { force: true });
    rs.reconfig(cfg, { force: true });
    _cfg=rs.conf()
    _cfg.members[0].priority=1
    _cfg.members[1].priority=0.5
    _cfg.members[2].priority=0.5
    rs.reconfig(_cfg, { force: true });
EOF
echo "Waiting for ${mongodb1} to become master.."
until mongo --host ${mongodb1}:${port} --eval 'quit(db.runCommand({ isMaster: 1 }).isMaster ? 0 : 2)' &>/dev/null; do
  printf '.'
  sleep 1
done
mongo --host ${mongodb1}:${port} <<EOF2
    use app;
    db.list.insert([
        {title: 'one'},
        {title: 'two'}
    ]);
EOF2