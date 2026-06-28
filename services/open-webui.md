# Open WebUI

## Purpose

Open WebUI provides a self-hosted web interface for interacting with large language models.

In this homelab, it is used as the primary local AI web interface and connects to Ollama running on the Windows desktop.

## Deployment

- **Host:** UGREEN DXP4800 Plus
- **Container name:** `open-webui`
- **Image:** `ghcr.io/open-webui/open-webui:main`
- **Deployment method:** Docker Compose via Portainer
- **Docker network:** `ai-net`
- **Published port:** `3002:8080`
- **Persistent data path:** `/volume1/docker/open-webui`

## Access

Open WebUI is reachable locally at:

```text
http://192.168.10.101:3002
```

A future friendly hostname may be configured through Pi-hole and Nginx Proxy Manager.

## Architecture

```text
User Browser
  ↓
Open WebUI container on NAS
  ↓
Ollama on Windows desktop
  ↓
Local LLM models
```

Ollama endpoint:

```text
http://192.168.10.100:11434
```

Configured in Compose as:

```yaml
environment:
  - OLLAMA_BASE_URL=http://192.168.10.100:11434
```

## Compose Notes

Current important configuration:

```yaml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    environment:
      - OLLAMA_BASE_URL=http://192.168.10.100:11434
    volumes:
      - /volume1/docker/open-webui:/app/backend/data
    ports:
      - 3002:8080
    restart: unless-stopped
    networks:
      - ai-net
```

## Watchtower

Open WebUI is opted into Watchtower automatic updates.

Label:

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=true
```

This means Watchtower may update Open WebUI during the weekly maintenance window.

## Current Local Models

Ollama on the Windows desktop has been used with models such as:

- DeepSeek-R1 14B
- Gemma 2 9B
- Llama 3.1 8B
- Qwen 2.5 7B
- Qwen 2.5 Coder 7B

Models are stored and executed on the desktop, not inside the Open WebUI container.

## Verification Commands

Check container status:

```bash
docker ps --filter name=open-webui
```

Check logs:

```bash
docker logs open-webui --tail 50
```

Verify Watchtower label:

```bash
docker inspect open-webui --format '{{json .Config.Labels}}'
```

Expected label:

```text
"com.centurylinklabs.watchtower.enable":"true"
```

Test Ollama from another machine:

```powershell
curl.exe http://192.168.10.100:11434/api/tags
```

## Troubleshooting

### Unable to Connect to Ollama

Verify:

- Ollama is running on the Windows desktop.
- The desktop IP address is still `192.168.10.100`.
- Ollama is listening on `0.0.0.0`, not only localhost.
- Windows firewall allows traffic to port `11434`.
- Open WebUI still has `OLLAMA_BASE_URL=http://192.168.10.100:11434` configured.

### Web Interface Unavailable

Verify:

- The `open-webui` container is running.
- Port `3002` is published on the NAS.
- The container is attached to `ai-net`.
- Browser access works at `http://192.168.10.101:3002`.

## Future Plans

- Add a friendly local DNS hostname such as `openwebui.home`.
- Add Nginx Proxy Manager reverse proxy support.
- Integrate SearXNG for web search.
- Add a RAG/document-library workflow.
- Document model selection and hardware limits.

## Notes

Open WebUI is part of the AI lab stack. It should remain separate from the media stack and continue using the `ai-net` Docker network.
