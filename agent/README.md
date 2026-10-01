# Nocturne Agent

Nocturne Agent is a local-first desktop operator for the Nocturne Hyprland
environment. Its control plane is deliberately independent from the language
model: routine commands are resolved without inference, and model output can
only select typed actions from a small allowlist.

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

The first milestone contains the deterministic planner, policy engine, desktop
tool registry, hardware-aware wake policy, private SQLite usage memory, CLI,
and tests. The controller runs through a private systemd user socket and exits
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

The local language runtime is deliberately a separate milestone. Routine
desktop commands already work without a model. When installed, llama.cpp will
only be consulted for unmatched requests, and the same policy boundary will
validate its proposed action before execution.

State is stored under `~/.local/state/nocturne-agent/` and is excluded from
Git. Model files are stored outside the repository.
