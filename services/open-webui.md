# Open WebUI

## Overview

Open WebUI is a self-hosted web interface for interacting with Large Language Models (LLMs). It provides a ChatGPT-like experience while allowing models to run locally or connect to remote AI providers.

In this homelab, Open WebUI serves as a central platform for experimenting with AI workloads, testing local language models, and evaluating self-hosted alternatives to commercial AI services.

## Key Features

* ChatGPT-style web interface
* Multi-user support
* Conversation history and organization
* File upload and document analysis
* Integration with Ollama
* Integration with OpenAI-compatible APIs
* Model management and selection
* Role-based access controls

## Use Cases

### Local AI

Run local models through Ollama without sending prompts to external services.

Examples:

* General knowledge questions
* Linux troubleshooting
* Documentation assistance
* Script generation
* Homelab planning

### Remote AI Providers

Connect Open WebUI to external providers when larger or more capable models are required.

Benefits:

* Access to advanced reasoning models
* Unified interface for multiple providers
* Centralized chat history

## Architecture

```text
User Browser
      |
      v
+----------------+
|  Open WebUI    |
+----------------+
      |
      +------------+
      |            |
      v            v
   Ollama     External APIs
(Local LLMs)   (Cloud Models)
```

## Deployment Notes

Containerized using Docker.

Key considerations:

* Persistent storage for configuration and chat history
* Reverse proxy integration for secure remote access
* HTTPS recommended when exposed externally
* Regular image updates for security and feature improvements

## Benefits to Homelab Learning

Open WebUI provides hands-on experience with:

* Containerized AI applications
* Reverse proxy configuration
* GPU acceleration concepts
* API integrations
* Self-hosted services
* AI workflow experimentation

## Maintenance

### Update Container

```bash
docker compose pull
docker compose up -d
```

### Review Logs

```bash
docker logs open-webui
```

### Verify Container Status

```bash
docker ps
```

## Troubleshooting

### Unable to Connect to Ollama

Verify:

* Ollama container is running
* Containers share a network
* Correct Ollama URL is configured

### Web Interface Unavailable

Verify:

* Container is running
* Published ports are correct
* Reverse proxy configuration is functioning
* DNS records resolve correctly

```
```

