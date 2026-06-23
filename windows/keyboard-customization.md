# Keyboard Customization

## Lemokey P1 HE

### Greenshot Screenshot Mapping

#### Objective

Configure a dedicated screenshot key for Greenshot on the Lemokey P1 HE keyboard, which does not include a traditional Print Screen key in the preferred layout.

#### Environment

- Keyboard: Lemokey P1 HE
- Operating System: Windows 11
- Screenshot Utility: Greenshot
- Configuration Tool: Lemokey Launcher

#### Configuration

1. Verified Windows was not intercepting the Print Screen key.
   - Settings → Accessibility → Keyboard
   - Confirmed **Use the Print screen key to open screen capture** was disabled.

2. Opened Lemokey Launcher.

3. Selected Layer 0 (Windows layer).

4. Remapped:
   - **F12 → Print Screen (PrtSc)**

5. Verified functionality by pressing F12.
   - Greenshot immediately launched region capture mode.

#### Result

The F12 key now functions as a dedicated Print Screen key and triggers Greenshot region capture without requiring additional software such as Microsoft PowerToys.

#### Benefits

- Works directly from keyboard firmware.
- No background remapping software required.
- Configuration persists across reboots.
- Compatible with future Linux installations.
- Preserves existing Greenshot hotkey configuration.

#### Troubleshooting

Verify Greenshot hotkeys:

| Action | Hotkey |
|----------|----------|
| Capture Region | Print Screen |
| Capture Window | Alt + Print Screen |
| Capture Full Screen | Ctrl + Print Screen |

If screenshots stop working:

1. Verify F12 is still mapped to Print Screen in Lemokey Launcher.
2. Confirm Greenshot is running in the system tray.
3. Confirm Windows Print Screen screen-capture shortcut remains disabled.
4. Test the key using the Key Test feature in Lemokey Launcher.

#### Notes

The Lemokey Launcher applies keymap changes directly to the keyboard. Exported configurations can be used as backups but are not required to save changes.