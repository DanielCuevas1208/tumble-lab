# Roadmap

Current release: 0.2.0, interactive sandbox slice.

## Complete

- Fixed-step 2D world with gravity, forces, torque, and impulses.
- Circle, convex polygon, and polygon-polygon collision handling.
- Sequential impulse solving with friction, restitution, and warm starting.
- Seeded stack, drop, throw, and heap scenarios.
- Headless run, record, replay, and frame comparison commands.
- LOVE sandbox with scene selection, pause, stepping, and time scaling.
- Visible contact points, velocity vectors, and simulation counters.
- Deterministic specs for primitives, motion, contacts, seeds, and replay.
- CI checks for lint, specs, and the headless smoke path.

## Next

- Add a broadphase index for larger body collections.
- Add continuous collision detection for fast bodies.
- Add joints and constraint examples.
- Add an in-sandbox recording browser.
- Add a published license and contribution guide.

The next slice must preserve deterministic headless behavior.

The next slice must reuse the shared scenario registry.
