# Contributing to ExEmailTracker

First off, thank you for considering contributing to ExEmailTracker! 

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible using the issue template.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- A clear and descriptive title
- A detailed description of the proposed enhancement
- Code examples of how it would be used
- Why this enhancement would be useful to most ExEmailTracker users

### Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code follows the existing style (run `mix format`).
6. Issue that pull request!

## Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/ex_email_tracker.git
cd ex_email_tracker

# Install dependencies
mix deps.get

# Create test database
MIX_ENV=test mix ecto.create

# Run tests
mix test

# Run formatter
mix format

# Run credo (if available)
mix credo --strict
```

## Testing

- Write tests for any new functionality
- Ensure all tests pass before submitting PR
- Aim for good test coverage

## Style Guide

- Follow standard Elixir conventions
- Use `mix format` before committing
- Keep functions small and focused
- Write descriptive function and variable names
- Add typespecs for public functions
- Document modules and public functions

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

## Questions?

Feel free to open an issue with your question or reach out on the Elixir Forum.