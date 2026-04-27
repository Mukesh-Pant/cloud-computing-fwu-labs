#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable --now httpd
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <title>Mukesh's EC2 — Lab 2</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body { font-family: system-ui, sans-serif; text-align: center; padding-top: 80px; background: #f5f5f5; color: #222; }
    h1   { font-size: 2.4rem; margin-bottom: 10px; }
    p    { font-size: 1.1rem; margin: 6px; }
    .badge { display: inline-block; background: #ff9900; color: white; padding: 4px 10px; border-radius: 4px; font-weight: bold; }
  </style>
</head>
<body>
  <h1>Hello from Mukesh's EC2 instance</h1>
  <p class="badge">FWU Cloud Computing — Practical Lab 2</p>
  <p>Roll No. 29 &middot; Region: ap-south-1 (Mumbai)</p>
  <p>Apache served this page at boot via EC2 user_data.</p>
</body>
</html>
HTML
