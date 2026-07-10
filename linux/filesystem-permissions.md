# Linux Filesystem Permissions

Last updated: 2026-07-09

## Purpose

This runbook provides a reusable method for diagnosing and correcting Linux ownership and permission problems affecting Docker bind mounts, media libraries, shared folders, and service accounts.

## Permission Model

Each file and directory has:

- An owner user
- An owner group
- Permissions for the owner
- Permissions for the group
- Permissions for everyone else

Permission letters:

- `r` = read
- `w` = write
- `x` = execute

For directories, `x` means the user can traverse or enter the directory. A service may have permission to read a file but still be unable to reach it if any parent directory lacks execute permission.

## Common Numeric Modes

| Mode | Meaning | Typical use |
|---|---|---|
| `644` | Owner read/write; everyone else read | Regular configuration files |
| `664` | Owner/group read/write; others read | Shared group-managed files |
| `755` | Owner full access; others read/traverse | Publicly readable directories and scripts |
| `775` | Owner/group full access; others read/traverse | Shared application directories |
| `770` | Owner/group full access; no access for others | Private shared data |
| `2770` | Same as `770`, plus setgid | Private shared directory where new items should inherit the directory group |

## Ownership Commands

Show your current identity and groups:

```bash
id
groups
```

Show ownership and permissions on a path:

```bash
ls -ld /path/to/directory
ls -lah /path/to/directory
stat /path/to/file
```

Change owner and group:

```bash
sudo chown user:group /path
```

Change only the group:

```bash
sudo chgrp group /path
```

Change permissions:

```bash
sudo chmod 2770 /path
```

Avoid recursive `chown` or `chmod` commands until the scope and consequences have been reviewed. Recursive changes can alter thousands of files and may break applications that rely on specific ownership.

## Best Diagnostic Command: `namei`

Inspect every directory component in a path:

```bash
namei -l "/path/to/directory/file.mkv"
```

Example output:

```text
drwxr-xr-x root root /
drwxr-xr-x root root volume2
drwxrwx--- root root Media
drwxrwxrwx user admin tv
-rw-rw-r-- user admin episode.mkv
```

If the service account is not the owner, not in the owning group, and the `other` permission lacks `x`, it cannot traverse that directory.

## Inspecting a Directory Tree

List directory permissions and ownership to a limited depth:

```bash
find /path -maxdepth 2 -type d -printf "%M %u %g %p\n" | sort
```

This is useful for identifying one directory whose ownership differs from the rest of the tree.

## Docker Bind-Mount Permissions

Docker bind mounts do not bypass host filesystem permissions. The process inside the container must have permission to access the host path.

Inspect container mounts:

```bash
docker inspect container_name --format '{{json .Mounts}}' | jq
```

Check the default identity used by `docker exec`:

```bash
docker exec container_name id
```

Important: `docker exec` commonly runs as root unless `-u` is specified. A test that succeeds as root does not prove the application process can access the path.

Test with the application's actual UID and GID:

```bash
docker exec -u UID:GID container_name ls -lah /mounted/path
```

Example:

```bash
docker exec -u 1001:10 plex ls -lah /media
```

## LinuxServer Containers

LinuxServer.io containers commonly use `PUID` and `PGID` environment variables. These should correspond to a host user and group that can access the mounted directories.

Check the configured or effective IDs:

```bash
docker logs container_name | head -50
docker exec container_name id
```

The application may run as a non-root user even though container initialization begins as root.

## Safe Troubleshooting Workflow

1. Confirm the file exists on the host.
2. Inspect the container bind mount.
3. Identify the application's UID and GID.
4. Use `namei -l` on the full host path.
5. Test access using `docker exec -u UID:GID`.
6. Change only the specific directory ownership or permissions blocking access.
7. Restart the affected service if it needs to reopen paths.
8. Verify that new permission errors are no longer appearing.

## Case Study: Plex Playback Failure

### Symptoms

- A television episode failed in both Infuse and the Plex Apple TV app.
- The file existed and could be listed from the NAS host.
- A root-level `docker exec` test could read the file.
- Plex logged:

```text
boost::filesystem::status: Permission denied [system:13]
```

### Investigation

Plex mounted the media library as:

```text
/volume2/Media -> /media:ro
```

Plex ran as:

```text
UID 1001
GID 10 (admin)
```

The complete path inspection showed:

```text
drwxr-xr-x root root /
drwxr-xr-x root root volume2
drwxrwx--- root root Media
drwxrwxrwx eddy.cheung admin tv
```

The top-level `/volume2/Media` directory blocked Plex because it was owned by `root:root` with no permissions for other users.

### Resolution

Change the directory group to `admin`, enable group access, and set the setgid bit:

```bash
sudo chgrp admin /volume2/Media
sudo chmod 2770 /volume2/Media
docker restart plex
```

Result:

```text
drwxrws--- root admin /volume2/Media
```

### Verification

Test access using Plex's actual runtime identity:

```bash
docker exec -u 1001:10 plex ls -lh "/media/tv/Your Friends & Neighbors/Season 2/"
```

Check for new permission errors:

```bash
docker exec plex grep -i "Permission denied" \
  "/config/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log" | tail -20
```

Playback succeeded after the permission correction and Plex restart.

## Why `2770` Was Used

- Owner: `rwx`
- Group: `rwx`
- Others: no access
- Leading `2`: setgid on the directory

The setgid bit causes newly created child files and directories to inherit the directory's group, helping keep shared application data consistently associated with `admin`.

## Lessons Learned

- File permissions alone do not guarantee access; every parent directory must be traversable.
- Tests run as container root may hide the application's real permission problem.
- `namei -l` is often the fastest command for diagnosing path traversal failures.
- Prefer targeted ownership and permission changes over broad recursive commands.
- Record the expected UID, GID, owner, group, and mode for important bind-mounted directories.
