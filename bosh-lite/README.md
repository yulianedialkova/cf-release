# Deploying CF on bosh-lite
* Google groups:
  [vcap-dev](https://groups.google.com/a/cloudfoundry.org/group/vcap-dev/topics) (for CF) &
  [bosh-users](https://groups.google.com/a/cloudfoundry.org/group/bosh-users/topics) &
  [bosh-dev](https://groups.google.com/a/cloudfoundry.org/group/bosh-dev/topics)

## Minimum requirements

8GB of RAM. 
Recommend using 16GB+ for better reliability and performance.

## Prepare and target the BOSH Lite director

Refer to [installation instructions](https://github.com/cloudfoundry/bosh-lite/blob/master/README.md) for BOSH Lite 

## Install Spiff
 ensure that you have installed [Spiff](https://github.com/cloudfoundry-incubator/spiff)  before running

# Deploying the latest final cf-release on bosh-lite

```
git clone https://github.com/cloudfoundry/cf-release
cd cf-release
./update
./bosh-lite/provision_latest_stable.sh
```

# Step by step guide for making, deploying, and testing dev releases on bosh-lite

### Upload a cf-compatible bosh-lite stemcell

Bosh team provides warden stemcells for use with bosh lite.

```
curl -L https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent -o latest-bosh-lite-stemcell.tgz
bosh upload stemcell latest-bosh-lite-stemcell.tgz
```

### Create and upload a cf release to the bosh-lite director

If you'd like to deploy the currently checked out git commit 

```
  bosh create release
  bosh upload release
```

### Prepare a deployment manifest using a provided script

```
./bosh-lite/make_manifest
```

### Deploy using a generated manifest

CF Runtime team uses a manifest generator to test CloudFoundry with basic default settings.

```
bosh -d ./bosh-lite/manifests/cf-manifest.yml deploy
```

### Confirm your cf is running and is able to deploy apps

There are 4 checks that confirm your CF is running correctly

1. /v2/info API endpoint responds
1. One simple app pushes successfully. This way you can also explore CF via this app (make requests, tail logs, etc)
1. An acceptance test suite included as a bosh errand completes successfully

##### /v2/info
Validate API endpoint is available

```
curl api.10.244.0.34.xip.io/v2/info
```

##### Simple app push
Use cf cli(available at https://github.com/cloudfoundry/cli) to push one of simple apps available in `src/acceptance-tests/assets`. This 

```
cd src/acceptance-tests/assets/ruby_simple
#login into a an account, space, org
cf logout
cf api api.10.244.0.34.xip.io --skip-ssl-validation
cf auth admin admin
cf co test1
cf target -o test1
cf create-space test1
cf target -o test1 -s test1
cf push test_app
#Observe deployment for any errors or warnings
```

##### Acceptance tests

This suite provides a good check that the CF deployment is operational.
```
bosh run errand acceptance_tests
```
