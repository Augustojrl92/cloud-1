#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import subprocess

CONTAINERS = [
    "cloud1_mariadb",
    "cloud1_wordpress",
    "cloud1_nginx",
    "cloud1_phpmyadmin",
    "cloud1_cadvisor",
]


def inspect_container(name):
    try:
        result = subprocess.run(
            ["docker", "inspect", name],
            capture_output=True,
            text=True,
            check=True,
        )

        data = json.loads(result.stdout)[0]

        running = 1 if data["State"].get("Running", False) else 0

        health = data["State"].get("Health", {})
        status = health.get("Status", "none")

        healthy = 1 if status == "healthy" else 0

        return running, healthy

    except Exception:
        return 0, 0


def generate_metrics():
    lines = [
        "# HELP cloud1_container_running Docker container running state",
        "# TYPE cloud1_container_running gauge",
        "# HELP cloud1_container_healthy Docker container healthcheck state",
        "# TYPE cloud1_container_healthy gauge",
    ]

    for name in CONTAINERS:
        running, healthy = inspect_container(name)

        lines.append(
            f'cloud1_container_running{{name="{name}"}} {running}'
        )

        lines.append(
            f'cloud1_container_healthy{{name="{name}"}} {healthy}'
        )

    return "\n".join(lines) + "\n"


class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return

        body = generate_metrics().encode()

        self.send_response(200)
        self.send_header(
            "Content-Type",
            "text/plain; version=0.0.4"
        )
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()

        self.wfile.write(body)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 9105), MetricsHandler)
    server.serve_forever()
