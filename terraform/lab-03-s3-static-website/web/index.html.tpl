<!doctype html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${full_name} — S3 Static Website</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: Georgia, serif;
      background: #f0f4f8;
      color: #333;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: white;
      border-radius: 8px;
      padding: 48px 56px;
      max-width: 640px;
      text-align: center;
      box-shadow: 0 2px 12px rgba(0,0,0,0.1);
    }
    h1 { font-size: 2rem; margin-bottom: 12px; }
    .subtitle { font-size: 1.1rem; color: #555; margin-bottom: 24px; line-height: 1.6; }
    .badge {
      display: inline-block;
      background: #232f3e;
      color: #ff9900;
      padding: 6px 16px;
      border-radius: 4px;
      font-family: monospace;
      font-size: 0.9rem;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>${full_name}</h1>
    <p class="subtitle">
      ${institution} — ${faculty} &middot; Roll No. ${roll_number}<br>
      Cloud Computing Practical — Lab 3
    </p>
    <span class="badge">Hosted on Amazon S3 &middot; ${region}</span>
    <p class="subtitle" style="margin-top:24px; font-size:0.95rem;">
      This page is served from an S3 bucket configured for static website hosting.<br>
      No web server required.
    </p>
  </div>
</body>
</html>
