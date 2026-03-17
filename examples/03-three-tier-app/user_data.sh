#!/bin/bash
set -euxo pipefail

# Update system
dnf update -y
dnf install -y python3 python3-pip

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create a simple Python web application
cat > /opt/app/app.py <<'PYEOF'
#!/usr/bin/env python3
"""Simple HTTP application server for the three-tier example."""

import json
import os
import socket
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "appdb")

class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._respond(200, {"status": "healthy", "timestamp": datetime.utcnow().isoformat()})
        elif self.path == "/":
            self._respond(200, {
                "message": "Three-Tier App is running",
                "hostname": socket.gethostname(),
                "database": f"{DB_HOST}:{DB_PORT}/{DB_NAME}",
                "timestamp": datetime.utcnow().isoformat(),
            })
        else:
            self._respond(404, {"error": "not found"})

    def _respond(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body, indent=2).encode())

    def log_message(self, fmt, *args):
        pass  # Suppress default logging

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), AppHandler)
    print("Server listening on port 8080")
    server.serve_forever()
PYEOF

# Create systemd service
cat > /etc/systemd/system/app.service <<'SVCEOF'
[Unit]
Description=Three-Tier Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment="DB_HOST=${db_host}"
Environment="DB_PORT=${db_port}"
Environment="DB_NAME=${db_name}"
Environment="DB_USERNAME=${db_username}"
Environment="DB_PASSWORD=${db_password}"
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

# Enable and start
systemctl daemon-reload
systemctl enable app
systemctl start app
