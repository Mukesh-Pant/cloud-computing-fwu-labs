# Lab 4 — Virtual Networking (Subnets, Routing, Security Groups)

## Apply

```bash
cd terraform/lab-04-vpc-networking
terraform init
terraform apply -auto-approve
```

Expected: 11 resources created (VPC + IGW + 2 subnets + 2 route tables + 2 RT associations + 2 SGs + the implicit RT default route).

## Screenshots to capture

Open https://ap-south-1.console.aws.amazon.com/vpcconsole/home?region=ap-south-1#

1. **`screenshots/lab-04/4.1-vpc-overview.png`**
   VPC dashboard → click `vpc-mukesh-net` → details panel showing CIDR `10.30.0.0/16`, DNS hostnames Enabled.

2. **`screenshots/lab-04/4.2-subnets.png`**
   Left menu → **Subnets**. Filter by VPC = `vpc-mukesh-net`. Capture both subnets visible: `subnet-mukesh-public` (10.30.1.0/24, ap-south-1a) and `subnet-mukesh-private` (10.30.2.0/24, ap-south-1b).

3. **`screenshots/lab-04/4.3-route-table-public.png`**
   Left menu → **Route tables**. Click `rt-mukesh-public` → **Routes** tab. Capture both routes visible:
   - `10.30.0.0/16 → local`
   - `0.0.0.0/0 → igw-...` (Internet Gateway)

4. **`screenshots/lab-04/4.4-igw-attached.png`**
   Left menu → **Internet gateways**. Capture the row for `igw-mukesh` showing State = `Attached` and the VPC ID matches `vpc-mukesh-net`.

5. **`screenshots/lab-04/4.5-sg-web-rules.png`**
   Left menu → **Security groups** (or EC2 → Security Groups). Click `mukesh-web-sg` → **Inbound rules** tab. Capture the 2 rules: HTTP (80) and HTTPS (443) from `0.0.0.0/0`.

6. **`screenshots/lab-04/4.6-sg-db-rules.png`**
   Click `mukesh-db-sg` → **Inbound rules** tab. Capture the rule: MySQL (3306) sourced from `mukesh-web-sg` (security group reference, not a CIDR).

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: 11 resources destroyed.
