# AutoVim

A modular Neovim configuration inspired by robotics and autonomous systems.
AutoVim brings an animated control-loop dashboard, explicit workspaces, and a
shared tool panel to the terminal, with a consistent navy, teal, and amber theme.

**Current status: early alpha.** The core editing workflow is usable, but
configuration, shortcuts, and dependencies may change between revisions.
Container workspaces and PlatformIO integration are still planned features.

## What it includes

- An animated dashboard: a blinking eye and a spinning gear exchange depth as
  they travel around a closed loop.
- A Telescope file/workspace picker and a netrw tree rooted in your chosen
  workspace or standalone file's directory.
- One shared sidebar for files, a persistent terminal, Undotree, and Harpoon.
- Numbered Harpoon pins in the top bar, with direct shortcuts for the first
  nine files.
- A statusline showing the current path, mode, edits, diagnostics, file details,
  cursor position, and attached language server when space permits.
- Tree-sitter highlighting with 26 configured parsers and the AutoVim theme.
- Native Neovim LSP, explicit server installation through Mason, and nvim-cmp
  completion with native snippets.
- Plugin commits pinned in `lazy-lock.json`; server versions and the Mason
  registry snapshot are pinned separately.

## Alpha compatibility

| Area | Current status |
| --- | --- |
| Linux + Neovim **0.10.4** | Tested baseline |
| Neovim **0.11.x** | Intended compatibility target; not yet independently validated |
| Other Neovim versions | Not validated; use 0.10.4 for the tested baseline |
| macOS and native Windows | Not validated; some paths and tools currently assume Unix |
| Terminal display | UTF-8 and true colour; a Nerd Font is needed for the explorer's folder icon |
| Modified terminal keys | Ctrl-Tab and Ctrl-number depend on the terminal sending distinct key sequences |

Core workflow checks and a real C/C++ clangd session have passed on the tested
baseline. The other language integrations are configured, but need broader
testing with their real toolchains and projects. A language appearing below
does not mean every compiler, framework, or operating system has been validated.

AutoVim uses no terminal-specific integration. Font choice and size belong to
your terminal application; the embedded terminal shares Neovim's character grid.

### Requirements

- Neovim **0.10.4** for the tested configuration.
- Git and an internet connection for initial plugin/parser/server downloads.
- A C compiler (`cc`, GCC, or Clang) to build Tree-sitter parsers.
- `curl`, GNU `tar`, `gzip`, and `unzip` for downloads and Mason packages.
- A working shell, as configured by Neovim's `shell` option.
- Recommended: `fd`, or `fdfind` from Debian/Ubuntu's `fd-find` package, for
  streaming file and directory search. `find` and a native scanner are fallbacks.
- Language-specific tools from the table below, for the languages you use.

## Installation

### Try AutoVim alongside your current config

Use Neovim's `NVIM_APPNAME` to give AutoVim its own configuration and standard
data/state/cache directories:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
git clone https://github.com/airfelixx/autovim.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/autovim"

# Restore locked plugin versions and wait for the initial parser installs.
NVIM_APPNAME=autovim AUTOVIM_BOOTSTRAP=1 \
  nvim --headless '+Lazy! restore' +qa

NVIM_APPNAME=autovim nvim
```

The first setup downloads plugins and builds parsers, so give it time to finish.
Language servers are installed separately. Keep the `NVIM_APPNAME=autovim`
prefix whenever launching this installation, including with file arguments.

### Use AutoVim as your default config

Back up any existing Neovim configuration first. Clone into
`${XDG_CONFIG_HOME:-$HOME/.config}/nvim` instead of `autovim`, then run:

```sh
AUTOVIM_BOOTSTRAP=1 nvim --headless '+Lazy! restore' +qa
nvim
```

For a manual installation, copy `init.lua`, `lua/`, `colors/`, and
`lazy-lock.json` into Neovim's config directory. The repository alone does not
change an existing installed copy.

## Getting around

Launch without a filename for the dashboard, with a directory for an explicit
workspace, or with a file for standalone editing:

```sh
NVIM_APPNAME=autovim nvim
NVIM_APPNAME=autovim nvim ~/projects/my-project
NVIM_APPNAME=autovim nvim ~/notes/example.py
```

Omit `NVIM_APPNAME=autovim` if using the default installation.

On the dashboard, `f` opens file selection, `c` opens the active config, and
Enter activates the selected action. Use `j`/`k`, arrows, or Tab to move;
Space followed by Space pauses or resumes the animation. `q` closes the menu
window. The container and PlatformIO entries are inactive placeholders.

### Workspace commands

| Command | Action |
| --- | --- |
| `:AutoVim` | Return to the dashboard while keeping existing buffers and edits |
| `:Open` | Open the Telescope file/workspace picker |
| `:Workspace [directory]` | Set this tab's workspace and open its tree |
| `:OpenFile [file]` | Open a file while keeping this tab's workspace |
| `:Standalone [file]` | Open a file and clear this tab's workspace |

The three path-taking commands open selection when no path is supplied.
Workspace roots are explicit and local to each Neovim tab; opening a file does
not automatically turn its Git root into an editor workspace.

### File selection

The picker searches relative paths with literal, case-insensitive matching.
For example, `tfc` finds matching directories and files inside them. The
`fd`/`fdfind` and `find` backends include hidden and ignored paths while
excluding `.git` internals; an empty prompt lists the current directory.

| Key | Action in the picker |
| --- | --- |
| Enter | Browse a directory or open a file |
| Space, Enter | Choose the selected directory as a workspace; on a file, choose the current directory |
| Ctrl-H | Go to the parent directory |
| Ctrl-C | Return the search root to your home directory and clear the query |
| Ctrl-N / Ctrl-P or arrows | Move the selection |
| Escape | Cancel and return to the previous screen |

In picker Normal mode, `-` also goes up and `q` cancels. Workspace selection
with Space, Enter belongs to this picker, rather than the editor's tree panel.

### Editor and terminal shortcuts

**Space is the leader:** press Space, then the next key in Normal mode.
Terminal input uses Ctrl equivalents so Space goes directly to the shell.

| Action | Editor Normal mode | Terminal input |
| --- | --- | --- |
| Toggle file tree | Space, Tab | Ctrl-Tab |
| Toggle terminal | Space, `\` | Ctrl-\ |
| Toggle undo history | Space, `u` | Ctrl-U |
| Toggle Harpoon list | Space, `h` | Ctrl-H |
| Pin the editor's file | Space, `a` | Ctrl-A |
| Open numbered Harpoon file | Space, `1`–`9` | Ctrl-1–Ctrl-9 |
| Move to another pane | Space, arrow | Ctrl-arrow |

Only one tool occupies the shared panel at a time. Harpoon's first row clears
the list; Enter opens a pin, and `d` removes it and renumbers the remaining
files. Pins persist per workspace, or per standalone file's parent directory.
Undo history also persists across editor restarts.

Each tab creates its shell when the terminal first opens. Hiding the panel,
switching tools, returning to the dashboard, or closing a tab keeps that shell
running. Type `exit` to end it. Its output remains available afterwards.
Sessions last for the current Neovim process, and an existing shell keeps its
working directory when you change workspaces. Ctrl-\ returns from terminal
input to the editor so you can enter colon commands.

## Language support

AutoVim uses Neovim's built-in LSP client. **You install the language toolchains;
Mason installs the configured language servers on request.** Opening a file
does not trigger a server download.

| Language | `:LspInstall` name | Tools you provide |
| --- | --- | --- |
| C / C++ | `clangd` | Your compiler and build tools |
| Assembly | `asm_lsp` | Rust/Cargo to build the server; your assembler |
| Java | `jdtls` | JDK 21+ and Python 3.9+ for the launcher |
| Python | `pyright` | Node.js/npm and your Python/project environment |
| HTML | `html` | Node.js/npm |
| CSS / SCSS / Less | `cssls` | Node.js/npm |
| JavaScript / TypeScript / JSX / TSX | `ts_ls` | Node.js 22.22.2+ and npm |
| Rust | `rust_analyzer` | Rust/Cargo; `rust-src` for standard-library analysis |
| Go | `gopls` | A recent Go toolchain compatible with the pinned server |
| Zig | `zls` | A Zig version compatible with the pinned ZLS 0.16.1 |
| Nim | `nim_langserver` | Nim, `nimsuggest`, and Nimble for dependencies |

The Java runtime and launcher requirements come from
[jdtls](https://github.com/eclipse-jdtls/eclipse.jdt.ls/blob/v1.62.0/README.md#requirements);
the JavaScript/TypeScript Node minimum follows the pinned
[typescript-language-server](https://github.com/typescript-language-server/typescript-language-server/blob/v6.0.2/package.json).
Check [the server definitions](lua/autovim/lsp/servers.lua) for all version pins,
filetypes, project markers, and settings.

Install your chosen toolchains, restart Neovim to inherit their PATH, then run:

```vim
:LspInstall clangd
```

Use `:LspInstall all` for every configured server, or `:LspInstall` without an
argument for the current file's server. Missing installer tools cause affected
packages to be skipped with a message. Once installation finishes, open your
file or use `:LspStart` to attach. Existing servers on PATH can also be used;
their versions are managed outside Mason.

| Command | Purpose |
| --- | --- |
| `:LspInfo` | Server availability, missing runtimes, attached clients, and project roots |
| `:LspStart` | Try starting the current file's server |
| `:LspRestart` | Restart attached servers and reattach their affected buffers |
| `:Mason` | Package installation progress and server management |
| `:MasonLog` | Installation failure details |

For C/C++, provide `compile_commands.json` or `compile_flags.txt` so clangd can
resolve your build's includes, defines, and target flags. Python prefers a
project `.venv/` or `venv/`, then the active `VIRTUAL_ENV`. Java keeps separate
metadata per project. Assembly configuration can use `.asm-lsp.toml`, and Nim
analysis uses `nimsuggest`. LSP project roots never change the explicit editor
workspace.

### LSP keys

These maps apply to editing buffers with an attached server. Available actions
depend on the server's capabilities.

| Key | Action |
| --- | --- |
| `gd` / `gD` | Definition / declaration |
| `gr` / `gi` / `gy` | References / implementation / type definition |
| `K` | Hover documentation |
| Ctrl-K in Insert mode | Signature help |
| Space, `l`, `r` | Rename symbol |
| Space, `l`, `a` | Code action |
| Space, `l`, `f` | Format the buffer when supported |
| Space, `l`, `d` | Show line diagnostics |
| Space, `l`, `q` | Put diagnostics in the location list |
| Space, `l`, `s` / `w` | Telescope document / workspace symbols |
| `[d` / `]d` | Previous / next diagnostic |

### Completion

Suggestions combine the language server, paths, and buffer words. Buffer-word
suggestions start after three characters; nothing is selected automatically.

| Insert-mode key | Action |
| --- | --- |
| Tab / Shift-Tab | Select the next / previous item in the visible menu |
| Enter | Accept the selected item; otherwise insert a newline |
| Ctrl-Space | Request suggestions |
| Ctrl-N / Ctrl-P | Select the next / previous item |
| Ctrl-E | Cancel completion |
| Ctrl-B / Ctrl-F | Scroll completion documentation up / down |

With the menu closed, Tab first moves to the next active snippet field.
Otherwise, it requests suggestions after non-whitespace text or keeps normal
indentation at the start of a line or after whitespace. Shift-Tab returns to
the previous snippet field when available. Snippet navigation also works in
Select mode. When no menu is visible, use Tab to open it, Tab again to select,
then Enter to accept.

## Configuration and updates

The entry point, `init.lua`, delegates to `lua/autovim/init.lua`. Each scope
owns a particular part of AutoVim:

| Scope / file | Responsibility |
| --- | --- |
| [dashboard/config.lua](lua/autovim/dashboard/config.lua) | Greeting, animation timing, palette, and menu entries |
| [core/](lua/autovim/core) | Global options, commands, and shortcuts |
| [workspace/](lua/autovim/workspace) | Explicit roots and standalone-file context |
| [explorer/](lua/autovim/explorer) | Tree panel, picker, and search backends |
| [sidebar/](lua/autovim/sidebar) | Activity rail and shared tool-panel layout |
| [terminal/](lua/autovim/terminal) | Shell creation and lifetime |
| [harpoon/](lua/autovim/harpoon) / [undo/](lua/autovim/undo) | Tool adapters and list/history actions |
| [ui/](lua/autovim/ui) / [colors/autovim.lua](colors/autovim.lua) | Editor bars, theme, and highlights |
| [lsp/](lua/autovim/lsp) | Server definitions, installation, native client, and completion |
| [plugins/specs.lua](lua/autovim/plugins/specs.lua) | Plugin versions, loading rules, and parser list |

Restart Neovim after changing Lua modules. Sourcing `init.lua` alone does not
clear Lua's module cache. The dashboard's config action opens the active
installation, which may be a different copy from your repository checkout.

Use `:Lazy restore` to restore the plugin commits in `lazy-lock.json`.
`:Lazy update` intentionally updates plugins and the lockfile. Server pins and
the Mason registry snapshot live in the LSP scope and should be reviewed
together when upgrading. Tree-sitter loads at startup as required by the
compatible plugin branch; Telescope and Undotree load when used, Harpoon loads
after startup, and completion loads on Insert mode.

## Current limits and feedback

- Container workspaces and PlatformIO actions are inactive dashboard entries.
- Debugger integration and container-aware language servers are not implemented.
- Terminal session persistence ends when Neovim exits; closing a panel does not
  provide persistence across application restarts.
- Modified keys can be intercepted by the host terminal or window manager.
- The native search fallback has different scanning/ignore behaviour; `fd` or
  `fdfind` is the preferred backend.

For setup problems, inspect `:Lazy`, `:checkhealth mason`, `:MasonLog`, and
`:LspInfo` as appropriate. When reporting a bug, include your OS, `nvim
--version`, terminal application, relevant toolchain/server versions, and
steps to reproduce it. Compatibility reports from other environments are useful
during the alpha.

## License

GNU General Public License, version 3. See [LICENSE](LICENSE). Plugins and
language servers retain their own upstream licenses.
