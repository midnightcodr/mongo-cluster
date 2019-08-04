k=keys/keyfile
openssl rand -base64 741 > $k
chmod 600 $k
sudo chown 999 $k
