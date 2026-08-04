package.path = "./?.lua;./?/init.lua;" .. package.path

local Recorder = require("engine.recorder")
local scenarios = require("scenarios")
local shape = require("engine.shape")
local vec = require("engine.vec")

local function close_to(actual, expected, tolerance)
  local message = string.format("expected %.12f, got %.12f", expected, actual)
  assert(math.abs(actual - expected) <= tolerance, message)
end

local function snapshot(world)
  local result = {}
  for _, body in ipairs(world.bodies) do
    result[#result + 1] = {
      id = body.id,
      shape = body.shape.type,
      x = body.position.x,
      y = body.position.y,
      angle = body.angle,
    }
  end
  return result
end

local function deep_equal(first, second)
  if type(first) ~= type(second) then
    return false
  end
  if type(first) ~= "table" then
    return first == second
  end
  for key, value in pairs(first) do
    if not deep_equal(value, second[key]) then
      return false
    end
  end
  for key in pairs(second) do
    if first[key] == nil then
      return false
    end
  end
  return true
end

describe("vector and shape primitives", function()
  it("calculates vector length and dot product", function()
    local vector = vec.new(3, 4)
    assert(vec.length(vector) == 5)
    assert(vec.dot(vector, vector) == 25)
  end)

  it("centers polygons and computes mass properties", function()
    local box = shape.box(1, 2)
    local mass, inertia = shape.mass_properties(box, 3)
    assert(mass == 24)
    close_to(inertia, 40, 1e-12)
    assert(box.vertices[1].x == -1)
    assert(box.vertices[1].y == -2)
  end)
end)

describe("deterministic scenarios", function()
  it("matches the explicit Euler free-flight solution", function()
    local dt = 1 / 60
    local steps = 60
    local world = scenarios.throw({ x = 0, y = -3, vx = 5, vy = 1 })
    local body = world.bodies[1]

    for _ = 1, steps do
      world:step(dt)
    end

    local expected_y = -3 + 1 * steps * dt + 9.81 * dt * dt * steps * (steps + 1) / 2
    close_to(body.position.x, 5, 1e-12)
    close_to(body.position.y, expected_y, 1e-12)
    close_to(body.velocity.y, 1 + 9.81, 1e-12)
  end)

  it("builds identical heaps from the same seed", function()
    local first = scenarios.heap({ seed = 7, count = 10 })
    local second = scenarios.heap({ seed = 7, count = 10 })
    assert(deep_equal(snapshot(first), snapshot(second)))
  end)

  it("reports a stable ground contact after a dropped circle settles", function()
    local world = scenarios.drop({ y = -1, restitution = 0 })
    for _ = 1, 180 do
      world:step(1 / 60)
    end

    assert(world.stats.contact_count > 0)
    assert(world.stats.normal_impulse >= 0)
    assert(world.bodies[2].position.y < 0.1)
  end)
end)

describe("recording", function()
  it("rebuilds and replays every captured frame exactly", function()
    local world = scenarios.heap({ seed = 9, count = 6 })
    local recorder = Recorder.new(world)
    recorder.dt = 1 / 60
    world:set_on_step(function()
      recorder:tick()
    end)
    recorder:start()
    for _ = 1, 12 do
      world:step(recorder.dt)
    end
    recorder:stop()

    local recording = Recorder.deserialize(recorder:serialize())
    local replay_world = Recorder.rebuild_world(recording)
    local replay = Recorder.new(replay_world)
    replay.dt = recording.dt
    replay_world:set_on_step(function()
      replay:tick()
    end)
    replay:start()
    for _ = 1, #recording.frames - 1 do
      replay_world:step(recording.dt)
    end
    replay:stop()

    assert(Recorder.frames_match(replay.frames, recording.frames, 0))
  end)
end)
