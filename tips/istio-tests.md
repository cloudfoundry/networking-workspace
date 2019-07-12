# Running Tests

Run:  
`istio_docker ~/go/src/istio.io/istio`  
`cd /go/src/istio.io/istio/`  
`make localTestEnv`  
`export PATH=/go/bin:$PATH`  
`export ISTIO_OUT=/go/out/linux_amd64/release`

- Sometimes you want to use the make files to run tests (e.g. `make test/local/cloudfoundry/e2e_pilotv2`) because make will do needed `iptables` config
- Sometimes you want to `go test` the individual file because the `makefile` will do k8s things you don't actually need for running your tests (e.g. `go test tests/e2e/tests/pilot/mcp_test.go`)


# Running e2e tests

We ran these from the Mac, not the docker image. Some tests will NOT work when run from the Mac. We did not figure out
how to run tests against minikube from inside the docker image.

Add `127.0.0.1:5000` as an insecure registry to docker?

Helpful starting place: https://github.com/istio/istio/blob/master/tests/e2e/local/minikube/README.md  

However, make sure you have minicube >= 1.2.0, it didn't work for us with 0.35.0

`cd tests/e2e/local/minikube/`  
`./install_prereqs_macos.sh`  
`brew install docker-machine-driver-hyperkit`  
`sudo chown root:wheel /usr/local/bin/docker-machine-driver-hyperkit`  
`sudo chmod u+s /usr/local/bin/docker-machine-driver-hyperkit`  
`./setup_host.sh`  

## This step needs to be run after any code changes to regenerate the binaries/docker images
`ISTIO=~/go/src/istio.io/ ./setup_test.sh`  
`make e2e_pilotv2_v1alpha3 E2E_ARGS="--use_local_cluster" HUB=localhost:5000 TAG=e2e T="-run=NAME_OF_TEST_HERE_FOR_FOCUSED_TEST"`
