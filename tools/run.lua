-- Tumble Lab headless runner.
--
-- Runs a scenario without a window and prints the final state, or
-- replays a recorded simulation and verifies it is identical.
--
-- Usage:
--   lua tools/run.lua <scenario> [options]
--   lua tools/run.lua --replay <file.tumble> [options]
--
-- Options:
--   --steps N        Number of fixed steps to run
--   --dt S           Fixed timestep in seconds (default 1/60)
--   --seed N         Seed for seeded scenarios
--   --record FILE    Write the recording to FILE
--   --replay FILE    Re-simulate FILE and verify all frames match
--   --tolerance S    Comparison tolerance for replay (0 = exact)
--   --quiet          Print the result only, no state table

package.path = "./?.lua;./?/init.lua;" .. package.path

local scenarios = require("scenarios")
local Recorder = require("engine.recorder")

local DEFAULT_DT = 1 / 60

local function parse_args(argv)
  local opts = { dt = DEFAULT_DT }
  local positional = {}
  local i = 1
  while i <= #argv do
    local arg = argv[i]
    if arg == "--steps" then
      opts.steps = tonumber(argv[i + 1])
      i = i + 2
    elseif arg == "--dt" then
      opts.dt = tonumber(argv[i + 1])
      i = i + 2
    elseif arg == "--seed" then
      opts.seed = tonumber(argv[i + 1])
      i = i + 2
    elseif arg == "--record" then
      opts.record = argv[i + 1]
      i = i + 2
    elseif arg == "--replay" then
      opts.replay = argv[i + 1]
      i = i + 2
    elseif arg == "--tolerance" then
      opts.tolerance = tonumber(argv[i + 1])
      i = i + 2
    elseif arg == "--quiet" then
      opts.quiet = true
      i = i + 1
    else
      positional[#positional + 1] = arg
      i = i + 1
    end
  end
  opts.scenario_name = positional[1]
  return opts
end

local function read_file(path)
  local file = assert(io.open(path, "rb"))
  local content = file:read("*a")
  file:close()
  return content
end

local function write_file(path, content)
  local file = assert(io.open(path, "wb"))
  file:write(content)
  file:close()
end

local function final_state_table(world)
  local rows = {}
  for _, body in ipairs(world.bodies) do
    rows[#rows + 1] = {
      id = body.id,
      shape = body.shape.type,
      x = body.position.x,
      y = body.position.y,
      vx = body.velocity.x,
      vy = body.velocity.y,
      angle = body.angle,
    }
  end
  return rows
end

local function print_state(world)
  local rows = final_state_table(world)
  print(string.format("bodies: %d", #rows))
  print(string.format("%-3s %-8s %10s %10s %10s %10s %10s", "id", "shape", "x", "y", "vx", "vy", "angle"))
  for _, row in ipairs(rows) do
    print(string.format(
      "%-3d %-8s %10.4f %10.4f %10.4f %10.4f %10.4f",
      row.id, row.shape, row.x, row.y, row.vx, row.vy, row.angle
    ))
  end
end

local function run_scenario(opts)
  local scenario = scenarios[opts.scenario_name]
  if not scenario then
    print("unknown scenario: " .. tostring(opts.scenario_name))
    print("available: " .. table.concat(sort_scenario_names(), ", "))
    return 1
  end
  local world = scenario({ seed = opts.seed })
  local steps = opts.steps or math.floor((scenarios.duration[opts.scenario_name] or 10) / opts.dt)

  local recorder = Recorder.new(world)
  recorder.dt = opts.dt
  world:set_on_step(function(_, _)
    recorder:tick()
  end)
  recorder:start()

  for _ = 1, steps do
    world:step(opts.dt)
  end
  recorder:stop()

  if opts.record then
    write_file(opts.record, recorder:serialize())
  end

  if not opts.quiet then
    print(string.format(
      "scenario: %s | steps: %d | dt: %s | simulated: %.3f s",
      opts.scenario_name, steps, opts.dt, steps * opts.dt
    ))
    print_state(world)
    print(string.format("contact impulse (last step): %.6f", world.stats.normal_impulse))
  end
  return 0
end

local function replay_file(opts)
  local content = read_file(opts.replay)
  local recording = Recorder.deserialize(content)
  local world = Recorder.rebuild_world(recording)

  local replay = Recorder.new(world)
  replay.dt = recording.dt
  world:set_on_step(function(_, _)
    replay:tick()
  end)
  replay:start()

  for _ = 1, #recording.frames - 1 do
    world:step(recording.dt)
  end
  replay:stop()

  local matches = Recorder.frames_match(replay.frames, recording.frames, opts.tolerance or 0)
  if not opts.quiet then
    print(string.format(
      "replay: %s | frames: %d | dt: %s | tolerance: %s",
      opts.replay, #recording.frames - 1, recording.dt, tostring(opts.tolerance or 0)
    ))
    if matches then
      print("result: identical")
    else
      print("result: mismatch")
    end
  end
  return matches and 0 or 2
end

local function sort_scenario_names()
  local names = {}
  for name in pairs(scenarios) do
    if type(scenarios[name]) == "function" then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

local opts = parse_args(arg)

if opts.replay then
  os.exit(replay_file(opts))
else
  os.exit(run_scenario(opts))
end
