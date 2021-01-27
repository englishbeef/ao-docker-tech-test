# AO Tech Challenge - Solution
## Summary
The goal of this repository is to provide the following tools:

* Building and publishing Docker containers with a simple toolset
* Support local and remote builds
* An all in one infrastructure stack managed by Terraform, allowing the easy deployment of a simple application

## Docker
### Build, Tag, and Push with docker-compose
Running `docker-compose up -d` in the local repository will trigger a build (if the images don't already exist), and bring the containers up. In the current configuration you can browse to http://localhost to inspect the application.

Basic healthchecks have also been added to the containers for basic failure inspection via `docker-compose ps`.

Once changes are ready the repository can be tagged with a version, and the `image:` stanzas in the compose file update with the new image versions. This can then be checked out by a CI platform which now simply has to run:
```
docker-compose build
docker-compose push
```
The new image versions will now be pushed out to their repositories reay for deployment.

### Nginx
A very simple Nginx container has been provisioned as a simple front end and loadbalancer. Loadbalancing is achived by leaveraging Dockers internal DNS and loadbalancing.

Nginx has the following upstream stanza configured, pointing to the backend applications Docker VIP (created, and named after, each defined service):

```
upstream aspnetapp {
    server aspnetapp;
}
```

Nginx sends traffic to the VIP, while Docker handles the actual loadbalancing to containers belonging to that service.

## Terraform
### aws-ecs-app
This Terraform module has been created to do the following:

* Deploy all infrastructure to expose a HTTPS endpoint
* Not bound to a particular application, be generic
* Ensure the infrastructure is easily secured
* Be uncomplicated and easy to use by only requiring important inputs to make and secure the application
* Use only AWS provided infrastructure

The only requirement of the module is that the root (or sub) domain you wish deploy the application under is already setup in Route 53.

Behind the scenes the modules uses AWSs Elastic Container Service (ECS) running on auto scaled EC2 instances. Containers are deployed via [Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html) in a user defined `.json` file.

### Deployment
On initial deployment ECS will attempt to provision the defined containers, and will keep trying until the defined images are available in the configured repositories.

Deploying new containers is as simple as updating the versions in the task definition, and running Terraform. ECS will then manage a phased deployment, taking the old containers out of service gracefully. Dependingon the required amount of tasks the EC2 instances might require increasing temporarily (again easily changed as a module input).

## Future Recommendations
* Customise the ECS AMI with Packer / Cloud-init specifically:
  * Remove passwordless sudo
  * Create AO specific admin user, remove ec2-user
  * Harden SSH - MACs, Ciphers, reduce attack surface by disabling password / gssapi etc, set Allow blocks
  * Automatic package updates
  * Log shipping, tripwire, monitoring etc
* Move to VPN + NAT network and remove all external ingress from the VMs
* Implement a service discovery layer, e.g. Consul, so we can deploy multiple applications behind a single endpoint, with Nginx performing routing
* Healthcheck customisation needs implementing in the module
* IAM policies need tweaking / better exposure
* Make the module much more generic and flexible, at the expense of complexity
* More work with ECS as currently Nginx and Aspnetapp have to be scaled together so that the routing from Nginx works