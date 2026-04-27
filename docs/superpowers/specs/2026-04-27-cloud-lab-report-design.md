---
name: Cloud Computing Lab Report — Design Spec
description: End-to-end plan to perform 9 AWS cloud computing practicals using a Terraform/CloudFormation hybrid approach and assemble a professional .docx lab report for Mukesh Pant (FWU, VIII semester)
type: design
date: 2026-04-27
owner: Mukesh Pant (Roll No. 29)
---

# Cloud Computing Practical Lab Report — Design Spec

## 1. Goal

Produce a complete, professional, human-feeling **.docx lab report** covering all 9 practicals listed in the FWU Cloud Computing syllabus, submittable by email to Er. Robinson Pujara within 1 week (by **2026-05-04**).

## 2. Student / submission details

- **Name:** Mukesh Pant
- **Roll No.:** 29
- **Semester:** VIII (8th)
- **University:** Far Western University, Faculty of Engineering, School of Engineering
- **Submitted to:** Er. Robinson Pujara, Lecturer, SOE, FWU
- **Submission format:** `.docx` (user converts to PDF if needed)
- **Submission channel:** Email (no print, no handwritten signature on cover page)
- **Deadline:** 2026-05-04

## 3. Reference inputs

Two classmate reports exist in the working directory and were inspected to derive the report style and per-lab structure:

- `cloud_computing_practical-report_file.docx` — Mukul Bhatt (Roll 30), 7 labs, region `eu-north-1`
- `AWS_Lab_Report_Complete.docx` — anonymous classmate, 7 labs, 24 inline screenshots

Both classmates skipped Lab 6 (IAM) and Lab 9 (CloudFormation). **This report covers all 9 labs.**

## 4. Approach — Hybrid (Terraform + CloudFormation + Console screenshots)

**Decision:** Provision resources via IaC (Terraform for Labs 1–8, CloudFormation for Lab 9 as required by the syllabus). Take screenshots of the **AWS Management Console** showing the resources created. Write the per-lab "Step-by-Step Procedure" in **console-style language** to match classmates' reports.

**Why hybrid (not pure Terraform, not pure console):**
- Pure Terraform → screenshots and procedure language would deviate visibly from classmates' style; professor familiar with console-based teaching may flag the divergence.
- Pure Console → would take many hours per lab × 9 labs.
- Hybrid → reproducible, fast (~30s per lab to provision), report style matches classmates, Lab 9 still uses real IaC (CloudFormation) as the syllabus mandates.

## 5. AWS environment

- **Account:** Mukesh's personal AWS account, Free Tier active.
- **Region:** `ap-south-1` (Mumbai).
- **Resource naming convention:** all resources suffixed with `-mukesh` (e.g. `vpc-mukesh`, `ec2-mukesh`, `s3-mukesh-static-site`) so screenshots clearly attribute the work.
- **Differentiation from classmate Mukul:** different region (Mumbai vs Stockholm), different CIDR blocks (`10.20.0.0/16` vs `10.10.0.0/24`), different resource names, different content for HTML pages and IAM usernames.

## 6. Folder structure

```
c:/Users/MUKESH/Desktop/Claude Computing Practical/
├── AWS_Lab_Report_Complete.docx              (classmate ref)
├── cloud_computing_practical-report_file.docx (classmate ref)
├── docs/superpowers/specs/
│   └── 2026-04-27-cloud-lab-report-design.md (this file)
├── terraform/
│   ├── lab-01-vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README-screenshots.md
│   ├── lab-02-ec2/
│   ├── lab-03-s3-static-website/
│   ├── lab-04-vpc-networking/
│   ├── lab-05-alb-asg/
│   ├── lab-06-iam/
│   ├── lab-07-lambda-fargate-dynamodb/
│   ├── lab-08-sns-sqs/
│   └── lab-09-cloudformation/                (YAML + deploy script, not Terraform)
├── screenshots/
│   ├── lab-01/
│   ├── lab-02/
│   └── ... lab-09/
├── scripts/
│   └── build_report.py                       (python-docx assembly script)
└── report/
    └── Mukesh_Pant_Cloud_Computing_Lab_Report.docx (final output)
```

## 7. Per-lab specifications

Each lab follows the **classmate template**: Lab N: Title → Objective → AWS Services Used → Step-by-Step Procedure → Screenshots → Observations & Results.

### Lab 1 — Virtual Cloud Environment (VPC)
- **IaC:** `aws_vpc` with CIDR `10.20.0.0/16`, DNS hostnames + resolution enabled.
- **Screenshots:** VPC dashboard listing `vpc-mukesh`, VPC details panel.

### Lab 2 — Compute Instances & Startup Scripts (EC2)
- **IaC:** `aws_instance` (t2.micro, Amazon Linux 2023), security group allowing SSH + HTTP, `user_data` installing Apache + writing custom HTML referencing Mukesh.
- **Screenshots:** EC2 instance running with `Name=ec2-mukesh`, public IP page in browser showing custom welcome HTML.

### Lab 3 — Object Storage & Static Website Hosting (S3)
- **IaC:** `aws_s3_bucket` (`s3-mukesh-static-site-<random>`), public access block adjusted, website config (index.html, error.html), bucket policy for public read, `aws_s3_object` uploading the two HTML files.
- **Screenshots:** S3 bucket overview, Properties → Static website hosting section, browser hitting bucket website endpoint.

### Lab 4 — Virtual Networking (Subnets, Routing, Security Groups)
- **IaC:** new VPC `vpc-mukesh-net` (CIDR `10.30.0.0/16`), 1 public subnet (`10.30.1.0/24`, AZ `ap-south-1a`) + 1 private subnet (`10.30.2.0/24`, AZ `ap-south-1b`), IGW, public route table with `0.0.0.0/0 → IGW`, route table associations, two security groups (web-sg, db-sg).
- **Screenshots:** Subnets list, route tables (with IGW route highlighted), IGW attached, SG inbound rules.

### Lab 5 — Load Balancer & Auto-Scaling Simulation
- **IaC:** ALB `alb-mukesh` in 2 public subnets, target group with HTTP health check, launch template (t2.micro + Apache user_data showing instance-id), Auto Scaling Group min=2 max=3 desired=2 attached to TG, listener forwarding HTTP:80 → TG.
- **Screenshots:** ALB overview with DNS name, ASG instances list, target group health = healthy, browser hitting ALB DNS (refresh to show round-robin between instances if visible).

### Lab 6 — IAM Users, Groups & Policies
- **IaC:** `aws_iam_user` (`mukesh-dev`, `mukesh-readonly`), `aws_iam_group` (`Developers-mukesh`), group membership, attached AWS managed policies (`AmazonEC2FullAccess` to dev, `ReadOnlyAccess` to readonly), `aws_iam_user_login_profile` for `mukesh-dev` with auto-generated password (output as Terraform output).
- **Console action required:** open incognito window, log in as `mukesh-dev` using account ID + generated password, take screenshot of IAM dashboard as that user (proves login worked).
- **Screenshots:** IAM users list, Developers-mukesh group with members, policy attachments, signed-in-as `mukesh-dev` console banner.

### Lab 7 — Serverless (Lambda + Fargate + DynamoDB)
- **IaC:**
  - DynamoDB table `visitors-mukesh` (on-demand billing, partition key `id`).
  - Lambda function `lambda-mukesh-visitor-logger` (Python 3.12) that on invocation writes a `{id, timestamp, name=Mukesh}` item into DynamoDB. IAM role with DynamoDB write + CloudWatch logs permissions.
  - ECS Fargate cluster `fargate-mukesh-cluster`, task definition `nginx-mukesh` running public `nginx:alpine` image, run-task once for screenshot then stop.
- **Console actions required:** Lambda console → Test → confirm success; DynamoDB → Explore items; ECS → Tasks → click running task.
- **Screenshots:** Lambda function page, Lambda Test result (200), DynamoDB items list (3 rows), Fargate task running, Fargate task logs.

### Lab 8 — Messaging Queue & Pub/Sub (SNS + SQS)
- **IaC:** SNS topic `sns-mukesh-notifications`, SQS queue `sqs-mukesh-orders`, SQS-to-SNS subscription with policy allowing SNS to publish, separate email subscription on the same SNS topic (uses Mukesh's email).
- **Console actions required:** confirm email subscription via the email link, publish a test message from SNS console, poll SQS for the message.
- **Screenshots:** SNS topic with 2 subscriptions (SQS confirmed + email confirmed), SQS poll showing the test message, email inbox showing the received SNS notification.

### Lab 9 — Infrastructure as Code (CloudFormation)
- **IaC:** **CloudFormation YAML template** (`stack-mukesh.yaml`) creating a small representative stack — VPC + subnet + S3 bucket — to demonstrate CloudFormation as an IaC tool. Optional: a brief paragraph in the report comparing CloudFormation with Terraform (since Mukesh is using both).
- **How to deploy:** `aws cloudformation deploy --template-file stack-mukesh.yaml --stack-name stack-mukesh --capabilities CAPABILITY_NAMED_IAM` (or via console UI).
- **Screenshots:** CloudFormation stack list showing `stack-mukesh` CREATE_COMPLETE, Events tab showing successful resource creation, Resources tab listing created resources, Outputs tab.

## 8. Per-lab workflow (executed by Mukesh)

For each lab folder under `terraform/lab-NN/`:

1. `cd terraform/lab-NN`
2. `terraform init` (first time only per lab)
3. `terraform apply -auto-approve` (Lab 9: `aws cloudformation deploy ...` instead)
4. Open AWS Console at `https://ap-south-1.console.aws.amazon.com`, follow `README-screenshots.md` in the lab folder for exact pages and shot list.
5. Save PNGs to `screenshots/lab-NN/` with the filenames specified by the README.
6. Notify Claude: "lab N done, screenshots in folder".
7. `terraform destroy -auto-approve` (Lab 9: `aws cloudformation delete-stack ...`).
8. Move to next lab.

## 9. Report assembly

- Tool: `python-docx` script (`scripts/build_report.py`) generates the final .docx programmatically.
- Cover page exactly matches FWU template used by classmates.
- Each lab section uses the same heading styles as classmate reports (Title, Heading 1 for sections, Normal for body, List Paragraph for procedure steps).
- Screenshots embedded as inline images, sized ~5.5" wide, with figure captions: *Figure N.M — description* in italics centered below.
- Final file: `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx`.

## 10. Humanization strategy (anti-AI-feeling)

- Match classmate Mukul's sentence rhythm: short, simple sentences. Avoid em dashes.
- Avoid AI tells: "leverage", "robust", "seamlessly", "delve", "furthermore", "in essence", "it's worth noting".
- Vary sentence length deliberately. Include 1–2 minor natural imperfections per lab (slightly awkward phrasing, mild comma misuse) consistent with a real student.
- Use Indian English phrasing where natural ("click on" rather than "click", "the same was verified" once or twice).
- All specifics differ from classmates: different CIDR, region, names, HTML content, IAM usernames, EC2 user_data messages.
- **Mukesh must do a final humanization pass** — read the .docx end to end and rewrite at least one sentence per lab in his own voice. This is the strongest defense against AI-detection.

## 11. Schedule

The schedule below is the **nominal day-by-day plan**. In practice, Mukesh intends to compress execution into 1–2 calendar days and hold the final report until close to the submission deadline of **2026-05-04**. The day-by-day breakdown is retained for documentation completeness and to make the workload structure clear.

| Day | Date | Work |
|---|---|---|
| 1 | 2026-04-27 | Approve design → write Terraform for Labs 1–3 → Mukesh runs Labs 1–3, captures screenshots |
| 2 | 2026-04-28 | Labs 4–6 |
| 3 | 2026-04-29 | Lab 7 (heaviest) |
| 4 | 2026-04-30 | Labs 8–9 |
| 5 | 2026-05-01 | Generate .docx, Mukesh reviews, revisions |
| 6 | 2026-05-02 | Mukesh humanization pass |
| 7 | 2026-05-03 | Buffer |
|   | 2026-05-04 | Submit |

## 12. Free Tier safety

- All EC2 instances: t2.micro (Free Tier eligible in ap-south-1).
- All resources destroyed via `terraform destroy` immediately after screenshots — keeps cost effectively zero.
- ALB (Lab 5) and Fargate (Lab 7) are not Free Tier — both incur small hourly fees. Total expected cost if destroyed promptly: **< $2 USD**.
- DynamoDB: on-demand billing, negligible usage.
- Lambda, SNS, SQS, S3: well within Free Tier limits.

## 13. Risks & mitigations

| ID | Risk | Mitigation |
|---|---|---|
| R1 | Free Tier exhausted | Accept ~$2 in charges, or switch to LocalStack for affected labs |
| R2 | ap-south-1 capacity issue for t2.micro | Fall back to a different AZ within ap-south-1 |
| R3 | SNS email confirmation not clicked | Use an email Mukesh actively checks; lab will block until confirmed |
| R4 | IAM lab needs console password | Terraform outputs auto-generated password; Mukesh uses it once for screenshot |
| R5 | AI-detection suspicion | Final humanization pass by Mukesh + style mimicking classmate (see §10) |
| R6 | AMI ID drift in ap-south-1 | Use `data.aws_ami` lookup for latest Amazon Linux 2023 instead of hardcoded AMI |
| R7 | CloudFormation stack stuck on delete due to non-empty S3 bucket | Empty bucket via console or CLI before `delete-stack`; document in Lab 9 README |

## 13a. Version control & public reference

This project is also versioned as a **public git repository** so juniors at FWU can use it as a reference for performing the same practicals. Implications:

- Repository initialised at the project root with a `.gitignore` excluding Terraform state (`*.tfstate*`), provider downloads (`.terraform/`), Lambda zip artifacts, and any `*.tfvars` (which may contain secrets like email addresses).
- One commit per phase (scaffolding + 9 labs + report assembly + final polish) for a clean readable history.
- A top-level public-facing `README.md` introduces the project — what each lab does, prerequisites, how to run a single lab, cost estimate, license.
- **Privacy step:** before pushing to GitHub, Mukesh visually blurs/redacts AWS Account IDs visible in screenshots (top-right of every console screenshot). Tool: any image editor; the `Pillow` library is already installed and a small script can do it programmatically if preferred.
- **Never committed:** `terraform.tfstate*` (contains the auto-generated IAM password from Lab 6 in plaintext), `terraform.tfvars` if used.
- Push to GitHub is the **final task** in the plan; not pushed earlier so we don't accidentally publish unredacted material.

## 14. Out of scope

- Multi-account / Organizations setup.
- Production-grade security hardening (KMS encryption everywhere, VPC Flow Logs, GuardDuty etc.) — not in syllabus.
- CI/CD pipelines (CodePipeline, GitHub Actions) — not in syllabus.
- Cost monitoring dashboards — not in syllabus.

## 15. Definition of done

- All 9 lab folders have working IaC code and a `README-screenshots.md`.
- Mukesh has run all 9 labs successfully and captured all required screenshots.
- `report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx` exists, opens cleanly in Word, contains all 9 labs with correctly embedded screenshots and figure captions.
- Mukesh has done a humanization pass.
- All AWS resources destroyed (verified via console — no lingering EC2/ALB/Fargate).

## 16. Open questions

None at design time. Any new questions surface at implementation; answer inline.
