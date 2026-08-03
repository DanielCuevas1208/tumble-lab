# Roadmap

This document tracks the direction of Tumble Lab. It shows what is done and what comes next. Milestones stay small. Each milestone is one coherent release.

## Legend

- [x] Done and verified by tests.
- [ ] Planned.

## Completed

### Engine core, release 0.1

- [x] Vector math helpers.
- [x] Deterministic Park-Miller random generator.
- [x] Circle and convex polygon shapes.
- [x] Mass and inertia for every shape.
- [x] Circle-circle, circle-polygon, and polygon-polygon collision.
- [x] Sequential impulse solver.
- [x] Warm starting for stable stacks.
- [x] Coulomb friction and restitution.
- [x] Fixed timestep world stepping.
- [x] Scenario builders for stack, drop, throw, and heap.
- [x] Headless runner with record and replay.

### Verification and presentation, release 0.2

- [x] Busted test suite for engine behavior.
- [x] Exact record and replay verification.
- [x] LOVE interactive sandbox.
- [x] Headless snapshot renderer.
- [x] CI with lint, format, and test jobs.
- [x] README, roadmap, license, and repository metadata.

## Next

### Performance, release 0.3

- [ ] Spatial hash broad phase for body pairs.
- [ ] Scene size benchmarks.

### Joints, release 0.3

- [ ] Distance joint.
- [ ] Revolute joint.

### Solver stability, release 0.4

- [ ] Position solver with split impulses.
- [ ] Body sleeping.
- [ ] Contact islanding.

### Simulation features, release 0.5

- [ ] Ray casting.
- [ ] Sensors.
- [ ] Continuous collision detection for fast bodies.
- [ ] Compound bodies.
- [ ] Concave shapes through convex decomposition.

### Tooling, release 0.5

- [ ] Web export with love.js.
- [ ] Frame-by-frame capture for short demo videos.

## Design notes

Determinism is the core promise. Every new feature must keep the recorder format stable. Format changes require a version bump and a migration path.

Tests define the behavior. Add a failing test before a behavior change. Then update the test.

The sandbox and the headless tools must stay in sync. Both consume the shared scenario builders.
