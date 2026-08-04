# Tumble Lab

Tumble Lab is a first-principles 2D rigid-body physics engine written in Lua.

It solves circle and convex polygon contacts with sequential impulses.

It exposes the same deterministic world through a LOVE sandbox and a headless runner.

## Value

- Inspect contact points, velocity vectors, body counts, and solver impulses.
- Compare free-flight motion with an analytic trajectory.
- Rebuild recorded runs and compare every captured frame.
- Explore seeded scenes with repeatable body placement.
- Read the engine without a framework abstraction layer.

## Architecture

The scenario registry creates worlds for both front ends.

The LOVE sandbox renders bodies and simulation state.

The headless runner prints final state and validates recordings.

The engine keeps body, collision, solver, and recording modules separate.

~~~text
LOVE sandbox ----+
                  +-- scenarios -- engine world -- collision and solver
headless CLI ----+                 +-- recorder
~~~

## Setup

Use Lua 5.4 or LuaJIT 2.1 for headless runs.

Use LOVE 11.5 for the interactive sandbox. The window requires 960 by 640 pixels.

Use Busted and Luacheck for repository checks.

Run commands from the repository root.

Open the interactive sandbox:

~~~text
love .
~~~

## Interactive sandbox

Select a scene with keys 1 through 4.

Press R to reset the selected scene.

Press Space to pause or resume simulation.

Press N to advance one fixed step.

Press plus or minus to change the time scale.

Press square brackets to change scenes.

The sidebar reports simulated time, steps, bodies, contacts, and time scale.

Contact points use orange markers.

Velocity vectors use cyan lines.

## Headless runner

Run a scene:

~~~text
lua tools/run.lua drop --steps 10
~~~

Example output:

~~~text
scenario: drop | steps: 10 | dt: 0.016666666666666666 | simulated: 0.167 s
bodies: 2
id  shape             x          y         vx         vy      angle
1   polygon      0.0000     0.2500     0.0000     0.0000     0.0000
2   circle       0.0000    -1.8501     0.0000     1.6350     0.0000
contact impulse (last step): 0.000000
~~~

Use --seed N for the seeded heap.

Use --dt S to select a fixed timestep.

Use --quiet to print no state table.

## Record and replay

Record a run:

~~~text
lua tools/run.lua heap --steps 120 --seed 42 --record run.tumble
~~~

Replay the recording:

~~~text
lua tools/run.lua --replay run.tumble
~~~

Replay returns status 0 for identical frames.

Replay returns status 2 for a mismatch.

Use --tolerance S for an accepted numeric difference.

## Test status

Local verification passes Luacheck, Lua syntax, the LOVE callback harness, and the headless smoke path.

Busted remains a CI check because this workspace cannot download LuaRocks packages.

## Tests

Run the deterministic specs:

~~~text
busted --output plain
~~~

Run the linter:

~~~text
luacheck .
~~~

Run the headless smoke check:

~~~text
lua tools/run.lua heap --steps 12 --seed 42 --quiet
~~~

The CI workflow runs all three checks.

## Limitations

Collision detection checks every body pair.

The solver uses a fixed iteration budget.

The engine does not provide continuous collision detection.

The engine does not provide joints, sleeping, or a broadphase index.

The project does not promise production stability.

## Roadmap

See ROADMAP.md for completed work and planned slices.

## License

No license file exists.

Treat this repository as an experimental project until a license is added.