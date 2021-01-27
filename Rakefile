aws_profile="englishbeef-root"
aws_region="eu-west-2"
aws_repository_url="357982985018.dkr.ecr.eu-west-2.amazonaws.com"

desc 'Deploy the AO test application'
task :apply_ao => ["init_ao"] do
    sh %{ terraform -chdir=terraform/state/ao apply -auto-approve }
end

desc 'Deploy the Docker build VM'
task :apply_build => ["init_build"] do
    sh %{ terraform -chdir=terraform/state/build apply -auto-approve }
end

desc 'Deploy the ECR repositories for docker images'
task :apply_ecr => ["init_ecr"] do
    sh %{ terraform -chdir=terraform/state/ecr apply -auto-approve }
end

desc 'Build the docker images defined in the compose file'
task :build do
    sh %{ docker-compose build }
end

desc 'Destroy all deployed Terraform'
task :destroy => ["destroy_ao", "destroy_build", "destroy_ecr"] do
end

desc 'Destroy the AO test application'
task :destroy_ao do
    sh %{ terraform -chdir=terraform/state/ao destroy -auto-approve }
end

desc 'Destroy the Docker build VM'
task :destroy_build do
    sh %{ terraform -chdir=terraform/state/build destroy -auto-approve }
end

desc 'Destroy the ECR repositories for docker images'
task :destroy_ecr do
    sh %{ terraform -chdir=terraform/state/ecr destroy -auto-approve }
end

desc 'Rewrites all Terraform configuration files to a canonical format'
task :fmt do
    sh %{ terraform fmt -recursive -diff . }
end

desc 'Initialise all Terraform states'
task :init => ["init_ecr", "init_build", "init_ao"] do
end

desc 'Initialise Terraform for the AO application'
task :init_ao do
    dir='terraform/state/ao'

    if !Dir.exist?(dir+'/.terraform')
        sh %{ terraform -chdir=#{dir} init }
    end
end

desc 'Initialise Terraform for the Docker build VM'
task :init_build do
    dir='terraform/state/build'

    if !Dir.exist?(dir+'/.terraform')
        sh %{ terraform -chdir=#{dir} init }
    end
end

desc 'Initialise Terraform for the ECR repositories'
task :init_ecr do
    dir='terraform/state/ecr'

    if !Dir.exist?(dir+'/.terraform')
        sh %{ terraform -chdir=#{dir} init }
    end
end

desc 'Login to ECR with your AWS profile'
task :login do
    sh %{ aws ecr get-login-password --region #{aws_region}  --profile #{aws_profile} \
            | docker login --username AWS --password-stdin #{aws_repository_url} }    
end

desc 'Push the docker image(s) to a remote repository'
task :push => ["build", "login"] do
    sh %{ docker-compose push }
end

desc 'Run the containers defined in the compose file'
task :up => ["build"] do
    sh %{ docker-compose up -d }
end

desc 'Validate Terraform configuration files in a directory'
task :validate do
    sh %{ terraform validate }
    if $?.exitstatus != 0
        exit
    end
end

desc 'Commit changes to repository'
task :commit do
    
end