\# Windows Laptop Health Check and Troubleshooting



\## System Information



Device:

\- Razer Blade 15 Mid-2019 Base Model



\## Objectives



\- Verify operating system integrity

\- Validate storage health

\- Investigate Samsung Magician warning

\- Resolve Apollo startup issues

\- Verify BitLocker and Secure Boot configuration



\## Operating System Integrity



\### DISM



```powershell

DISM /Online /Cleanup-Image /RestoreHealth

```



Result:

\- Completed successfully

\- No remaining image corruption



\### SFC



```powershell

sfc /scannow

```



Result:

\- No integrity violations detected



\## BIOS Verification



Current Version:

\- 1.03



Result:

\- Confirmed latest available BIOS revision



\## Secure Boot and BitLocker



Actions:

\- Disabled Secure Boot

\- Entered BitLocker recovery key

\- Verified successful boot

\- Confirmed recovery key backup to Microsoft account



Verification:



```powershell

manage-bde -status

```



Result:

\- TPM protector enabled

\- XTS-AES 256 encryption

\- Drive fully encrypted



\## Samsung SSD Health



Drive:

\- Samsung 970 EVO Plus 2TB



Actions:

\- Reviewed SMART statistics

\- Investigated Samsung Magician warning



Result:

\- No critical health issues identified



\## Apollo Streaming Client



Issue:

\- Apollo reported ViGEmBus missing



Resolution:

\- Removed existing installation

\- Reinstalled ViGEmBus

\- Rebooted system



Result:

\- Apollo launched successfully

\- Controller support restored



\## Lessons Learned



\- Secure Boot changes may trigger BitLocker recovery.

\- Always verify BitLocker recovery key availability before firmware or Secure Boot changes.

\- DISM and SFC should be run before deeper troubleshooting.

\- Driver issues can persist until a reboot is performed.

