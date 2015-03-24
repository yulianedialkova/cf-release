#!/usr/bin/env bash

set -xe

DIR="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
STEMCELL_SOURCE=https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
STEMCELL_FILE=latest-bosh-stemcell-warden.tgz
CF_DIR="$DIR/.."
MOST_RECENT_CF_RELEASE=$(find ${CF_DIR}/releases -regex ".*cf-[0-9]*.yml" | sort | tail -n 1)

main() {
  fetch_stemcell
  upload_stemcell
  build_manifest
  deploy_release
}

fetch_stemcell() {
  if [[ ! -e $STEMCELL_FILE ]]
  then
    curl -L --progress-bar "${STEMCELL_SOURCE}" -o "$STEMCELL_FILE"
  fi
}

upload_stemcell() {
  bosh -n -u admin -p admin upload stemcell --skip-if-exists $STEMCELL_FILE
}

build_manifest() {
    TMPDIR=$(mktemp -d /tmp/cfXXXXXXXXXXXX)
    cp -R $CF_DIR/ $TMPDIR/cf-release
    pushd $TMPDIR/cf-release
    local version=$(echo $MOST_RECENT_CF_RELEASE  | egrep -o 'cf-[0-9]+' | egrep -o '[0-9]+')
    git clean -ffdx
    git co .
    git co v$version
    ./update
    mkdir -p $CF_DIR/bosh-lite/manifests
    BOSH_RELEASES_DIR=$TMPDIR bosh-lite/make_manifest 
    local manifest_path=$CF_DIR/bosh-lite/manifests/v${version}.yml
    cp bosh-lite/manifests/cf-manifest.yml $manifest_path
    ruby -e "require 'yaml'; y = YAML.load_file('$manifest_path'); y['releases'].map!{|r| r['version'] = ${version}; r}; File.write('$manifest_path', YAML.dump(y))"
    bosh deployment $CF_DIR/bosh-lite/manifests/v${version}.yml
    popd
    rm -rf $TMPDIR
}

deploy_release() {
  bosh -n -u admin -p admin upload release --skip-if-exists $MOST_RECENT_CF_RELEASE
  bosh -n -u admin -p admin deploy
}

main
