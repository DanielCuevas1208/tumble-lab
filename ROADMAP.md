# Roadmap

Current release: 0.4.0, continuous collision slice.

Status values: complete, in-progress, planned, and blocked.

## Complete

- `fixed-world` — complete. Gravity, forces, torque, impulses, and fixed steps work.
- `collision-primitives` — complete. Circles and convex polygons produce contact manifolds.
- `impulse-solver` — complete. Friction, restitution, warm starting, and position bias work.
- `broadphase` — complete. A uniform grid returns deterministic candidate pairs.
- `deterministic-tools` — complete. Headless runs, recordings, replays, and frame comparisons work.
- `sandbox-showcase` — complete. LOVE scenes expose contacts, velocities, counters, and controls.
- `continuous-collision` — complete. Fast dynamic circles stop at static circle impacts.

### `continuous-collision`

User outcome: A fast circle no longer passes through a static circle during one fixed step.

Bounded deliverable: Add a relative-motion time-of-impact query for dynamic-circle and static-circle pairs.

Acceptance criteria:

- A discrete failure fixture tunnels without CCD.
- The CCD fixture stops at the first impact.
- Multiple impacts keep body-ID event order.
- The `ccd` scenario replays every frame exactly.

Verification:

~~~text
lua tools/run.lua ccd --steps 1
lua -e "describe=function(_,f) f() end; it=function(_,f) f() end; require('spec.core_spec')"
busted
~~~

## Planned

### `distance-joints` — planned

User outcome: Users can build a small soft-body chain in the shared scenario registry.

Bounded deliverable: Add distance joints with explicit stiffness and solver parameters.

Acceptance criteria:

- A chain stays within a documented constraint error bound.
- A deformable loop remains stable for a fixed replay.
- A shared LOVE and headless scenario demonstrates the joint registry.

Verification: `busted --filter="distance joints"` and `lua tools/run.lua soft-body --steps 120 --quiet`.

### `recording-browser` — planned

User outcome: Users can inspect recordings inside the LOVE sandbox.

Bounded deliverable: Add a browser panel for local recording metadata and replay selection.

Acceptance criteria:

- The panel lists recordings without changing simulation state.
- Users can select and replay one recording.
- A headless recording remains byte-for-byte compatible.

Verification: `busted --filter="recording browser"` and `love .`.

### `license-contribution` — planned

User outcome: Contributors can read project reuse and contribution rules.

Bounded deliverable: Add a selected open-source license and a concise contribution guide.

Acceptance criteria:

- The license names the repository and copyright holder.
- The guide lists checks and the expected test command.
- README links to both files.

Verification: `Test-Path LICENSE; Test-Path CONTRIBUTING.md; luacheck .`.

## Release rules

Every slice must preserve deterministic headless behavior.

Every scene must use the shared scenario registry.

Mark a milestone complete only after its acceptance criteria pass executable checks.
