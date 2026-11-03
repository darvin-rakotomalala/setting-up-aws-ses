## Setting Up AWS SES using Lambda and API Gateway | Spring Boot Rest API and Terraform

AWS Simple Email Service (SES) is a cloud-based email sending service designed to help digital marketers and application
developers send marketing, notification, and transactional emails. It is a reliable, scalable, and cost-effective
service for businesses of all sizes.

### Key Features:

- **Scalability**: Handles large volumes of emails effortlessly.
- **Deliverability**: High deliverability rates due to AWS's reputation.
- **Cost-Effective**: Pay-as-you-go pricing model.
- **Security**: Supports authentication mechanisms like DKIM and SPF.

### Challenges of traditional email systems

* Setting up and managing email servers
* Configuring networks for reliable email delivery
* Maintaining good IP address reputation to avoid spam

### Benefits of using amazon ses for contact form email

* Email server management is handled entirely by Amazon
* Emails are sent through Amazon's reliable network infrastructure
* Users benefit from Amazon's established sender reputation

## The Architecture Backend Overview

Let's dive into AWS and what services we are going to use and how.

As mentioned in the title, we will use AWS Lambda and Simple Email Service (SES). SES is a serverless messaging service
that allows you to send email messages when invoked. AWS Lambda allows you to write server-side code to execute in
response to events.

![setting-up-asw-ses.png](setting-up-asw-ses.png)

We will also use API Gateway which enables us to invoke Lambda functions via HTTP.

```
Users -> API Gateway (REST, /{proxy+} ANY) -> Lambda alias "lambda-dev" (Spring Boot 4, Java 21)
                                                   |-> SES  (email to the site owner)
                                                   |-> KMS  (logs, SNS, S3, env vars)
                                                   '-> CloudWatch -> SNS (critical / warning)
GitHub push -> GitHub Actions -> OIDC -> Terraform -> AWS
```

### Technology

***

* Java 21
* Spring Boot 4
* Maven
* AWS account
* Role and permission Lambda, SES, API Gateway

## Implementation

***

- Provisioning infrastructure with Terraform
- Sending a Simple Email: Send a simple plain-text email using AWS SDK.

### Deploy

```bash
# Build the Lambda package (classes + lib/*.jar zip)
mvn clean packages                    # -> target/ses-email-backend-lambda.zip

# Provision
$ cd setting-up-aws-ses/terraform
$ terraform init
$ terraform fmt -recursive
$ terraform validate
$ terraform plan -var-file="terraform.tfvars" -no-color -out=TFplan.JSON
$ terraform apply -var-file="terraform.tfvars" -auto-approve

# Click the verification link AWS emails to sender_email (and recipient_email if different).
# Also confirm the SNS subscription emails.
```

## Verification and Testing

***

- SENDER_EMAIL=`you@gmail.com`
- `GET api_invoke_url/api/health` - cheap liveness check that does not touch SES.
- `POST api_invoke_url/api/contact` - validates the body, then emails the site owner through SES.

    ```
    curl -X POST "$(terraform output -raw contact_endpoint)" \
    -H 'Content-Type: application/json' \
    -d '{"senderName":"Ada","senderEmail":"ada@example.org","senderSubject":"Hello","senderMessage":"Nice site!"}'
    ```

## Best Practices

***

- **Error Handling**: Always include robust error handling in your applications.
- **Email Validation**: Ensure that email addresses are valid before sending.
- **Throttling**: Be aware of your SES sending limits to avoid throttling.
- **Unsubscribe Links**: Include unsubscribe options in marketing emails to comply with regulations.
- **Monitoring**: Use AWS CloudWatch to monitor your email sending activities.
- **Security**: Protect your AWS credentials and use IAM roles where possible.

## Cleanup

***

To destroy all resources, run ```terraform destroy -var-file="terraform.tfvars" -auto-approve```

## Summary

***

This project provides a fully automated, serverless backend solution for handling website contact form submissions using
**Spring Boot 4** and **Java 21** deployed on **AWS Lambda**.

By leveraging **Terraform** for Infrastructure-as-Code (IaC) and **GitHub Actions** with **OIDC** for continuous
deployment, the entire infrastructure stack—including **API Gateway**, **Lambda**, **AWS SES**, **KMS**, and
**CloudWatch** monitoring—is provisioned reliably and reproducibly.

**Key Highlights:**

* **Serverless & Cost-Effective**: Eliminates the overhead of maintaining dedicated mail servers by offloading email
  delivery to AWS SES and execution to AWS Lambda.
* **Infrastructure-as-Code**: Enables fully automated deployment, configuration updates, and cleanup using Terraform
  modules.
* **Production-Ready Operations**: Built-in health checks (`/api/health`), robust CloudWatch logging, KMS encryption,
  and automated alert notifications via SNS for critical metrics.
