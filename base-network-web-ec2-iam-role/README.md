# Basic HTTP Web app with network infrastructure

This terraform template creates the following items:
    - 1 VPC
    - 1 Internet Gateway
    - 1 Route Table
    - 1 Association between route table and Subnet
    - 1 A security group that allows only 22,80,443 ports from my public IP only
    - 1 Network interface
    - 1 Elastic IP associated to the interface created previously
    - 1 Web server instance 
    - 1 Instance role that allows SSM Access

**NOTE** : For this template i used the one from Terraform Course - Automate your AWS cloud infrastructure and added some changes.

To deploy this template to cloudformation:

1. Make sure you create the key pair from AWS Console. As you will be able to connect using AWS Sesion Manager, this is not a MUST but it is a nice to have

2. cd to this directory, this will be your root directory, or the one where you copy the main.tf file

3. Change the values for profile and IPs

4. execute:
```terraform apply
```

5. Review the plan, if you are satisfy write yes when the prompt request it 

6. Wait for the template to end execution and move to the aws console to see the resources created.

7. To destroy the instance execute:
```terraform destry
```