#!/bin/bash
set -euxo pipefail

# Update system packages
dnf update -y

# Install nginx
dnf install -y nginx

# Create a hello world page
cat > /usr/share/nginx/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project_name} — Hello World</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.25rem; opacity: 0.9; margin-bottom: 0.5rem; }
        .meta {
            margin-top: 2rem;
            font-size: 0.9rem;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello, World!</h1>
        <p>Deployed with Terraform on AWS</p>
        <p>Project: <strong>${project_name}</strong></p>
        <div class="meta">
            <p>Instance launched at: <span id="time"></span></p>
        </div>
    </div>
    <script>
        document.getElementById('time').textContent = new Date().toISOString();
    </script>
</body>
</html>
HTMLEOF

# Enable and start nginx
systemctl enable nginx
systemctl start nginx
