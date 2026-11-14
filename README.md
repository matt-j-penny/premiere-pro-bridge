# Premiere Pro Bridge

Let Claude (or any MCP client) edit inside your open Adobe Premiere Pro project. You can ask it to cut clips, build sequences, add markers, set up exports and more.

This repo packages [leancoderkavy/premiere-pro-mcp](https://github.com/leancoderkavy/premiere-pro-mcp) v1.30.0 (MIT) with a one-command setup and shorter docs. The server code comes from that project unchanged. All credit for it goes to its authors.

## How it works

```
Claude ──MCP──▶ Node server ──script files──▶ Premiere panel (CEP) ──ExtendScript──▶ Premiere Pro
```

The server writes small ExtendScript jobs to a temp folder. A panel inside Premiere picks each one up and runs it through Premiere's own scripting API, then sends the result back. Nothing touches your `.prproj` file directly, and no screen control is used. Everything runs locally.

## Requirements

- macOS (for Windows, see [Manual setup](#manual-setup))
- Adobe Premiere Pro 2020 or later
- Node.js 20, 22 or 24+ (`brew install node@22`)
- Optional: FFmpeg, needed by `trim_clip`, `slip_edit` and `detect_silence` (`brew install ffmpeg`)

## Setup

```bash
git clone https://github.com/matt-j-penny/premiere-pro-bridge.git
cd premiere-pro-bridge
./setup.sh
```

`setup.sh`:

1. Checks your Node version
2. Installs dependencies and builds the server
3. Installs the Premiere panel and turns on Adobe's CEP debug mode, which unsigned panels need
4. Registers the server as `premiere-pro` in Claude Code and Claude Desktop, if they're installed. Your Desktop config is backed up first.
5. Runs a local health check

Then:

1. Fully quit and reopen Premiere Pro, and open a project.
2. Open **Window > Extensions > MCP for Adobe Premiere Pro**. The panel should say **Running**.
3. Restart Claude and ask:

   > Run verify_premiere_connection. Make no changes.

If that passes, you're connected. Try opening a copy of a project first, before you let it edit real work.

## Example prompts

- "List the sequences in this project and tell me which one is active."
- "Add a marker at every point where the speaker pauses for more than a second."
- "Cut the first 3 seconds off every clip on V1."
- "Export the active sequence with the H.264 Match Source preset."

## Updating

```bash
git pull
./setup.sh
```

Quit Premiere before you update, so the panel can be replaced.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Panel is missing from Window > Extensions | Fully quit Premiere (Cmd+Q) and reopen it. Then run `node dist/index.js --diagnose-cep`. |
| Panel shows but Claude can't connect | Make sure the panel says Running and a project is open. Restart Claude after you run setup. |
| `premiere-pro` tools don't show up in Claude | Run `claude mcp list` (Claude Code) or check `~/Library/Application Support/Claude/claude_desktop_config.json` (Desktop). |
| Anything else | Run `node dist/index.js --doctor`. It checks the install without reading your project. |

## Manual setup

For Windows, Cursor, VS Code or anything else:

```bash
npm ci
npm run build
node dist/index.js --install-cep
node dist/index.js --print-client-config claude   # or cursor | vscode | codex
```

Paste the printed config into your client's MCP settings.

## Optional: UXP bridge (Premiere 25.6+)

The newer UXP bridge adds about 98 tools on top of the CEP panel. It needs a separate plugin install and a shared token. See [uxp-plugin/DISTRIBUTION.md](uxp-plugin/DISTRIBUTION.md).

## Uninstall

```bash
node dist/index.js --uninstall-cep
claude mcp remove -s user premiere-pro
```

Then delete the `premiere-pro` entry from your Claude Desktop config.

## More docs

- [Full upstream README](docs/UPSTREAM-README.md): every tool, env var and option
- [Supported actions](docs/supported-actions.md)

## License

MIT. See [LICENSE](LICENSE). The original copyright belongs to the upstream authors.
