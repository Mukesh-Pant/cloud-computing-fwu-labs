#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable --now httpd

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /var/www/html/index.html <<HTML
<!doctype html>
<html>
<head>
  <title>${display_name} ALB Demo</title>
  <style>
    body { font-family: system-ui; text-align: center; padding-top: 80px; background: #232f3e; color: white; }
    h1 { color: #ff9900; }
    .info { font-family: monospace; background: rgba(255,255,255,0.1); padding: 16px; display: inline-block; border-radius: 6px; margin-top: 12px; }
  </style>
</head>
<body>
  <h1>${display_name} ALB Demo &mdash; Lab 5</h1>
  <p>FWU Cloud Computing &middot; Roll No. ${roll_number}</p>
  <div class="info">
    <p>Served by instance: <strong>$INSTANCE_ID</strong></p>
    <p>Availability Zone: <strong>$AZ</strong></p>
  </div>
  <p style="margin-top:24px;">Refresh the page to see load balancing across the ASG.</p>
</body>
</html>
HTML
