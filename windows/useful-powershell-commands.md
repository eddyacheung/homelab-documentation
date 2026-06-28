# Useful PowerShell Commands

A collection of Windows PowerShell commands frequently used for workstation troubleshooting and maintenance.

## Windows Health

Check Windows image health:

```powershell
DISM /Online /Cleanup-Image /RestoreHealth
```

Verify system files:

```powershell
sfc /scannow
```

## BIOS and Hardware

Show BIOS version and release date:

```powershell
Get-CimInstance Win32_BIOS |
Select SMBIOSBIOSVersion, ReleaseDate
```

Show computer manufacturer and model:

```powershell
Get-CimInstance Win32_ComputerSystem |
Select Manufacturer, Model
```

## Secure Boot

Check Secure Boot state:

```powershell
Confirm-SecureBootUEFI
```

## BitLocker

Check BitLocker status:

```powershell
manage-bde -status
```

## Installed Applications

List Start Menu applications:

```powershell
Get-StartApps
```

Search Start Menu applications by AppID:

```powershell
Get-StartApps | Where-Object {$_.AppID -match "TEXT"}
```

## Winget

Upgrade all available packages:

```powershell
winget upgrade --all
```

Upgrade a specific package:

```powershell
winget upgrade <package>
```

Install a package:

```powershell
winget install <package>
```

## Networking

Flush DNS cache:

```powershell
ipconfig /flushdns
```

Run a DNS lookup:

```powershell
nslookup hostname
```

Run a DNS lookup against a specific DNS server:

```powershell
nslookup hostname 192.168.10.250
```

Check HTTP headers:

```powershell
curl.exe -I http://hostname
```

## SSH

Connect to the NAS:

```powershell
ssh ugreen
```

Connect to the NAS by IP:

```powershell
ssh eddy.cheung@192.168.10.101
```

## Git and VS Code

Open the homelab documentation repository:

```powershell
cd C:\GitHub\homelab-documentation
code .
```

## Notes

- Use VS Code as the primary workspace for documentation and configuration files.
- Use the integrated terminal for Git Bash and SSH sessions.
- Prefer `ssh ugreen` followed by `sudo -i` or the `root` alias when administering the NAS.
- Avoid committing local SSH configuration or private keys to Git.
