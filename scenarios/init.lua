-- Reusable demonstration scenarios. Each builder returns a configured
-- world ready to step. Scenarios are shared by the headless runner,
-- the test suite, and the LOVE sandbox.
--
-- Coordinates use y-down screen convention. The ground platform is a
-- static box whose top surface sits at y = 0. Bodies above the ground
-- have negative y and fall toward it under gravity.

local World = require("engine.world")
local shape = require("engine.shape")
local rng = require("engine.rng")

local scenarios = {}

local function add_ground(world, half_width, friction)
  world:add_body({
    shape = shape.box(half_width, 0.25),
    kind = "static",
    position = { x = 0, y = 0.25 },
    friction = friction or 0.6,
  })
end

-- A tower of boxes resting on the ground.
function scenarios.stack(opts)
  opts = opts or {}
  local count = opts.count or 8
  local world = World.new(0, 9.81)
  add_ground(world, 8)
  for k = 1, count do
    world:add_body({
      shape = shape.box(0.25, 0.25),
      position = { x = 0, y = -(0.5 * k - 0.25) },
      friction = 0.6,
    })
  end
  return world
end

-- A circle dropped onto the ground.
function scenarios.drop(opts)
  opts = opts or {}
  local world = World.new(0, 9.81)
  add_ground(world, 8)
  world:add_body({
    shape = shape.circle(opts.radius or 0.2),
    position = { x = opts.x or 0, y = opts.y or -2 },
    velocity = { x = 0, y = 0 },
    friction = 0.3,
    restitution = opts.restitution or 0.5,
  })
  return world
end

-- A body in free flight, with an optional ground.
-- With no ground this matches the analytic projectile solution.
function scenarios.throw(opts)
  opts = opts or {}
  local world = World.new(0, opts.gravity or 9.81)
  if opts.ground then
    add_ground(world, 20)
  end
  world:add_body({
    shape = shape.circle(opts.radius or 0.15),
    position = { x = opts.x or 0, y = opts.y or -3 },
    velocity = { x = opts.vx or 5, y = opts.vy or 1 },
    friction = 0.3,
    restitution = opts.restitution or 0.6,
  })
  return world
end

-- A seeded scatter of mixed bodies.
function scenarios.heap(opts)
  opts = opts or {}
  local generator = rng.new(opts.seed or 42)
  local world = World.new(0, 9.81)
  add_ground(world, 16)
  for _ = 1, (opts.count or 24) do
    local size = generator:range(0.12, 0.28)
    local is_circle = generator:float() < 0.45
    local body_shape = is_circle and shape.circle(size) or shape.box(size, generator:range(0.12, 0.28))
    world:add_body({
      shape = body_shape,
      position = { x = generator:range(-6, 6), y = generator:range(-7, -2) },
      angle = generator:range(0, math.pi * 2),
      angular_velocity = generator:range(-3, 3),
      friction = 0.5,
    })
  end
  return world
end

-- A wide seeded scatter for broadphase stress testing.
function scenarios.swarm(opts)
  opts = opts or {}
  local generator = rng.new(opts.seed or 17)
  local count = opts.count or 80
  local world = World.new(0, 9.81)
  add_ground(world, 24)
  for _ = 1, count do
    local size = generator:range(0.10, 0.22)
    local is_circle = generator:float() < 0.4
    local body_shape = is_circle and shape.circle(size) or shape.box(size, generator:range(0.10, 0.22))
    world:add_body({
      shape = body_shape,
      position = { x = generator:range(-10, 10), y = generator:range(-12, -2) },
      angle = generator:range(0, math.pi * 2),
      angular_velocity = generator:range(-2, 2),
      friction = 0.45,
    })
  end
  return world
end

-- Default simulation lengths, in seconds.
scenarios.duration = {
  stack = 20,
  drop = 6,
  throw = 4,
  heap = 30,
  swarm = 25,
}

return scenarios
