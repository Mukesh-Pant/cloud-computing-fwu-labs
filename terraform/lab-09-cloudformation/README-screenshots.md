# Lab 9 — Infrastructure as Code (CloudFormation)

> Note: this lab folder lives under `terraform/` for consistency with the rest
> of the project, but the lab itself uses **AWS CloudFormation**, not Terraform
> — that's what the syllabus requires for IaC topic.

## Deploy

You can deploy via CLI or Console. Both work; pick whichever you prefer.

### Option A — CLI (faster)

```bash
cd terraform/lab-09-cloudformation
aws cloudformation deploy \
  --template-file stack-mukesh.yaml \
  --stack-name stack-mukesh \
  --region ap-south-1 \
  --capabilities CAPABILITY_NAMED_IAM
```

Wait for output: `Successfully created/updated stack - stack-mukesh`.

### Option B — Console

1. Open https://ap-south-1.console.aws.amazon.com/cloudformation/home?region=ap-south-1
2. Click **Create stack** → **With new resources (standard)**.
3. **Template source:** Upload a template file → choose `stack-mukesh.yaml` → Next.
4. **Stack name:** `stack-mukesh`. Leave parameter defaults (Owner = Mukesh, VpcCidr = 10.50.0.0/16) → Next.
5. Skip stack options → Next.
6. Acknowledge IAM capabilities checkbox → **Submit**.
7. Wait until status = `CREATE_COMPLETE` (about 30 seconds).

## Screenshots to capture

Open the CloudFormation console: https://ap-south-1.console.aws.amazon.com/cloudformation/home?region=ap-south-1

1. **`screenshots/lab-09/9.1-stack-list.png`**
   Stacks list showing `stack-mukesh` with Status = `CREATE_COMPLETE` (green).

2. **`screenshots/lab-09/9.2-stack-events.png`**
   Click `stack-mukesh` → **Events** tab. Capture the events list showing the lifecycle:
   `CREATE_IN_PROGRESS` for `CfnVpc` → `CREATE_COMPLETE` for `CfnVpc`,
   `CREATE_IN_PROGRESS` for `CfnBucket` → `CREATE_COMPLETE` for `CfnBucket`,
   and finally `CREATE_COMPLETE` for the stack itself.

3. **`screenshots/lab-09/9.3-stack-resources.png`**
   Click the **Resources** tab. Capture the table showing the 2 logical IDs (`CfnVpc`, `CfnBucket`), their physical IDs (the actual VPC ID `vpc-…` and bucket name `mukesh-cfn-<account-id>`), and resource types.

4. **`screenshots/lab-09/9.4-stack-outputs.png`**
   Click the **Outputs** tab. Capture the 4 outputs visible: `VpcId`, `VpcCidrOutput`, `BucketName`, `BucketArn`.

## Cleanup

The S3 bucket is empty (we never uploaded anything) so CloudFormation can delete it directly.

### Option A — CLI

```bash
aws cloudformation delete-stack --stack-name stack-mukesh --region ap-south-1
aws cloudformation wait stack-delete-complete --stack-name stack-mukesh --region ap-south-1
```

### Option B — Console

In Stacks → `stack-mukesh` → click **Delete** → confirm. Wait until the stack disappears from the list.

⚠️ If you ever upload something into the bucket later and the delete fails, empty the bucket first:
```bash
aws s3 rm s3://mukesh-cfn-<account-id>/ --recursive
```
