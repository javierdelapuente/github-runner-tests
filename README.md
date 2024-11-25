```
./prepare_openstack.sh
./prepare_githubrunners.sh

lxc file pull openstack/home/ubuntu/demo-openrc .
lxc file push demo-openrc github-runners/home/ubuntu/demo-openrc


lxc exec github-runners -- su --login ubuntu

. <( cat demo-openrc )
cd /home/ubuntu/github/javierdelapuente/github-runner-operator

REPOSITORY=javierdelapuente/github-runner-operator
TOKEN=<YOUR GITHUB TOKEN>


juju add-model testing
# create a base image
BASE_IMAGE=jammy
juju deploy github-runner-image-builder --channel=edge --revision=22 \
--config base-image=$BASE_IMAGE \
--config openstack-auth-url=$OS_AUTH_URL \
--config openstack-password=$OS_PASSWORD \
--config openstack-project-domain-name=$OS_PROJECT_DOMAIN_NAME \
--config openstack-project-name=$OS_PROJECT_NAME \
--config openstack-user-domain-name=$OS_USER_DOMAIN_NAME \
--config openstack-user-name=$OS_USERNAME \
--config experimental-external-build=true \
--config experimental-external-build-flavor=m1.builder \
--config experimental-external-build-network=external-network \
--config app-channel="edge"

cat << EOF >clouds.yaml
clouds:
  cloud:
    auth:
      auth_url: $OS_AUTH_URL
      project_name: $OS_PROJECT_NAME
      username: $OS_USERNAME
      password: $OS_PASSWORD
      user_domain_name: $OS_USER_DOMAIN_NAME
      project_domain_name: $OS_PROJECT_DOMAIN_NAME
    region_name: RegionOne
EOF

juju deploy github-runner --channel=latest/edge --config path=$REPOSITORY --config virtual-machines=1 --config openstack-clouds-yaml=@clouds.yaml --config openstack-flavor=m1.small --config openstack-network=external-network --config token=$TOKEN
juju integrate github-runner github-runner-image-builder

# is this valid?
# https://juju.is/docs/juju/constraint#heading--virt-type: kvm, virtual-machine
# arch=amd64 cores=0 mem=0M virt-type=container

tox -e integration-juju3.2 -- -x  --log-cli-level=DEBUG  --log-format="%(asctime)s %(levelname)s %(message)s" --charm-file=github-runner_ubuntu-22.04-amd64.charm --path=$REPOSITORY --token=$TOKEN --model testing --keep-models --openstack-test-image image-builder-jammy-x64 --openstack-flavor-name-amd64 "m1.small" --openstack-network-name-amd64 external-network --openstack-auth-url-amd64 "${OS_AUTH_URL}" --openstack-password-amd64 "${OS_PASSWORD}" --openstack-project-domain-name-amd64 "${OS_PROJECT_DOMAIN_NAME}" --openstack-project-name-amd64 "${OS_PROJECT_NAME}" --openstack-user-domain-name-amd64 "${OS_USER_DOMAIN_NAME}" --openstack-username-amd64 "${OS_USERNAME}" --openstack-region-name-amd64 "RegionOne"  -m openstack -k test_runner_manager_openstack
```