# Open WebUI Homelab Context Guide

This guide defines how the homelab repository can be used as a retrieval-augmented knowledge source for Open WebUI without exposing secrets.

## Goal

Enable local models to answer questions such as:

- Which containers use `media-net`?
- Where is the Seerr database stored?
- How is qBittorrent isolated behind Gluetun?
- What is the recovery procedure for Pi-hole or Watchtower?
- Which Compose file defines a particular port or volume?

## Recommended Source Content

Include:

- `README.md`
- `DASHBOARD.md`
- `docker/README.md`
- `docker/*/README.md`
- `docker/*/docker-compose.yml`
- `services/**/*.md`
- `networking/**/*.md`
- `troubleshooting/**/*.md`
- `changes/**/*.md`
- `architecture/**/*.md`
- `standards/**/*.md`

Exclude:

- `.git/`
- Real `.env` files
- Backups and database files
- Logs
- Exported credentials or tokens
- Temporary diagnostic files
- Binary files and media

## Security Rules

1. Only ingest content already safe for Git.
2. Never ingest a live NAS configuration directory directly.
3. Keep real `.env` files ignored and outside the repository.
4. Review Compose files for embedded tokens before every commit.
5. Treat generated AI answers as guidance, not as proof of the live state.

## Suggested Collection Structure

Create one Open WebUI knowledge collection named:

```text
Eddy Homelab
```

Use repository-relative filenames as document titles so citations remain useful.

Recommended grouping:

- `Architecture and indexes`
- `Docker stacks`
- `Service runbooks`
- `Networking`
- `Troubleshooting`
- `Change history`

## Ingestion Workflow

### Initial manual workflow

1. Pull the latest repository state.
2. Package or upload the approved Markdown and YAML files.
3. Add them to the `Eddy Homelab` collection.
4. Test known questions against the source documents.
5. Correct documentation when the model exposes gaps or contradictions.

### Future automated workflow

A future script should:

1. Pull or read the current Git checkout.
2. Select only approved paths and extensions.
3. Reject ignored or secret-bearing files.
4. Generate a manifest with file hashes.
5. Upload only new or changed documents.
6. Remove documents deleted from Git.
7. Record the ingestion time and commit SHA.

## Evaluation Questions

Use these questions after each ingestion refresh:

1. What network does Recyclarr use?
2. Which service owns port 8888?
3. Why is Watchtower rolling restart disabled?
4. Where is Plex configuration stored?
5. Which containers depend on Gluetun?
6. How is Pi-hole connected to the LAN?
7. What is the current top project in `DASHBOARD.md`?
8. How should a Docker stack change be deployed and documented?

An acceptable answer should cite the relevant repository documents and distinguish documented configuration from live verification.

## Prompt Guidance

A useful system instruction for the collection:

```text
Answer using the Eddy Homelab knowledge collection first. Cite the source file for configuration claims. Distinguish documented state from live runtime state. Never invent credentials, IP addresses, ports, commands, or recovery steps that are not supported by the documents. When documents conflict, identify the conflict and recommend live verification.
```

## Next Project Steps

- Confirm the Open WebUI version and current knowledge-base features.
- Choose manual upload or API-driven synchronization.
- Perform the initial ingestion.
- Run the evaluation questions above.
- Document refresh and rollback procedures after the workflow is proven.
