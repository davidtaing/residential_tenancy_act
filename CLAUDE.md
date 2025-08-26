# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Setup project dependencies and database
mix setup

# Start the development server
mix phx.server

# Start with IEx shell
iex -S mix phx.server

# Run tests
mix test

# Build assets
mix assets.build

# Deploy assets (minified)
mix assets.deploy

# Database operations
mix ash.setup    # Setup Ash resources and database
mix ecto.setup   # Create, migrate, and seed database
mix ecto.reset   # Drop and recreate database
```

## Architecture Overview

This is an Elixir Phoenix LiveView application that provides a chatbot interface for querying Residential Tenancy Act information. The application uses the Ash framework for resource management and authentication.

### Core Domains

- **ResidentialTenancyAct.Accounts** - User management with magic link authentication
- **ResidentialTenancyAct.Acts** - RTA sections data and similarity search functionality
- **ResidentialTenancyAct.Chat** - Chat conversations, messages, and token/prompt history

### Key Components

**LLM Integration (`lib/residential_tenancy_act/llm/`)**
- AWS Bedrock integration for text generation and embeddings
- Prompt management for RTA queries and conversation titles
- Vector similarity search for relevant RTA sections

**Chat System (`lib/residential_tenancy_act/chat*/`)**
- Real-time chat interface using Phoenix LiveView
- Chat state management with `ChatStateServer` GenServer
- RAG (Retrieval-Augmented Generation) pipeline in `Chatbot` module

**Web Interface (`lib/residential_tenancy_act_web/`)**
- `ChatLive` - Main chat interface with real-time updates
- Authentication via Ash Authentication with magic links
- Responsive UI with sidebar navigation

### Data Flow

1. User sends message via ChatLive interface
2. ChatStateServer manages chat states (searching → generating → responding)
3. Chatbot performs RAG search against RTA sections using embeddings
4. LLM generates response with relevant context
5. Complete response updates user interface via LiveView

The application uses PostgreSQL with pgvector extension for vector similarity search of RTA sections.