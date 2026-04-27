# Lab 1 — Virtual Cloud Environment (VPC)

## Apply

```bash
cd terraform/lab-01-vpc
terraform init
terraform apply -auto-approve
```

Expected output: `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`
Outputs: `vpc_id` and `vpc_cidr` printed.

## Screenshots to capture

Open https://ap-south-1.console.aws.amazon.com/vpcconsole/home and take:

1. **`screenshots/lab-01/1.1-vpc-list.png`**
   VPC dashboard showing `vpc-mukesh` in the VPCs list with State = `Available`.
   Make sure the Region selector in the top-right shows **Asia Pacific (Mumbai) ap-south-1**.

2. **`screenshots/lab-01/1.2-vpc-details.png`**
   Click on `vpc-mukesh` → Details panel. Capture VPC ID, CIDR `10.20.0.0/16`, DNS hostnames = `Enabled`, DNS resolution = `Enabled`, Tenancy = `Default`.

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: `Destroy complete! Resources: 1 destroyed.`
