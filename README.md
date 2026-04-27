# AWS Cloud Computing — Practical Lab Reference

End-to-end lab work for the **Cloud Computing** subject of the
**B.E. Computer Engineering (VIII Semester)** programme at
**Far Western University, Faculty of Engineering**. All 9 syllabus practicals
provisioned via Infrastructure as Code (Terraform + CloudFormation) with
console screenshots and a compiled lab report.

> Author: **Mukesh Pant** · Roll No. 29 · VIII Semester
> Subject Lecturer: Er. Robinson Pujara, SOE, FWU
> Region used: `ap-south-1` (Mumbai)

Shared publicly so juniors can use it as a reference for performing the same
practicals on their own AWS accounts.

---

## Labs covered

| # | Lab | IaC tool | Key AWS services |
|---|-----|----------|------------------|
| 1 | Virtual Cloud Environment (VPC)              | Terraform      | VPC |
| 2 | Compute Instances & Startup Scripts (EC2)    | Terraform      | EC2, AMI, Security Groups |
| 3 | Object Storage & Static Website Hosting      | Terraform      | S3 |
| 4 | Virtual Networking — Subnets, Routing, SGs   | Terraform      | VPC, Subnets, Route Tables, IGW, SG |
| 5 | Load Balancer & Auto-Scaling Simulation      | Terraform      | ALB, Target Groups, Launch Template, ASG |
| 6 | IAM Users, Groups & Policies                 | Terraform      | IAM Users, Groups, Managed Policies |
| 7 | Serverless (Lambda + Fargate + DynamoDB)     | Terraform      | Lambda, ECS Fargate, DynamoDB, IAM, CloudWatch |
| 8 | Messaging Queue & Pub/Sub (SNS + SQS)        | Terraform      | SNS, SQS |
| 9 | Infrastructure as Code                       | CloudFormation | CloudFormation, VPC, S3 |

Every lab folder contains:
- `*.tf` (or `*.yaml` for Lab 9) — the Infrastructure as Code definition
- `README-screenshots.md` — exact list of console screenshots to capture
- `provider.tf`, `variables.tf`, `outputs.tf` — shared Terraform structure

---

## Prerequisites

You'll need:

- An **AWS account** (Free Tier is sufficient — total cost for running all 9
  labs back-to-back and destroying promptly is typically **under USD 2**).
- **Terraform 1.6+** — install from
  [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI v2**, configured via `aws configure` with credentials that have
  admin (or near-admin) permissions for the duration of the labs.
- Region default `ap-south-1` (`aws configure set region ap-south-1`).
- **Python 3.11+** with `python-docx` and `Pillow`
  (`pip install python-docx Pillow`) — only required if you want to rebuild
  the lab report yourself.

---

## How to run a single lab

Pick any lab folder under `terraform/`, then:

```bash
cd terraform/lab-01-vpc
terraform init
terraform apply -auto-approve

# Take screenshots per the lab's README-screenshots.md, save into screenshots/lab-01/

terraform destroy -auto-approve
```

Lab 8 needs your email at apply time (so SNS can deliver):

```bash
cd terraform/lab-08-sns-sqs
terraform apply -auto-approve -var="subscriber_email=you@example.com"
```

Lab 9 uses CloudFormation, not Terraform:

```bash
cd terraform/lab-09-cloudformation
aws cloudformation deploy \
  --template-file stack-mukesh.yaml \
  --stack-name stack-mukesh \
  --region ap-south-1 \
  --capabilities CAPABILITY_NAMED_IAM
# Cleanup:
aws cloudformation delete-stack --stack-name stack-mukesh --region ap-south-1
```

---

## How to rebuild the lab report

The compiled report at
`report/Mukesh_Pant_Cloud_Computing_Lab_Report.docx` is generated from the
script `scripts/build_report.py` plus the screenshots under `screenshots/`.

```bash
pip install python-docx Pillow
python scripts/build_report.py
```

To customise the report for yourself, edit the lab content dictionaries in
`scripts/build_report.py` (cover-page name, roll number, observations, etc.)
and re-run the script.

---

## Cost & cleanup

- **Always run `terraform destroy` after capturing screenshots.** The
  ALB (Lab 5) and Fargate task (Lab 7) accrue small hourly charges if left
  running.
- Most resources fall inside the AWS Free Tier (EC2 t2.micro, S3, Lambda,
  DynamoDB on-demand with tiny usage, SNS, SQS, CloudFormation).
- If you finish all 9 labs in a single sitting and clean up promptly, total
  out-of-pocket cost is typically **less than USD 2**.

---

## Repository layout

```
terraform/                   # one folder per lab (Lab 9 uses CloudFormation YAML)
├── lab-01-vpc/
├── lab-02-ec2/
├── lab-03-s3-static-website/
├── lab-04-vpc-networking/
├── lab-05-alb-asg/
├── lab-06-iam/
├── lab-07-lambda-fargate-dynamodb/
├── lab-08-sns-sqs/
└── lab-09-cloudformation/

screenshots/                 # AWS Console screenshots captured per lab
scripts/build_report.py      # python-docx report assembler
report/                      # compiled .docx lab report
docs/superpowers/            # design spec + step-by-step implementation plan
```

The `docs/superpowers/` directory captures the full process — design spec
and implementation plan — for anyone who wants to see how the project was
scoped and structured before any AWS resources were touched.

---

## License

MIT. Use it freely for your own learning. Attribution appreciated but not
required.

---

## Acknowledgements

- **Far Western University, Faculty of Engineering, School of Engineering**
- **Er. Robinson Pujara**, Lecturer (Cloud Computing) — for the practical
  curriculum that shaped this work.
