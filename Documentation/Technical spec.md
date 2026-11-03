## Setting Up AWS SES using Lambda and API Gateway | Spring Boot Rest API and Terraform

AWS Simple Email Service (SES) is a cloud-based email sending service designed to help digital marketers and application
developers send marketing, notification, and transactional emails. It is a reliable, scalable, and cost-effective
service for businesses of all sizes.

### Key Features:

- **Scalability**: Handles large volumes of emails effortlessly.
- **Deliverability**: High deliverability rates due to AWS's reputation.
- **Cost-Effective**: Pay-as-you-go pricing model.
- **Security**: Supports authentication mechanisms like DKIM and SPF.

---

## Architecture overview

Here is the architecture diagram related to the scenario we are going to address.

![setting-up-asw-ses.png](../setting-up-asw-ses.png)

---

### Architecture Flow

* A user fills out the contact POST API request to the API Gateway endpoint.
* API Gateway invokes the Lambda function.
* Lambda calls SES to email the message to the site owner.
* Lambda returns a success or error response to the front end.

---

### Skills You’ll Practice

* Infrastructure as Code with Terraform
* Building serverless APIs with API Gateway and Lambda
* Verifying identities and sending email with Amazon SES
* Storing data in DynamoDB
* Applying least-privilege IAM policies
* Handling CORS and input validation for web forms

---

### Technology

* Java 21
* Spring Boot 4
* Maven
* AWS account
* Role and permission SES

---

## Implementation

### Set Up Amazon SES

- Create Identity to register the email you’ll use with SES `darvintojo@gmail.com`.
- Check that email inbox for a verification email from AWS.
- Encrypt SES with KMS
- Generate outputs

---

### Set Up Lambda function

***

- Give IAM Role for lambda function the permission to use Amazon SES, KMS.
- Create an IAM role to attach it to the function and grant it permissions (referred to as policies in AWS) to invoke
  the SES service, permissions to send emails using SES.
- Java Entity: senderName, senderEmail, senderSubject and senderMessage.

### Function configuration

| Setting            | Value                                                                                               |
|--------------------|-----------------------------------------------------------------------------------------------------|
| Function name      | `sesEmailBackend`                                                                                   |
| Description        | AWS Serverless Spring Boot 4 API                                                                    |
| Runtime            | Java 21                                                                                             |
| Architecture       | `x86_64`                                                                                            |
| Handler            | `com.ce.StreamLambdaHandler::handleRequest`                                                         |
| Memory             | 1024 MB (starting point; tune with measurements)                                                    |
| Timeout            | 30 seconds (effective limit through API Gateway is 29 seconds)                                      |
| Deployment package | JAR uploaded to the artifacts S3 bucket                                                             |
| Execution role     | `AWSLambdaBasicExecutionRole` + SES + KMS                                                           |
| Log group          | `SpringBoot_SESEmailBackend_Logs`, KMS-encrypted (set through the function's logging configuration) |
| Trigger            | API Gateway                                                                                         |
| Output             | all outputs for the resources                                                                       |

### Cold-start strategy

- **SnapStart** (`apply_on = PublishedVersions`): reduces Java cold starts from seconds to hundreds of milliseconds.
- Publish a version on every deployment (`publish = true`) and point the alias `lambda-dev` to it (`AutoPublishAlias`);
  API Gateway must invoke the **alias**, not `$LATEST`, otherwise SnapStart does not apply.
- Architecture is kept on `x86_64` for SnapStart compatibility; verify current ARM64 support in the AWS documentation
  before switching to Graviton.

---

### Set Up API Gateway

| Setting                | Value                                                                                                                                       |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| API type / name        | REST API, `sesEmailRestApi`                                                                                                                 |
| Endpoint configuration | `REGIONAL` (fronted by CloudFront)                                                                                                          |
| Resource / method      | `/{proxy+}` with method `ANY`                                                                                                               |
| Integration            | Lambda proxy integration targeting the `lambda-dev` alias                                                                                   |
| Stage                  | `dev` (new deployment on every API change)                                                                                                  |
| Access logs            | Log group `SpringBoot_SESEmailBackendApi_Logs`, KMS-encrypted                                                                               |
| Execution metrics      | Detailed metrics enabled on the stage                                                                                                       |
| Throttling             | Stage and method rate/burst limits to protect Lambda concurrency                                                                            |
| Caching                | Optional stage cache for read-heavy endpoints; a high hit rate (for example 90 %) cuts backend load roughly tenfold and reduces Lambda cost |
| Output                 | Invoke URL                                                                                                                                  |

---

### Set Up Amazon KMS

- Create Amazon KMS key to encrypt SES and CloudWatch Log group
- Update IAM role of Lambda function to add permission decrypt and encrypt
- Generate outputs

---

### Create Amazon CloudWatch Log group

- Create Log Group for Lambda Function
    - Name `SpringBoot_SESEmailBackend_Logs`
    - Metric Filters and Alarm for alert
    - Alerts when functions hit account/reserved concurrency limits.
    - Detects code exceptions, unhandled rejections, and runtime crashes.
    - High latency signals performance bottlenecks or imminent timeouts.
    - Prevents unexpected throttling across all regional services.
    - Function Timeouts `"Task timed out after"`
    - Out of Memory (OOM) Errors `{ $.status = "OOM" || $.message = "*Out of memory*" }`
    - Unhandled Code Exceptions / Panic `?"ERROR" ?"Error" ?"Exception" ?"Unhandled" ?"panic"`
    - Cold Start Tracking (From REPORT Logs) `[type="REPORT", ..., init_duration="Init Duration:"]`
- Create Log Group for Java Spring Boot application
    - Name `SpringBoot_ContactFormApi_Logs`
    - Metric Filters: Extract metrics from log patterns (ERROR, WARN)
        - Metric Filter for ERROR patterns
        - Metric Filter for WARNING patterns
- Create Log Group for API Gateway
    - Name `SpringBoot_SESEmailBackendApi_Logs`
    - Extract 4xx/5xx Errors by Specific Path or Endpoint
    - Severe Backend Delays (Latencies > Threshold)
    - High 5xx Server Errors `Critical: Triggers PagerDuty / OpsGenie`
    - Spike in 4xx Client Errors `Warning: Alert Slack or email team`
    - High Overall Latency `Warning: Indicates API bottleneck`
    - High Integration Latency `Warning: Backend dependency issue (Lambda/ECS/DB)`
    - API Throttling `Warning: Quotas or concurrency limits reached`
    - Error Rate: HTTP 4xx, 5xx errors per minute
    - High 4XX error rate → 'Alert when 5XX errors exceed threshold'
    - High 5XX error rate → 'Alert when 5XX errors exceed threshold'
- Generate outputs
