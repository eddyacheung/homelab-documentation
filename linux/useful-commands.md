# Useful Linux Commands

## Service Management

Check service status:

```bash
systemctl status <service>
```

Restart service:

```bash
systemctl restart <service>
```

View service logs:

```bash
journalctl -u <service> -f
```

---

## Navigation

Current directory:

```bash
pwd
```

List files:

```bash
ls -lah
```

Change directory:

```bash
cd /path
```

Go back one directory:

```bash
cd ..
```

Go to home directory:

```bash
cd ~
```

---

## File Operations

Copy file:

```bash
cp source destination
```

Move file:

```bash
mv source destination
```

Delete file:

```bash
rm filename
```

Create directory:

```bash
mkdir directory
```

---

## Search

Find file:

```bash
find / -name filename 2>/dev/null
```

Search inside files:

```bash
grep -r "keyword" .
```

---

## Logs

View last 100 lines:

```bash
tail -100 logfile
```

Follow log in real time:

```bash
tail -f logfile
```

---

## Networking

View IP addresses:

```bash
ip addr
```

Test connectivity:

```bash
ping hostname
```

DNS lookup:

```bash
nslookup hostname
```

---

## Docker

Running containers:

```bash
docker ps
```

All containers:

```bash
docker ps -a
```

View logs:

```bash
docker logs container_name
```

Enter container shell:

```bash
docker exec -it container_name bash
```

Restart container:

```bash
docker restart container_name
```

---

## Vim

Search:

```text
/keyword
```

Next match:

```text
n
```

End of file:

```text
G
```

Save and quit:

```text
:wq
```

Quit without saving:

```text
:q!
```

---

## Commands I Learned While Building My Homelab

(Add commands here as I discover them.)
