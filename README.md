# terraform-file-structure


which creates EC2, Custom VPC, Custom Security Group(allow ssh, http, https)

Now runs these terraform commands to apply this structure ----
** But before it you have - 
    - AWS account with IAM user for AWS configure
    - Terraform Installed in the system 
    - Clone this repo by git clone <repo-link-here> | need to git installed before it 
    - Go to folder where is main.tf is store
    - You have to generate the ssh key, and give same name as the key-pair from the code or you can give your sutable name 
    - Runs these commands 
** To initilize the terraform to download the providers which is used in the code 
```bash
terraform init
```

** Then plan the structure 
```bash
terraform plan
```

** Now apply the structure
```bash
terraform apply
```
or you can use auto approve 
```bash 
terraform apply -auto-approve
```