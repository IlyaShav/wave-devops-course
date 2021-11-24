PART 1
prerquisites: 
1.aws cli installed with full credentials.
2.aws key pair for accessing provisioned instances.
3.terraform installed.
4.an IAM role for ansible, so it could utilize the dynamic inventory.

steps:
1. pull the git files from the repository
2. type "terraform init" to initialize all terraform configuration files
3. enter the vpc.tf file and in the ec2_instance module change the "key_name" value to your key.
4. type "terraform apply" to provision the resources.
5. once the resources were provisioned, enter your aws console and ssh to your "public" instance, from there we will run the ansible playbook.
6. now we need to establish an ssh connetion between the public instance and the private instances, create a file that will contain your private key
   and enter the following command "chmod 600 yourkey.pem", this command will ensure that the ssh-agent will accept the key.
7. enter the command "eval `ssh-agent`" to start a ssh-agent session.
8. enter the command "ssh-add yourkey.pem" to add the identity to the ssh-agent, now when we ssh to the private instances, the ssh-agent will use
   the key we added to authenticate us and grant access. 
9. go to the directory "/ansible" there you should find the playbook, and enter the command "ansible-playbook playbook.yaml" this will initiate the
   installation of docker and will provision a web server in a docker container.
10. in the aws console, search for ec2 service and click on it, to the left you'll see a list of tabs, click on the load balancers tab, there
    should be one ready for you, copy the load balancer's address and paste it into your browser, you should see the web server working!
 
PART 2
prerquisites: 
1.aws cli installed with full credentials.
2.terraform v0.13.6 installed. 

steps: 
1. get the repo and enter the part 2 directory, terraform uses the AWS credentials file to authenticate into the account, please change the "shared_credentials_file" value to your file location and save the file, enter "terraform" init", then "terraform apply".
2. terraform will provision an EKS cluster with an ECR repository and jenkins that we will need for part 3, the proccess should take 10-15 minutes to complete.
3. after the cluster's creation we should see if we can connect to it and see the resources, enter the command "export KUBECONFIG=~/wave-devops-course/part2/kubeconfig_my-cluster" this command grants us access to our provisioned cluster with the file named "kubeconfig_my-cluster".
4. now enter "kubectl get nodes" to see that we have acceess.




PART 3
prerquisites:
1.an ECR repository
2.jenkins installed
3.jenkins plugins: Docker, Docker PipeLine, Kubernetes, Kubernetes continuous deploy.

steps:
1.
2. enter your jenkins dashboard and choose a new item, pick a pipeline.
3. scroll down to PipeLine and in the definition tab pick "pipeline script from SCM"
4. in the repository tab copy and paste the repo :https://github.com/IlyaShav/wave-devops-course.git
5. run the pipeline and the image with the application should be in the ECR.
6. in the script path write "JenkinsFile"
7. click on "build now", the docker image should be in the ecr in about 30 seconds.
