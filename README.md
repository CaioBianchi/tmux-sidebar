# tmux-sidebar

A tmux plugin that adds an **interactive sidebar** on the **left or right** side of your window. The sidebar displays pane titles and process names, inherits your existing tmux status-bar theming, and lets you **select a pane with arrow keys and press Enter to focus it**.

---

## ✨ Features

- **Left / right positions** — toggle with a single key press.
- **Interactive pane list** — navigate with ↑/↓ (or `k`/`j`) and press **Enter** to focus the selected pane.
- **Native theming** — sidebar automatically uses your `status-style`, `window-status-current-style`, and other tmux colour settings.
- **Focus-aware** — when the sidebar opens, focus stays on your main pane; focus only moves when you explicitly choose a pane.
- **TPM compatible** — one-line install via the Tmux Plugin Manager.
- **Lightweight** — pure Bash, no external dependencies.

---

## 📦 Installation

### Via TPM (recommended)

Add the plugin to your TPM plugin list in `~/.tmux.conf`:

```tmux
set -g @plugin 'CaioBianchi/tmux-sidebar'
```

Then press `prefix + I` (capital i) inside tmux to install.

### Manual

Clone the repo into your tmux plugins directory:

```bash
git clone https://github.com/CaioBianchi/tmux-sidebar.git ~/.tmux/plugins/tmux-sidebar
```

Then source it at the bottom of `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-sidebar/tmux-sidebar.tmux
```

---

## 🎹 Key bindings

| Key | Action |
|-----|--------|
| `prefix + b` | Toggle sidebar between **left** and **right**. |

> The key is configurable — see [Configuration](#configuration) below.

### Using the sidebar

When the sidebar is visible:

| Key | Action |
|-----|--------|
| `↑` / `k` | Move selection up |
| `↓` / `j` | Move selection down |
| `Enter` | Focus the selected pane |

---

## ⚙️ Configuration

Add any of the following options to your `~/.tmux.conf` *before* the TPM `run-shell` line.

| Option | Default | Description |
|--------|---------|-------------|
| `@sidebar-position` | `left` | Starting position (`left` or `right`). |
| `@sidebar-enabled` | `1` | Auto-start the sidebar when tmux loads (`0` = off, `1` = on). |
| `@sidebar-width` | `25` | Width of the sidebar. |
| `@sidebar-key` | `b` | Key (after prefix) to **toggle position** (left ↔ right). |
| `@sidebar-refresh-interval` | `5` | Seconds between sidebar content refreshes. |

### Example

```tmux
set -g @sidebar-position    "right"
set -g @sidebar-enabled     "1"
set -g @sidebar-width       "30"
set -g @sidebar-key         "s"

# ... other plugins ...
set -g @plugin 'CaioBianchi/tmux-sidebar'
```

---

## 🧪 Tests

The plugin ships with a self-contained Bash test suite.

```bash
cd ~/.tmux/plugins/tmux-sidebar
bash tests/run_tests.sh
```

Tests cover:
- Helper functions (colour extraction, option reading).
- Sidebar creation / destruction in left and right positions.
- Position cycling.

---

## 📂 Plugin structure

```
tmux-sidebar/
├── tmux-sidebar.tmux        # TPM entry point — sets defaults & binds keys
├── scripts/
│   ├── helpers.sh             # Shared functions (options, colours, pane ID helpers)
│   ├── sidebar.sh             # Create / destroy sidebar pane
│   ├── cycle.sh               # Toggle between left and right
│   └── render.sh              # Interactive pane list running inside the sidebar
├── tests/
│   ├── framework.sh           # Lightweight test harness
│   ├── test_helpers.sh        # Unit tests
│   ├── test_sidebar.sh        # Integration: create / destroy
│   ├── test_cycle.sh          # Integration: position cycling
│   └── run_tests.sh           # Test runner
└── README.md
```

---

## 📝 License

MIT
