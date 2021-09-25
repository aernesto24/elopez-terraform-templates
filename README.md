# elopez-terraform-templates
Terraform templates from different trainings or developed by myself

**NOTE** : Inside each folder there will be specific README files adapted to the template request

## Useful commands
This small part provide some useful commands for terraform


```
terraform state list
```
List all resources we have state for, mostly resources that i created


```
terraform state show <resource>
```
Provides detailf of an specific resource, example:
- terraform state show aws_instance.myfirstServer


```
terraform apply --auto-approve
```
Apply your terraform template with automatic approval (**you must be cautious with this**)


```
terraform output
```
Show all the outputs defined on your template 


```
terraform refresh
```
Refresh the state of your terraform deployment without actually redeploying anything, helpful if you add outputs to your template and want to see how it looks like


```
terraform destroy --target resource.name
```
This command will destroy a specific resource instead of all the resources defined in the template
- Example: terraform destroy --target aws_instance.myfirstServer


```
terraform apply --target resource.name
```
This command will create a specific resource instead of all the resources defined in the template
- Example: terraform apply --target aws_instance.myfirstServer


```
terraform apply -var "var_name=var_value"
```
Apply a terraform template entering the value you defined in a variable inside the template.
- Lets say you define the following variable:
    - variable "instance_type" { description = "Instance Type"}
    - you can apply it using terraform apply -var "instance_type=t3.micro"


