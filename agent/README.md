# NØX — Nocturne Agent

Nocturne Agent is a local-first desktop operator for the Nocturne Hyprland
environment. Its control plane is deliberately independent from the language
model: routine commands are resolved without inference, and model output can
only select typed actions from a small allowlist.

The user interface is terminal-native. Run `nox` for its full-screen night
console, scrollable chat, editable in-memory prompt history, typed confirmation
flow, and built-in command deck. Use `nox --classic` for the original
line-oriented sigil view. NØX does not use a floating control panel.
Completed actions and attention states are mirrored to the existing themed
notification center. `Super+X` opens NØX in a tiled Kitty terminal.

Browser observation is explicit and read-only. When asked what is happening in
the browser, NØX reads the most recently used browser's window/media metadata
and temporarily OCRs only its visible viewport. The screenshot is deleted
immediately, OCR text is never stored, and browser text is sent only to a
non-tool-calling local summarizer. Install the private OCR helper with
`./install-ocr.sh`; it does not modify Ubuntu's system packages.

General observation is also read-only and loaded only when requested. NØX can
inspect the current user's processes, Hyprland windows, user services, download
metadata, NetworkManager devices, PipeWire state, battery, and power profile.
It does not read downloaded file contents, and raw snapshots are reduced to a
short answer before being returned to the terminal.

App launches are resolved deterministically against the machine's installed
desktop entries, then handed to UWSM as a separate graphical scope. This keeps
GUI apps outside the controller's hardened read-only service sandbox. App
names are not guessed by the language model: an unknown or uninstalled name
fails honestly instead of launching a different application.

Common installed-app aliases are deterministic too: `open YT Music` resolves
to the installed YouTube Music PWA. `play SONG by ARTIST` resolves a direct
track and starts it in that PWA. `close APP` targets that app's Hyprland
windows and requires an explicit confirmation before anything is closed.

The Tool Forge creates declarative routines from those same typed tools. A
proposal contains JSON actions rather than generated code or shell commands,
is independently policy-validated, and is saved disabled. Review proposals
with `:proposals`, then explicitly activate one with `:enable ID`. Enabled
routines run only on their exact trigger phrases and every step is revalidated
at execution time.

NØX 0.4 adds a compact agent loop modeled on the public tool-loop architecture
used by modern coding and desktop agents. Unmatched natural requests can take
up to three typed steps: select a capability, execute it behind policy, return
a compact result for verification, then continue, recover, or answer. Repeated
calls are stopped, tool results are capped at 1,200 characters, and the loop
never gains a shell. A read-only app finder lets the loop discover exact
desktop entries instead of requiring a hand-written alias for every phrasing.

Only six compact action receipts live in RAM for follow-ups such as `close it`;
raw prompts are still never written to disk. The socket-activated controller
exits after five idle minutes and the llama.cpp model independently unloads
most VRAM after 75 idle seconds. A process-free systemd timer preserves a
three-minute warm follow-up window, then stops llama.cpp to release the
remaining mapped RAM as well. No OpenClaw Gateway, Node runtime, channel
connectors, or second background agent is installed.

## Design goals

- Stay asleep unless a request actually requires language inference.
- Release model RAM and VRAM after a short idle period.
- Pause inference while gaming, under GPU pressure, or on low battery.
- Never expose a general shell, `sudo`, file deletion, package management, or
  messaging as model-callable tools.
- Require confirmation for disruptive actions such as closing a window or
  changing the system power profile.
- Store action names and outcomes for personalization, not prompt text or file
  contents.

## Current milestone

The current milestone contains the deterministic fast path, bounded agent
loop, policy engine, desktop discovery and observation registries, safe Tool
Forge, modern terminal chat, hardware-aware wake policy, private SQLite usage
memory, CLI, and tests. The
controller runs through a private systemd user socket and exits
after five idle minutes. The socket remains available at effectively zero idle
cost and starts the controller again on the next request.

Run the tests without installing anything:

```bash
cd agent
PYTHONPATH=src python3 -m unittest discover -s tests -v
```

Try the deterministic planner:

```bash
cd agent
PYTHONPATH=src python3 -m nocturne_agent.cli ask "volume down 5"
PYTHONPATH=src python3 -m nocturne_agent.cli context
PYTHONPATH=src python3 -m nocturne_agent.cli doctor
```

Install the on-demand user service:

```bash
./install-agent.sh
nocturne-agent ask "open terminal"
```

Useful terminal deck commands:

```text
:tools                         list model-callable typed actions
:apps                          list installed apps NØX can resolve
:doctor                        check desktop tools and model state
:forge start focus mode by...  propose a disabled reusable routine
:proposals                     review routines and enabled state
:enable focus-mode-ab12        enable one reviewed routine
:sleep                         unload the model immediately
```

Routine desktop commands work without a model. When installed, llama.cpp is
consulted only for unmatched requests, observation summaries, and requested
Tool Forge proposals. The same policy boundary validates model-selected
actions before execution.

Install the optional local intelligence layer (about 2.7 GB total download):

```bash
./install-model.sh
```

This installs a checksummed official llama.cpp CUDA binary and the official
Qwen3-4B Q4_K_M model. It listens on localhost with a machine-local API key,
does not expose llama.cpp's shell/file tools or web UI, and unloads model/KV
memory from RAM and VRAM after 75 idle seconds. GPU layers are fitted around
the desktop's current VRAM use, with CPU fallback instead of taking memory from
a running game.

State is stored under `~/.local/state/nocturne-agent/` and is excluded from
Git. Model files are stored outside the repository.
