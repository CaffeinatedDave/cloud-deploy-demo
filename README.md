Sheffield Hackathon - Deployment to the Cloud Demo App
======================================================

# Deploying to Heroku

TODO

# Deploying to AWS

These instructions are written with the aim of helping people to follow the SkyBet Workshop at HackSheffield.

The intention is to help contestants who wish to host their projects on EC2 get their code reliably and easily deployed to an EC2 instance.

If you are trying to use this AWS CodeDeploy and are having any trouble pm me(@Conorrr) on the [HackSheffield slack](https://hacksheffield.slack.com).

CodeDeploy is generally aimed at users with much more time to develop complex deployment solutions, for the hackathon I have attempted to make use of CodeDeploy to quickly get code reliably deployed.

To make this guide simpler and easier to follow I will be using the web console for all AWS configuration.

The guide may looks quite lengthy but I have attempted to break things down into their most basic steps. It is written assuming that you are using a *nix machine. If you are using windows the majority of the steps should be the same except for the SSH steps which would require a SSH client.

###Prerequisites
 - Signed up for GitHub account
 - Signed up for an AWS account

##Instructions 

###Step 1 - Set up security for EC2 and CodeDeploy

* **Create a Role for EC2** - this appears to be a quirk of CodeDeploy. The EC2 instance doesn't make use of this Role but CodeDeploy requires that the EC2 instance you wish to deploy to has a role set.
 * Navigate to https://eu-west-1.console.aws.amazon.com
 * Firstly we need to setup policies so that CodeDeploy can access our EC2 instance
 * Select *Identity & Access Management*
 * Select *Roles* on the left hand side
 * Now click the **Create New Role** at the top of the page
 * Name the role *ec2-cd-role*
 * On the next page select **AWS Service Roles** -> **Amazon EC2**
 * Select the **AmazonS3ReadOnlyAccess** Policy and click Next Step
 * Click Create Role

* **Create a Role for CodeDeploy** - this role is used by CodeDeploy and it is used.
 * You should've been returned to the Roles page, Click the *Create New Role* button
 * Name it *cd-role*
 * This time select **AWS CodeDeploy** (you may need to scroll down a bit)
 * Select the **AWSCodeDeployRole** policy
 * Click **Create role**

* **Create KeyPair** - you will need this to securely SSH into the EC2 instance
 * Return to the AWS dashboard by clicking the AWS logo in the top left of the page, under Compute select **EC2**
 * Under *Network & Security* on the left hand side click **Key Pairs**
 * Click **Create Key Pair** and name it workshop
 * This should trigger the download of a file called *workshop.pem*
 * Move this pem file to **~/.ssh** you may need to create the directory if it doesn't already exist. `mkdir -p ~/.ssh| mv ~/Downloads/workshop.pem ~/.ssh/workshop.pem`

###Step 2 - Launch an EC2 instance
 * Select *Instances* on the left hand menu
 * Click the **Launch Instance** button at the top of the page
 * Select *Amazon Linux AMI 2015.09.2*
 * Choose *t2.micro* and Click **Next: Configure Instance Details** (not Review and Launch)
 * Change IAM role to *ec2-cd-role* and click **Next: Add Storage**
 * The default selection will do fine, click **Next: Tag Instance**
 * We need to tag our instance so that it can be identified by CodeDeploy, Give it the name *sb-workshop* and click **Next: Configure Security Group**
 * We want to create a new security group with the following rules: (these can be changed later so don't worry if you mess them up)
  * Type: *SSH* the other fields should be autopopulated
  * Type: *HTTPS* the other fields should be autopopulated
  * Type: *Custom TCP Rule*, Port Range: *8080*, Source: *Anywhere*
 * Click **Review and Launch**
 * Your confirm screen should match:

 ![Confirm EC2 Page](http://i.imgur.com/KonTchq.png)

 * When you click **Launch** you should be prompted to select a keypair, pick workshop, check the checkbox and click **Launch Instances**, It should take ~ a minute for your instance to get up and running.

###Step 3 - Install AWS CodeDeploy

* Find the *Public IP address* for your instance from the instance dashboard
* SSH onto your newly instantiated EC2 instance
 - `ssh -i ~/.ssh/workshop.pem ec2-user@EC2_PUBLIC_IP`
* Download and install AWS CodeDeploy
 - `sudo yum update` - this may take a couple of minutes to complete
 - `wget https://aws-codedeploy-eu-west-1.s3.amazonaws.com/latest/install`
 - `chmod +x ./install`
 - `sudo ./install auto`

### Step 4 - Setup CodeDeploy

* Navigate to [*CodeDeploy*](https://eu-west-1.console.aws.amazon.com/codedeploy/home?region=eu-west-1#/applications)
* Select **Create New Application**
* You can name your application and deployment group whatever you want
* Now select Key:*Name* and Value:*sb-workshop* under Tags
* Set *Deployment Config* to any value, it shouldn't make a difference because we on have 1 instance
* Select cd-role for the *Service Role ARN* (it will be prefix with a long string)
* Click **Create Application**

### Step 5 - Deploying code

For your own application this step should be repeated everytime you wish to push new changes.  In this workshop I am only explaining how to deploycode manually each time using the webconsole. If you had more time you could set up AWS command line tools to trigger deployments or set up GitHub hooks so that your code is deployed each time you pushed to master. But seeing as there is only 24 to develop your application neither of these things have much value.

![Where to find deployments](http://i.imgur.com/ndFBx8k.png)

* Select deployments as shown above and click **Create New Deployment**
* Select your *Application* and your *Deployment Group*
* Check *My application is stored in GitHub*, a **Connect with GitHub** but should appear, click it and sign in to GitHub.
* Now enter *CaffeinatedDave/cloud-deploy-demo* as the Repository Name 
* Go to GitHub and get the latest full length commit hash, for this demo it is *59f225a15a9e7bbc5b68a55f17d78d672a797e4a* (This may well get outdated if I forget to update it)
* Select any Deployment Config option as in step 4
* Hit **Deploy Now**


### STEP 6 - Debugging problems

* You should be taken back to a list of deployments, each deployment is given a random name, click on the name od the deployment at the top of the list
* You should see the status of the Deployment (hopefully is says Successfull)
* At the bottom of the page is a list of all instances that have been deployed to, in this workshop we only deployed to 1.
* On the right of the instance is a link to *View Events*, this lists out each step and whether it was successful. If it wasn't successful then a link to view the error log will exist.

#### So how does AWS know what to do
Instructions on how to deploy the application are held in a file called `app-spec.yaml` in the git repo

I will breifly explain what each part of the app-spec does, for more information see the [appspec user guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html)

Here is the appspec used to deploy this project.

```
version: 0.0
os: linux
files:
  - source: /Gemfile
    destination: /opt/ruby-app
  - source: /Gemfile.lock
    destination: /opt/ruby-app
  - source: /public
    destination: /opt/ruby-app/public
  - source: /views
    destination: /opt/ruby-app/views
  - source: /web.rb
    destination: /opt/ruby-app 
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies
      timeout: 300
      runas: ec2-user
  AfterInstall:
    - location: scripts/setup_app
      timeout: 300
      runas: ec2-user
  ApplicationStart:
    - location: scripts/start_server
      timeout: 300
      runas: ec2-user
  ApplicationStop:
    - location: scripts/stop_server
      timeout: 300
      runas: ec2-user
```

**version** - This is for the version of the appspec format, currently there is only 1 version `0.0.0`

**os** - Specifies what OS the application should run on can be either `linux` or `windows`

**files** - These are simple rules which run during the Install hook(see below for an explanation of hooks). It specifies which files and directories should be copied from the repository to the server and where they should be copied to.

**permissions** - Although not used in this project if specific permissions need to be set for files then they should be specified in here. See the [appspec user guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html#http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html#d0e30313) for more infomation.

**hooks**: These specify bash scripts that should be run and which user they should be run as. The timeout is how long CodeDeploy should wait before failing the deployment in seconds. See below for more infomation on hooks.

#### Hooks

Code deployment is split into a 7 Steps, 5 user defined and 2 process defined.

![hook diagram](http://docs.aws.amazon.com/codedeploy/latest/userguide/images/app_hooks.png)

1. **ApplicationStop** - this is the first step. In this step you should stop your application from running and delete any temporary data you don't need.
2. **DownloadBundle** - This event copies files to a temporary directory on the EC2 instance. This event is reserved for the AWS CodeDeploy agent and cannot be used to run scripts.
3. **BeforeInstall** – You can use this deployment lifecycle event for preinstall tasks, such as installing dependencies.
4. **Install** - During this deployment lifecycle event, the AWS CodeDeploy agent copies the revision files from the temporary location to the final destination folder. This event is reserved for the AWS CodeDeploy agent and cannot be used to run scripts.
5. **AfterInstall** - You can use this deployment lifecycle event for tasks such as configuring your application and downloading dependencies listed in the application.
6. **ApplicationStart** – You typically use this deployment lifecycle event to restart services that were stopped during ApplicationStop.
7. **ValidateService** – This is the last deployment lifecycle event. It should be used to verify the deployment was completed successfully.

####More Reading

- [CloudDeploy troubleshooting guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting.html)
- [appspec.yaml Reference guide](http://docs.aws.amazon.com/codedeploy/latest/userguide/app-spec-ref.html)

