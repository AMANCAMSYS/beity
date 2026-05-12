# @dmytri/speckit-opencode-plugin

[OpenCode](https://opencode.ai) plugin for [spec-kit](https://github.com/github/spec-kit) workflow - specification-driven development.

## Installation

See [OpenCode Plugins](https://opencode.ai/docs/plugins/) for full documentation.

Add to your `opencode.json`:

```json
{
  "plugin": ["@dmytri/speckit-opencode-plugin"]
}
```

OpenCode will automatically install the plugin on next start.

## Requirements

[specify CLI](https://github.com/github/spec-kit) must be installed. See [speckit.org](https://speckit.org/#quick-start) for installation instructions:

```bash
# Install with uv (recommended)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verify installation
specify --version
```

The plugin will notify you if `specify` is not installed.

## Usage

```typescript
speckit({ action: "init" })        // Initialize spec-kit in current project (auto-runs on first use)
speckit({ action: "check" })       // Verify specify CLI and tools installed
speckit({ action: "phase" })       // Check current workflow phase and guidance
```

### Workflow

After initialization, the agent uses slash commands for each phase:

1. `/speckit.constitution` - Create project principles
2. `/speckit.specify` - Define requirements
3. `/speckit.plan` - Create technical plan
4. `/speckit.tasks` - Break into tasks
5. `/speckit.implement` - Execute tasks

Use `speckit({ action: "phase" })` to check current progress and get guidance on what's next.

## How It Works

- Agent uses plugin tool for spec-kit operations (never uses CLI directly)
- Plugin auto-initializes `.specify/` via `specify init`
- Plugin provides phase tracking and workflow guidance
- Slash commands (loaded from `.specify/templates/commands/`) drive the actual workflow
