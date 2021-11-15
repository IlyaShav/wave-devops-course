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
2.aws key pair for accessing provisioned instances.
3.terraform v0.13.6 installed. 

steps: 
1. pull the files "main.tf" and "outputs.tf" from git into a directory and enter the command "terraform init"
2. terraform will provision an EKS cluster with an ECR repository that we will need for part 3, the proccess should take 10-15 minutes to complete.
3. after the cluster's creation we should see if we can connect to it and see the resources, enter the command "KUBECONFIG=./kubeconfig_my-cluster kubectl get nodes --all-            namespaces". this command grants us access to our provisioned cluster with the file named "kubeconfig_my-cluster".

PART 3
prerquisites:
1.an ECR repository
2.jenkins installed
3.jenkins plugins:
  Docker
  Docker PipeLine
4.docker installed

steps:
1. enter your jenkins dashboard and choose a new item, pick a pipeline.
2. scroll down to PipeLine and paste the JenkinsFile code in the repository to the script field below.
3. substitute the environment variable's values in the pipeline with your values:
   In place of “YOUR_ACCOUNT_ID_HERE” paste your AWS Account ID
   In place of “CREATED_AWS_ECR_CONTAINER_REPO_REGION” copy created ECR repo region id
   “IMAGE_REPO_NAME” set your ECR repository name (repo was created in part 2, use the name that was given)
   “IMAGE_TAG” mention your desired tag
4. let's take our .aws folder with all the credentials in it, copy it into the /var/lib/jenkins folder and change the owner of the files inside to jenkins using the following      command "sudo chown -R jenkins ./", jenkins should be able to read the credentials and access ecr.
5.  run the pipeline and the image with the application should be in the ECR.
