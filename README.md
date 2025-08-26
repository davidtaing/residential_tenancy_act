# Residential Tenancy Act Chatbot

An intelligent chatbot application that helps users navigate and understand Residential Tenancy Act information through natural language queries. Built with Elixir Phoenix LiveView and powered by AI.

https://residential-tenancy-act.fly.dev/

## Features

- **AI-Powered Chat Interface** - Ask questions about residential tenancy laws in natural language
- **Retrieval-Augmented Generation (RAG)** - Searches relevant RTA sections to provide accurate, contextual responses
- **Real-time Updates** - Live chat experience with asynchronous response generation
- **Magic Link Authentication** - Secure, passwordless login system
- **Conversation History** - Save and revisit previous conversations
- **Multi-state Support** - Currently supports NSW RTA with extensible architecture

## Quick Start

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Technology Stack

- **Backend**: Elixir Phoenix LiveView
- **Database**: PostgreSQL with pgvector extension
- **Authentication**: Ash Authentication with magic links
- **AI/ML**: AWS Bedrock (Nova models) for text generation and embeddings
- **Frontend**: Phoenix LiveView with Tailwind CSS
- **Background Jobs**: Oban

## Architecture

The application follows a domain-driven design with three main contexts:
- **Accounts** - User management and authentication
- **Acts** - RTA sections data and similarity search
- **Chat** - Conversations, messages, and chat history

The chat system uses a RAG pipeline that:
1. Converts user queries to embeddings
2. Searches for relevant RTA sections using vector similarity
3. Generates contextual responses using LLM with retrieved context

## Development

See [CLAUDE.md](CLAUDE.md) for detailed development guidance and common commands.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
