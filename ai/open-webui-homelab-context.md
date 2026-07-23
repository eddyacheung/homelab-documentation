# Open WebUI Homelab RAG Operations Guide

This guide documents the completed Open WebUI retrieval-augmented generation workflow used to answer questions from the version-controlled homelab repository.

## Status

**Phase 1 complete:** 2026-07-23

The `Eddy Homelab` knowledge collection is populated, attached to a dedicated assistant, and validated with source-backed answers.

## Architecture

```text
GitHub homelab documentation
        |
        v
PowerShell export workflow
        |
        v
Approved Markdown/YAML files
        |
        v
Open WebUI knowledge collection
        |
        v
Embeddings and vector index
        |
        v
Homelab Assistant
```

## Components

### Open WebUI

- Host: UGREEN NAS
- Container image: `ghcr.io/open-webui/open-webui:main`
- Validated version: `0.10.2`
- Persistent data: `/volume1/docker/open-webui`

### Ollama

- Host: Windows desktop with NVIDIA RTX 4070
- Endpoint: `http://192.168.10.100:11434`
- Assistant base model: `General Assistant`
- Underlying Ollama model: `llama3.1:8b`

### Embeddings and retrieval

- Embedding model: `sentence-transformers/all-MiniLM-L6-v2`
- Chunk size: `1000`
- Chunk overlap: `100`
- Markdown Header Splitter: enabled
- Hybrid Search: disabled
- Top K: `3`

## Knowledge Collection

- Name: `Eddy Homelab`
- Description: `Version-controlled homelab documentation.`
- Current initial export: 77 files

Use repository-relative paths and filenames so citations identify the source document clearly.

## Export Workflow

The repository contains the following export structure:

```text
RAG/
├── export.ps1
├── include.txt
├── exclude.txt
└── output/
```

The export script:

1. Clears the previous export.
2. Reads the include and exclude rules.
3. Copies approved files into `RAG/output/`.
4. Preserves the repository folder hierarchy.
5. Prevents unrelated or sensitive files from entering the upload set.

### Approved source content

Typical included content:

- `README.md`
- `DASHBOARD.md`
- `architecture/`
- `changes/`
- `docker/`
- `networking/`
- `services/`
- `standards/`
- `troubleshooting/`

### Excluded content

Never ingest:

- `.git/`
- Real `.env` files
- Credentials, tokens, or secrets
- Backups and database files
- Logs
- Temporary diagnostics
- Binary media
- `RAG/output/` as an input source

## Homelab Assistant Configuration

Create or maintain a custom model named `Homelab Assistant` with:

- Base model: `General Assistant`
- Knowledge: `Eddy Homelab`
- Knowledge Base builtin tool: enabled
- Citations: enabled
- Function Calling: `Legacy`

Recommended system prompt:

```text
You are my personal homelab assistant.

Use the attached homelab documentation as the primary source of truth.
Always search the attached knowledge base before answering technical questions.
When an answer comes from the documentation, answer naturally and reference the relevant source.
If the documentation does not contain the answer, state that clearly before using general knowledge.
If documentation conflicts with prior knowledge, trust the documentation and identify the conflict.
```

## Critical Compatibility Setting

### Function Calling must be set to Legacy

With this Open WebUI and Ollama configuration, `Native` and inherited `Default` behavior did not invoke knowledge retrieval reliably.

Observed symptoms:

- Generic model answers despite attached knowledge
- No retrieval or vector-search activity after questions
- Correct ingestion logs but no query-time retrieval
- The assistant claimed it lacked environment-specific information

Changing the custom model to:

```text
Function Calling: Legacy
```

immediately enabled retrieval, source citations, and correct answers.

After changing Function Calling, save the model and start a new chat before testing.

## Validation

Primary regression question:

```text
What network does Recyclarr use?
```

Expected documented answer:

```text
media-net
```

A successful response should:

- Answer `media-net`
- Display source references or citations
- Use repository content rather than generic model knowledge
- Avoid inventing unsupported configuration

Additional evaluation questions:

1. Which service owns port 8888?
2. Why is Watchtower rolling restart disabled?
3. Where is Plex configuration stored?
4. Which containers depend on Gluetun?
5. How is Pi-hole connected to the LAN?
6. What is the current top project in `DASHBOARD.md`?
7. How should a Docker stack change be deployed and documented?

## Refresh Procedure

Whenever repository documentation changes:

1. Pull or confirm the latest repository state.
2. Run `RAG/export.ps1`.
3. Review `RAG/output/` for unexpected or sensitive files.
4. Refresh the files in the `Eddy Homelab` knowledge collection.
5. Start a new Homelab Assistant chat.
6. Run the Recyclarr regression question.
7. Confirm citations point to the expected repository documents.

The current workflow is manual. Automated hash-based synchronization remains a future enhancement.

## Troubleshooting

### Knowledge imports but answers remain generic

Verify, in order:

1. `Eddy Homelab` is attached to `Homelab Assistant`.
2. Knowledge Base is enabled under Builtin Tools.
3. Function Calling is explicitly set to `Legacy`, not `Default` or `Native`.
4. The model was saved after the change.
5. Testing occurs in a new chat.
6. The knowledge collection still contains the exported documents.

### Ingestion diagnostics

Healthy ingestion logs include messages similar to:

- `generating embeddings`
- `embeddings generated`
- `adding to collection`
- `added ... items`
- `Linked file ... to knowledge`

These messages prove import and indexing, but not query-time retrieval. Successful query-time behavior is confirmed by a cited answer from the Homelab Assistant.

### Upgrade checklist

After every Open WebUI upgrade:

- Confirm the knowledge collection still exists.
- Confirm the assistant still has `Eddy Homelab` attached.
- Confirm Function Calling remains `Legacy`.
- Confirm the embedding model and retrieval settings are unchanged.
- Start a new chat and ask the Recyclarr regression question.

## Security Rules

1. Only ingest content already considered safe for Git.
2. Never ingest live NAS configuration directories directly.
3. Keep real `.env` files outside Git and the RAG export.
4. Review exported files before upload.
5. Treat AI answers as documentation-assisted guidance, not proof of live runtime state.
6. Verify consequential changes against the running system before implementation.

## Future Enhancements

- Automate changed-file synchronization using hashes and commit SHAs.
- Record the last successful ingestion commit.
- Evaluate stronger embedding models only after establishing retrieval benchmarks.
- Add automated RAG regression tests.
- Split collections only if retrieval quality degrades as the repository grows.
