local Recorder = require("engine.recorder")
local scenarios = require("scenarios")

local function run(recorder, world, steps, dt)
   recorder:start()
   world:set_on_step(function(_, _)
      recorder:tick()
   end)
   for _ = 1, steps do
      world:step(dt)
   end
   recorder:stop()
end

describe("recorder", function()
   it("round-trips a recording through text", function()
      local world = scenarios.drop()
      local recorder = Recorder.new(world)
      recorder.dt = 1 / 60
      run(recorder, world, 90, recorder.dt)

      local parsed = Recorder.deserialize(recorder:serialize())
      assert.are.equal(1 / 60, parsed.dt)
      assert.are.equal(9.81, parsed.gravity.y)
      assert.are.equal(#world.bodies, #parsed.initial)
      assert.are.equal(#recorder.frames, #parsed.frames)
      for i = 1, #world.bodies do
         assert.are.equal(recorder.initial[i].id, parsed.initial[i].id)
      end
   end)

   it("starts a recording with a TUMBLE header", function()
      local world = scenarios.drop()
      local recorder = Recorder.new(world)
      recorder.dt = 1 / 60
      run(recorder, world, 30, recorder.dt)

      local text = recorder:serialize()
      assert.is_not_nil(text:find("^TUMBLE 1"))
      assert.is_not_nil(text:find("frames 31"))
   end)

   it("reproduces an exact replay from a serialized recording", function()
      local dt = 1 / 60
      local world = scenarios.heap({ seed = 7 })
      local recorder = Recorder.new(world)
      recorder.dt = dt
      run(recorder, world, 300, dt)

      local recording = Recorder.deserialize(recorder:serialize())
      local rebuilt = Recorder.rebuild_world(recording)
      local replay = Recorder.new(rebuilt)
      replay.dt = recording.dt
      run(replay, rebuilt, #recording.frames - 1, recording.dt)

      assert.is_true(Recorder.frames_match(replay.frames, recording.frames, 0))
   end)

   it("compares frames exactly or with a tolerance", function()
      local a = { { { x = 1, y = 2, vx = 0, vy = 0, angle = 0, w = 0, id = 1 } } }
      local b = { { { x = 1, y = 2, vx = 0, vy = 0, angle = 0, w = 0, id = 1 } } }
      assert.is_true(Recorder.frames_match(a, b, 0))

      b[1][1].x = 1.0001
      assert.is_false(Recorder.frames_match(a, b, 0))
      assert.is_true(Recorder.frames_match(a, b, 0.001))
   end)

   it("detects frame count and frame length differences", function()
      local frame = { x = 0, y = 0, vx = 0, vy = 0, angle = 0, w = 0, id = 1 }
      local a = { { frame } }
      local b = { { { x = 0, y = 0, vx = 0, vy = 0, angle = 0, w = 0, id = 1 } }, {} }
      assert.is_false(Recorder.frames_match(a, {}, 0))
      assert.is_false(Recorder.frames_match(a, b, 0))
   end)
end)
