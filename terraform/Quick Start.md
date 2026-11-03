## Setting Up AWS SES using Lambda and API Gateway | Spring Boot Rest API and Terraform

AWS Simple Email Service (SES) is a cloud-based email sending service designed to help digital marketers and application
developers send marketing, notification, and transactional emails. It is a reliable, scalable, and cost-effective
service for businesses of all sizes.

### Deploy

```bash
$ cd setting-up-aws-ses/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve
```

### Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```
