RUN_DIR=/var/vcap/sys/run/ca_truster

function trust_cas() { #first argument is cert_writer_path
  set -e -x
  $1
  update-ca-certificates
}

function untrust_cas() {
  set -e -x
  rm -f /usr/local/share/ca-certificates/cf-ca-truster-*.crt
  update-ca-certificates --fresh
}

lockdir=$RUN_DIR/ca_truster.lock
if mkdir "$lockdir"
then    # directory did not exist, but was created successfully
    echo "successfully acquired lock: $lockdir"
    # continue script
else    # failed to create the directory, presumably because it already exists
  echo "cannot acquire lock, giving up on $lockdir"
  exit 0
fi

mkdir -p $RUN_DIR
touch $RUN_DIR/cert_digest

#guard check
shasum $1 > $RUN_DIR/new_cert_digest
if [ ! -z "$(diff -q $RUN_DIR/cert_digest $RUN_DIR/new_cert_digest)" ] ; then
  untrust_cas
  trust_cas $1
fi
mv $RUN_DIR/new_cert_digest $RUN_DIR/cert_digest
rmdir "$lockdir"
