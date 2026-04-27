# Lab 2 — Compute Instances & Startup Scripts (EC2)

## Apply

```bash
cd terraform/lab-02-ec2
terraform init
terraform apply -auto-approve
```

After `apply`, **wait ~90 seconds** for `user_data` (yum + httpd + writing index.html) to finish before testing the URL.

Outputs printed: `instance_id`, `public_ip`, `public_url`, `ami_id`.

## Screenshots to capture

Open https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#Instances

1. **`screenshots/lab-02/2.1-ec2-running.png`**
   EC2 → Instances list. Capture the row for `ec2-mukesh` showing Instance state = `Running`, Status checks = `2/2 checks passed`, Public IPv4 visible.

2. **`screenshots/lab-02/2.2-ec2-details.png`**
   Click `ec2-mukesh` → Details tab. Capture: Instance type `t2.micro`, AMI ID, Security groups (`sg-mukesh-ec2`), Public IPv4, IAM role = blank, VPC = default (or whichever), AZ.

3. **`screenshots/lab-02/2.3-browser-welcome.png`**
   In a new browser tab open `http://<public_ip>` (use the value from Terraform output `public_url`). Wait until the page loads — you should see the orange "Hello from Mukesh's EC2 instance" page. Capture the full browser including the URL bar.

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: 2 resources destroyed (instance + security group).
