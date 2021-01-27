
# Install rake
# Install aws cli https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
aws configure --profile englishbeef-root
aws ecr get-login-password \
    --region eu-west-2 \
    --profile englishbeef-root \
  | docker login \
    --username AWS \
    --password-stdin 357982985018.dkr.ecr.eu-west-2.amazonaws.com/aspnetapp
aws ecr get-login-password \
    --region eu-west-2 \
    --profile englishbeef-root \
  | docker login \
    --username AWS \
    --password-stdin 357982985018.dkr.ecr.eu-west-2.amazonaws.com/nginx
# Install docker cli
# Connect to cluster after deploy
docker context create ecs aspnet
docker context use aspnet
docker compose up 

# Manually add zone to route53, e.g. added ao-docker-tech-test.englishbeef.com, then setup my provider (Gandi) to point to the new zone

docker login --username AWS --password $(docker run --rm -it amazon/aws-cli ecr get-login-password --region eu-west-2) 357982985018.dkr.ecr.eu-west-2.amazonaws.com

# Create docker context
docker context create build --docker "host=ssh://ec2-user@52.56.160.205"

# Pushing to repositories appears to be done locally
docker-compose up -d --build

# So dividing a net by 4 is cidr + 2 bits, could do some magic with cidrsunets function


# Demo
This repository has enough infrastructure to allow you to build and deploy the applications completely. The whole deployment should fit completely within an AWS free tier account.

## Prerequisites
### AWS Account
Create an AWS account if don't have one, or a new one to take advantage of the free tier.

You will also need to use the Root account credentials, or an Admin account with lots of access, e.g. all of EC2, ECS, VPC, ECR (anything Terraform is likely to touch).

### terraform.tfvars
In each of terraform/state/{ao,build,ecr} you will need to place a `terraform.tfvars` file with your API and region details:

```
aws_access_key = ACCESS_KEY
aws_region     = "eu-west-2"
aws_secret_key = SECRET_KEY
```

*NOTE* if you want to use the code as is, you will need to leave region as `eu-west-2` due to hard coded subnet defaults in the `aws-ecs-app` module that I didn't get a chance to fix. If you want to use a different region you'll need to define the `vpc` input, and associated values.

If you change region you will also need to update `Rakefile`.

### DNS Zone
The application module takes a domain name as input, however it only manages adding records. You must setup the zone in Route 53 in advance, including adding any NS records (for a subdomain) or with you registrar (for a root domain).

### Tools
You'll need to ensure you have the following installed:

* aws-cli >~ 2.1
* docker-compose >~ 1.27
* rake (if you wasnt to use some helpers)
* terraform >~ v0.14

### AWS CLI
Ensure this is setup, and you've created a profile. You will need to update `Rakefile` with your new profile name.

## Deployment
### Create repositories
Create the repositories first, so we've got somewhere to push the images to. You can use the rake helper:

```
rake apply_ecr
```

*NOTE* You will need to update `docker-compose.yml`, `task.json`, and `Rakefile` with the new repository URLs.

### Build and run Docker containers
#### Remote
A Terraform module has been written to create a remote build machine. Make sure you update the `priviledged_subnets` input with your public IP (curl https://icanhazip.com).

 You can either ssh to it, clone the repository, and build the containers. Or use it as a remote host like so:

```
rake apply_build
```

This will output the IP of the remote instance, which you can now use to setup a Docker context:

```
docker context create build --docker "host=ssh://ec2-user@${EC2_IP}"
docker context use build
```

Now build and push the containers to the repositorys:

```
rake push
```

### Local
This is the simplest option, just build and push:

```
rake push
```

### Deploy application
Now we have the containers deploy the application Terraform. Make sure you've updated the `name` input to the `ao` state with your desired domain!

```
rake apply_ao
```

Within a couple minutes of Terraform finishing you should be able to browse to your domain.

### Deploy update
To see ECS handle a container update bumb the container versions in `docker-compose.yaml` and `task.json`. Run through the build and push, and applying Terraform:

```
rake push
rake apply_ao
```

Now you should be able to login to the ECS console, see that a new deployment is pending, and watch it perform a rolling replacement of the containers.
