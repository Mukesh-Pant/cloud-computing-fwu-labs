# Lab 5 — Load Balancer & Auto-Scaling Simulation

⚠️ **Cost note:** ALB has a small hourly fee (~₹1.6/hour). Destroy promptly after capturing screenshots.

## Apply

```bash
cd terraform/lab-05-alb-asg
terraform init
terraform apply -auto-approve
```

This creates ~16 resources. **Total apply time ≈ 3–4 minutes** (ALB provisioning is the slow part).

After apply, **wait an additional 90 seconds** for the 2 ASG instances to boot, run user_data (Apache install), and pass ALB target-group health checks before opening the ALB URL.

Outputs printed: `alb_dns_name`, `alb_url`, `asg_name`.

## Screenshots to capture

1. **`screenshots/lab-05/5.1-alb-overview.png`**
   EC2 → Load Balancers → click `alb-mukesh`. Capture the Description tab (or details panel) showing DNS name, Scheme = `internet-facing`, VPC = `vpc-mukesh-alb`, Availability Zones = both subnets.

2. **`screenshots/lab-05/5.2-asg-instances.png`**
   EC2 → Auto Scaling groups → click `asg-mukesh` → **Instance management** tab. Capture both 2 instances with Lifecycle = `InService` and Health status = `Healthy`.

3. **`screenshots/lab-05/5.3-target-group-health.png`**
   EC2 → Target Groups → click `tg-mukesh` → **Targets** tab. Capture both targets with Health status = `healthy`.

4. **`screenshots/lab-05/5.4-browser-alb-1.png`**
   Open `alb_url` from Terraform outputs in a browser. Capture the page showing **Instance ID A** (e.g. `i-0abc...`) and its AZ.

5. **`screenshots/lab-05/5.5-browser-alb-2.png`**
   **Hard refresh** the page (Ctrl+F5) a few times until the displayed instance ID changes — this proves load balancing is working. Capture the page showing **Instance ID B** (different from screenshot 5.4).

   *Tip: if all refreshes show the same instance, try opening in an incognito window or wait a few seconds and refresh again — ALB uses round-robin per connection.*

## Destroy

```bash
terraform destroy -auto-approve
```

Expected: 16 resources destroyed. **Verify in console** that no ALB or instances remain.
