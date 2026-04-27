# Lab 3 — Object Storage & Static Website Hosting (S3)

## Apply

```bash
cd terraform/lab-03-s3-static-website
terraform init
terraform apply -auto-approve
```

Expected: 6 resources created. Outputs: `bucket_name`, `website_endpoint`, `website_url`.

## Screenshots to capture

1. **`screenshots/lab-03/3.1-bucket-overview.png`**
   S3 → Buckets list. Capture the row showing `mukesh-static-<id>` bucket with Region = `ap-south-1`.

2. **`screenshots/lab-03/3.2-static-hosting.png`**
   Click the bucket name → **Properties** tab → scroll to **Static website hosting** section.
   Capture the section showing Status = `Enabled` and the Bucket website endpoint URL.

3. **`screenshots/lab-03/3.3-browser-site.png`**
   Open `website_url` from Terraform outputs in a browser. Capture the full browser window
   showing the rendered "Mukesh Pant — S3 Static Website" card page (include URL bar).

## Destroy

`force_destroy = true` is set, so Terraform will empty the bucket automatically.

```bash
terraform destroy -auto-approve
```

Expected: 6 resources destroyed.
