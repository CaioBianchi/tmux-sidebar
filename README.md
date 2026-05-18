# tmux-sidebar

A tmux plugin that adds **side status bars** (left or right) with **expand / collapse** support. The sidebar displays pane titles and process names, inherits your existing tmux status-bar theming, and can be cycled through four positions — **left, right, top, and bottom** — with a single key press.

---

## ✨ Features

- **Four positions** — left, right, top, bottom (toggle with a hotkey).
- **Expand / collapse** — show only indicators when collapsed, full pane names + processes when expanded.
- **Native theming** — sidebar automatically uses your `status-style`, `window-status-current-style`, and other tmux colour settings.
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
| `prefix + b` | Cycle sidebar position (`left → right → top → bottom → left`). |
| `prefix + B` | Toggle sidebar between **expanded** and **collapsed**. |

> The keys are configurable — see [Configuration](#configuration) below.

---

## ⚙️ Configuration

Add any of the following options to your `~/.tmux.conf` *before* the TPM `run-shell` line.

| Option | Default | Description |
|--------|---------|-------------|
| `@sidebar-position` | `right` | Starting position (`left`, `right`, `top`, `bottom`). |
| `@sidebar-state` | `collapsed` | Starting state (`expanded`, `collapsed`). |
| `@sidebar-enabled` | `0` | Auto-start the sidebar when tmux loads (`0` = off, `1` = on). |
| `@sidebar-width` | `25` | Width when side position is **expanded**. |
| `@sidebar-collapsed-width` | `4` | Width when side position is **collapsed**. |
| `@sidebar-height` | `3` | Height when top / bottom position is **expanded**. |
| `@sidebar-collapsed-height` | `1` | Height when top / bottom position is **collapsed**. |
| `@sidebar-key` | `b` | Key (after prefix) to **cycle position**. |
| `@sidebar-toggle-key` | `B` | Key (after prefix) to **toggle expand / collapse**. |
| `@sidebar-refresh-interval` | `5` | Seconds between sidebar content refreshes. |

### Example

```tmux
set -g @sidebar-position    "left"
set -g @sidebar-state       "expanded"
set -g @sidebar-enabled     "1"
set -g @sidebar-width       "30"
set -g @sidebar-key         "s"
set -g @sidebar-toggle-key  "S"

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
- Sidebar creation / destruction in all four positions.
- Expand / collapse dimension changes.
- Position cycling with state preservation.

---

## 📂 Plugin structure

```
tmux-sidebar/
├── tmux-sidebar.tmux        # TPM entry point — sets defaults & binds keys
├── scripts/
│   ├── helpers.sh             # Shared functions (options, colours, pane ID helpers)
│   ├── sidebar.sh             # Create / destroy sidebar pane
│   ├── toggle.sh              # Expand ↔ collapse
│   ├── cycle.sh               # Rotate through positions
│   └── render.sh              # Loop that paints sidebar content
├── tests/
│   ├── framework.sh           # Lightweight test harness
│   ├── test_helpers.sh        # Unit tests
│   ├── test_sidebar.sh        # Integration: create / destroy
│   ├── test_toggle.sh         # Integration: expand / collapse
│   ├── test_cycle.sh          # Integration: position cycling
│   └── run_tests.sh           # Test runner
└── README.md
```

---

## 📝 License

MIT
