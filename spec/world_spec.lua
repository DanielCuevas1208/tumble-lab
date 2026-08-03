local World = require("engine.world")
local shape = require("engine.shape")
local scenarios = require("scenarios")

local function near(a, b, eps)
   assert.are.near(a, b, eps or 1e-9)
end

local function body_state(world)
   local out = {}
   for _, body in ipairs(world.bodies) do
      out[body.id] = {
         body.position.x,
         body.position.y,
         body.angle,
         body.velocity.x,
         body.velocity.y,
         body.angular_velocity,
      }
   end
   return out
end

describe("world", function()
   it("assigns unique ids in insertion order", function()
      local world = World.new(0, 9.81)
      local a = world:add_body({ shape = shape.circle(1) })
      local b = world:add_body({ shape = shape.box(1, 1) })
      assert.are.equal(1, a.id)
      assert.are.equal(2, b.id)
   end)

   it("removes and looks up bodies by id", function()
      local world = World.new(0, 9.81)
      local a = world:add_body({ shape = shape.circle(1) })
      world:add_body({ shape = shape.box(1, 1) })
      world:remove_body(a)
      assert.is_nil(world:body_by_id(a.id))
   end)

   it("clears the world", function()
      local world = World.new(0, 9.81)
      world:add_body({ shape = shape.circle(1) })
      world:clear()
      assert.are.equal(0, #world.bodies)
      assert.are.equal(1, world:next_body_id())
   end)

   it("never moves static bodies", function()
      local world = World.new(0, 9.81)
      local ground = world:add_body({
         shape = shape.box(8, 0.25),
         kind = "static",
         position = { x = 0, y = 0.25 },
      })
      local ball = world:add_body({
         shape = shape.circle(0.2),
         position = { x = 0, y = -2 },
         velocity = { x = 5, y = 0 },
      })
      for _ = 1, 60 do
         world:step(1 / 60)
      end
      assert.are.equal(0, ground.position.x)
      assert.are.equal(0.25, ground.position.y)
      assert.is_true(ball.position.x > 4)
   end)

   it("integrates a free body exactly under constant velocity", function()
      local world = World.new(0, 0)
      local body = world:add_body({
         shape = shape.circle(0.1),
         position = { x = 1, y = -2 },
         velocity = { x = 3, y = -4 },
      })
      local dt, steps = 1 / 60, 120
      for _ = 1, steps do
         world:step(dt)
      end
      near(body.position.x, 1 + 3 * steps * dt)
      near(body.position.y, -2 - 4 * steps * dt)
   end)

   it("matches the discrete gravity trajectory", function()
      local dt, steps = 1 / 60, 120
      local world = World.new(0, 9.81)
      local body = world:add_body({
         shape = shape.circle(0.1),
         position = { x = 5, y = -3 },
         velocity = { x = 5, y = 1 },
      })
      for _ = 1, steps do
         world:step(dt)
      end
      near(body.position.x, 5 + 5 * steps * dt)
      near(body.position.y, -3 + steps * dt + 9.81 * dt * dt * steps * (steps + 1) / 2)
   end)

   it("applies accumulated forces once and clears them", function()
      local world = World.new(0, 0)
      local body = world:add_body({ shape = shape.circle(1), density = 2 })
      local dt = 1 / 60
      body:apply_force(10, 0)
      world:step(dt)
      near(body.velocity.x, 10 / body.mass * dt)
      world:step(dt)
      near(body.velocity.x, 10 / body.mass * dt)
   end)

   it("calls the step callback once per step", function()
      local world = World.new(0, 9.81)
      world:add_body({ shape = shape.circle(1) })
      local calls = 0
      world:set_on_step(function()
         calls = calls + 1
      end)
      for _ = 1, 5 do
         world:step(1 / 60)
      end
      assert.are.equal(5, calls)
      assert.are.equal(5, world.step_count)
   end)

   it("respects gravity changes", function()
      local world = World.new(0, 0)
      local body = world:add_body({ shape = shape.circle(1) })
      world:step(1 / 60)
      assert.are.equal(0, body.velocity.y)
      world:set_gravity(0, -5)
      world:step(1 / 60)
      near(body.velocity.y, -5 / 60)
   end)

   it("produces identical trajectories for identical inputs", function()
      local dt, steps = 1 / 60, 600
      local a = scenarios.heap({ seed = 42 })
      local b = scenarios.heap({ seed = 42 })
      for _ = 1, steps do
         a:step(dt)
         b:step(dt)
      end
      local state_a, state_b = body_state(a), body_state(b)
      for id, fields in pairs(state_a) do
         for k = 1, 6 do
            assert.are.equal(fields[k], state_b[id][k])
         end
      end
   end)

   it("keeps a resting stack inside bounds", function()
      local dt, steps = 1 / 60, 300
      local world = scenarios.stack({ count = 6 })
      for _ = 1, steps do
         world:step(dt)
      end
      for _, body in ipairs(world.bodies) do
         if body:is_dynamic() then
            assert.is_true(body.position.y < -0.1, "box must not sink through the ground")
            assert.is_true(math.abs(body.position.x) < 2, "stack must stay upright")
         end
      end
   end)
end)
