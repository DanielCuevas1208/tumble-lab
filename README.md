# Tumble Lab

Tumble Lab is a small deterministic 2D rigid-body simulation lab written in
Lua. It provides fixed-step worlds, gravity, contacts, collision handling, and
an inspectable headless runner.

## Current status

The current `main` branch focuses on the simulation engine, scenarios, and
headless execution. Interactive presentation and broader test coverage are
still under development.

## Requirements

- Lua 5.4 or a compatible Lua interpreter

The runner uses only the Lua files in this repository.

## Run a scenario

Run a scenario from the repository root:

```text
lua tools/run.lua <scenario>
```

Use `--steps N` to set the number of fixed steps. Use `--dt S` to set the
timestep. Use `--seed N` for a seeded scenario. Use `--quiet` to print only the
result.

The runner lists available scenario names when the requested name is unknown.

## Record and replay

Record a simulation:

```text
lua tools/run.lua <scenario> --record run.tumble
```

Replay the recording and compare every frame:

```text
lua tools/run.lua --replay run.tumble
```

Use `--tolerance S` when a small numeric difference is acceptable. A successful
replay returns status 0. A mismatch returns status 2.

## Project layout

- `engine/` - world, body, collision, solver, and recording code
- `scenarios/` - deterministic simulation scenarios
- `tools/run.lua` - command-line runner and replay checker

## Limitations

The engine is a learning and demonstration project. It does not provide a
complete game-physics feature set or a production stability guarantee.

## License

No license file is published yet. Treat this repository as an experimental
project until a license is added.
