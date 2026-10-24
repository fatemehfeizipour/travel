# Infrastructure (Terraform)

This folder defines all of the AWS infrastructure for the TravelEase contact form. For the project overview, architecture diagram and the request flow, see the [main README](https://github.com/fatemehfeizipour/travelease-serverless-contact-form-rebuild/blob/main/README.md).

- **Tool:** Terraform with the AWS provider (v6.x). Developed locally on 1.16, and the pipeline installs the latest release.
- **Region:** ca-central-1
- **State:** remote, in an S3 bucket with versioning and native locking
- **Resources:** 31 managed resources and 1 data source, across 9 AWS services

>  the output of `terraform state list` ![the output of `terraform state list`](`docs/screenshots/16-state-list.png`)

## Contents

1. [Folder layout](#folder-layout)
2. [What Terraform manages](#what-terraform-manages)
3. [Variables and secrets](#variables-and-secrets)
4. [State](#state)
5. [IAM model](#iam-model)
6. [Working with it locally](#working-with-it-locally)
7. [How changes reach AWS](#how-changes-reach-aws)
8. [Gotchas](#gotchas)
9. [Cost](#cost)
10. [Next for the infrastructure](#next-for-the-infrastructure)

## Folder layout

[↑ Back to contents](#contents)

The code is split by service, so each file answers one question.

| File | What it holds |
|---|---|
| `main.tf` | `terraform` block and the AWS provider |
| `state.tf` | S3 backend: bucket, state key, encryption, native locking |
| `variables.tf` | Input variables (notification email, SES sender, SES test recipient) |
| `dynamodb.tf` | The submissions table |
| `iam.tf` | The Lambda execution role, its trust policy, and its permissions policy |
| `lambda.tf` | The Lambda function and its environment variables |
| `arcive.tf` | The `archive_file` data source that zips the Lambda code |
| `cloudwatch.tf` | Log group, metric filters and the failure alarm |
| `ses.tf` | The sender and test recipient email identities |
| `github_oidc.tf` | The GitHub OIDC provider, the plan role and the apply role with their policies |
| API Gateway, S3, CloudFront and SNS files | The HTTP API (integration, route, stage, Lambda permission), the private website bucket and its policy, the CloudFront distribution, and the SNS topic and subscription |

## What Terraform manages

[↑ Back to contents](#contents)

| Service | Resources |
|---|---|
| API Gateway | HTTP API, integration, route (`POST /contact`), `$default` stage with throttling and CORS |
| CloudFront | Distribution, origin access control |
| S3 | Private website bucket, public access block, bucket policy, three uploaded site files |
| Lambda | Function and the permission that lets API Gateway invoke it |
| DynamoDB | Submissions table (on-demand, `submission_id` string as partition key) |
| SNS | Topic and email subscription |
| SES | Sender identity and test recipient identity |
| CloudWatch | Log group (3-day retention), two metric filters (failures, honeypot), failure alarm |
| IAM | Lambda role and policy, GitHub OIDC provider, plan role, apply role and its inline policies |

The `archive_file` data source zips the Lambda code on the machine running Terraform. It creates nothing in AWS.

## Variables and secrets

[↑ Back to contents](#contents)

Three variables hold email addresses. They are never committed.

| Variable | Used for |
|---|---|
| notification email | Where the business gets SNS notifications and alarm emails |
| SES sender | The verified address emails are sent from |
| SES test recipient | The verified address that stands in for a customer in the SES sandbox |

- **Locally:** set them in `terraform.tfvars`, which is listed in `.gitignore`.
- **In GitHub Actions:** set them as repository secrets named `TF_VAR_<variable name>` and pass them to the plan and apply steps as environment variables. Secrets are used rather than plain variables because the repository is public and the workflow logs are public.

## State

[↑ Back to contents](#contents)

- The state bucket is created by hand in the console, because Terraform cannot create the place its own state lives.
- Public access is blocked and versioning is on, so a bad write can be rolled back.
- Locking uses S3 native locking (`use_lockfile`), which writes a small `.tflock` file next to the state. No DynamoDB lock table is needed.
- Because state is remote, the laptop and the GitHub runner see the same picture of the infrastructure.

## IAM model

[↑ Back to contents](#contents)

| Role | Assumed by | Trust condition | Permissions |
|---|---|---|---|
| `travelease-lambda-role` | The Lambda service | Service principal | Put items in the table, publish to the topic, send from the sender identity, write to the log group |
| `travelease-github-actions-role` (plan) | GitHub Actions, any workflow from this repository | OIDC subject for this repository (StringLike) | `ReadOnlyAccess` plus a narrow policy to create and delete the state lock file |
| `travelease-github-apply-role` (apply) | GitHub Actions, only runs on `main` | OIDC subject for this repository and `refs/heads/main` (StringEquals) | One inline policy per service, each limited to this project's resources |

- A **trust policy** says who may assume a role. A **permissions policy** says what the role can do once assumed. Both are needed.
- The OIDC subject uses the repository **IDs** as well as names. I found this by printing the real token subject in a temporary debug step.
- IAM actions in the apply role are limited to roles and policies named `travelease-*`, which is why every IAM resource in the project follows that naming rule.
- A few list and describe actions (for example `logs:DescribeLogGroups` and `ses:GetIdentityVerificationAttributes`) cannot be limited to a resource, so they sit in one small read-only policy on all resources.

> **Screenshot placeholder:** the apply role's inline policies in the IAM console (`docs/screenshots/17-apply-role-policies.png`)

## Working with it locally

[↑ Back to contents](#contents)

From this folder:

```
terraform fmt        # tidy formatting (run before every commit, the pipeline checks it)
terraform init       # download providers and connect to the S3 backend
terraform validate   # check syntax
terraform plan       # preview changes, read it before applying
terraform apply      # make the changes
```

Before applying, decide what the last line of the plan should say. A plan that surprises you is the point at which to stop.

## How changes reach AWS

[↑ Back to contents](#contents)

1. Work on a new branch, never directly on `main`.
2. Run `terraform fmt` and `terraform plan` locally.
3. Push the branch and open a pull request. The **Check** workflow runs on every push, and the **Plan** workflow runs on the pull request.
4. Read the plan in the pull request.
5. Merge. The push to `main` starts the **Apply** workflow, which runs with the apply role.

Changes to the apply role's own permissions are the exception. The role cannot grant itself permissions it does not have yet, so those are applied once from a laptop, then committed and merged through the same pull request process. The plan on the pull request should then say "No changes".

## Gotchas

[↑ Back to contents](#contents)

- **Renaming an IAM policy replaces it.** A policy's ARN contains its name, so a rename destroys and recreates the policy and the attachment pointing at it (`# forces replacement`). Briefly, the role has no permissions.
- **Line endings.** Windows (CRLF) and the Linux runner (LF) hash files differently, which causes false changes in the plan. `.gitattributes` fixes line endings to LF.
- **Lambda zip.** The archive uses a fixed file mode, so the hash is the same on every machine.
- **Re-running a failed apply job.** It runs the code from that run's commit, not the latest fix. Merge the fix instead.
- **"Error acquiring the state lock" (HTTP 412).** Another run holds the lock, or a run that was cancelled or crashed left the `.tflock` file behind. Check the Actions tab for a running apply first. Only if nothing is running, remove the stale lock with `terraform force-unlock <lock ID>`. Do not use `-lock=false`, because it removes the protection.
- **`terraform init` vs `git init`.** Easy to mix up. A nested `.git` folder was created once by mistake and removed.

## Cost

[↑ Back to contents](#contents)

Everything here is pay per use and very low volume (on-demand DynamoDB, Lambda, HTTP API, SNS, SES, CloudFront and a few small S3 objects). The state file is tiny, so S3 state storage costs a fraction of a cent. A budget alert is on the to-do list.

## Next for the infrastructure

[↑ Back to contents](#contents)

- Checkov scan in the pipeline
- A condition limiting which policies the apply role may attach
- A custom domain with Route 53 and ACM
- Cognito for authentication and authorization
- The containerised version (Docker, ECS/Fargate, ALB, VPC, RDS), and the same stack in CloudFormation and CDK for comparison
