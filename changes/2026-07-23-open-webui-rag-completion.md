# Open WebUI RAG Completion

**Date:** 2026-07-23  
**Status:** Completed

## Summary

Completed the first working version of the homelab retrieval-augmented generation workflow in Open WebUI. The system now answers questions from the Git-backed homelab documentation and returns source-backed responses.

## Implemented

- Created the `Eddy Homelab` knowledge collection.
- Exported 77 approved documentation files while preserving repository hierarchy.
- Configured `sentence-transformers/all-MiniLM-L6-v2` for embeddings.
- Set chunk size to 1000 and overlap to 100.
- Enabled the Markdown Header Splitter.
- Disabled Hybrid Search for the initial baseline.
- Set Top K to 3.
- Created the `Homelab Assistant` using General Assistant backed by `llama3.1:8b`.
- Attached the `Eddy Homelab` collection.
- Enabled the Knowledge Base builtin tool and citations.
- Added a system prompt directing the assistant to use repository documentation as its primary source of truth.

## Problem Encountered

Document ingestion completed successfully, including embedding generation, vector collection updates, and knowledge-file linking. Despite that, chat responses remained generic and no query-time retrieval appeared in the logs.

The issue was not caused by:

- Markdown parsing
- Embedding generation
- Vector storage
- Knowledge-file attachment
- The selected Ollama model

## Resolution

The custom model's Function Calling setting was changed from inherited/default behavior to:

```text
Legacy
```

After saving the model and starting a new chat, Open WebUI immediately began retrieving repository content and displaying source references.

For this validated Open WebUI 0.10.2 and Ollama configuration, `Legacy` is a required compatibility setting.

## Validation

Regression question:

```text
What network does Recyclarr use?
```

Expected and received answer:

```text
media-net
```

The successful response cited repository documents, proving the assistant used retrieved context rather than general model knowledge.

## Rollback

No live infrastructure configuration was changed outside Open WebUI application settings and knowledge data.

To disable the RAG workflow:

1. Remove `Eddy Homelab` from the custom model.
2. Disable the Knowledge Base builtin tool.
3. Delete the custom `Homelab Assistant` if it is no longer required.
4. Leave the underlying Open WebUI and Ollama services unchanged.

## Operational Notes

- Refresh the collection after material repository updates.
- Re-run the Recyclarr regression question after every refresh.
- Revalidate Function Calling remains `Legacy` after Open WebUI upgrades.
- Review exported files before upload to prevent credentials or live secrets from entering the collection.

## Related Documentation

- `ai/open-webui-homelab-context.md`
- `DASHBOARD.md`
- `README.md`
