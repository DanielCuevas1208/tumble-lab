local World = require("engine.world")
local shape = require("engine.shape")

local function near(a, b, eps)
   assert.are.near(a, b, eps or 1e-6)
end

local function ground(world)
   world:add_body({
      shape = shape.box(8, 0.25),
      kind = "static",
      position = { x = 0, y = 0.25 },
      friction = 0,
      restitution = 0,
   })
end

local function drop_ball(world, opts)
   return world:add_body({
      shape = shape.circle(0.1),
      position = { x = 0, y = opts.y },
      velocity = { x = 0, y = 0 },
      friction = 0,
      restitution = opts.restitution or 0,
   })
end

describe("solver", function()
   it("rebounds with the restitution coefficient above the speed threshold", function()
      local dt = 1 / 240
      local world = World.new(0, 9.81)
      ground(world)
      local ball = drop_ball(world, { y = -1, restitution = 0.8 })

      local previous = ball.velocity.y
      local impact, rebound
      for _ = 1, 3000 do
         world:step(dt)
         local vy = ball.velocity.y
         if impact == nil and previous > 1 and vy <= 0 then
            impact = previous
            rebound = -vy
         end
         previous = vy
      end

      assert.is_not_nil(impact, "the ball must hit the ground")
      near(rebound / impact, 0.8, 0.2)
   end)

   it("does not rebound below the restitution speed threshold", function()
      local dt = 1 / 240
      local world = World.new(0, 9.81)
      ground(world)
      local ball = drop_ball(world, { y = -0.13, restitution = 0.9 })

      local minimum = 0
      for _ = 1, 1200 do
         world:step(dt)
         if ball.velocity.y < minimum then
            minimum = ball.velocity.y
         end
      end

      assert.is_true(minimum > -0.2, "the ball must settle without a visible rebound")
      near(ball.velocity.y, 0, 0.1)
   end)

   it("brings an inelastic drop to rest", function()
      local dt = 1 / 240
      local world = World.new(0, 9.81)
      ground(world)
      local ball = drop_ball(world, { y = -1, restitution = 0 })

      for _ = 1, 3000 do
         world:step(dt)
      end

      near(ball.velocity.y, 0, 0.1)
      near(ball.position.y, -0.1, 0.05)
   end)

   it("applies friction to stop a sliding body", function()
      local dt = 1 / 120
      local world = World.new(0, 9.81)
      world:add_body({
         shape = shape.box(8, 0.25),
         kind = "static",
         position = { x = 0, y = 0.25 },
         friction = 0.9,
      })
      local body = world:add_body({
         shape = shape.box(0.25, 0.25),
         position = { x = 0, y = -0.26 },
         velocity = { x = 3, y = 0 },
      })
      for _ = 1, 240 do
         world:step(dt)
      end
      assert.is_true(math.abs(body.velocity.x) < 0.05, "friction must stop sliding")
   end)

   it("keeps horizontal speed without friction", function()
      local dt = 1 / 120
      local world = World.new(0, 9.81)
      world:add_body({
         shape = shape.box(8, 0.25),
         kind = "static",
         position = { x = 0, y = 0.25 },
         friction = 0,
      })
      local body = world:add_body({
         shape = shape.box(0.25, 0.25),
         position = { x = 0, y = -0.26 },
         velocity = { x = 3, y = 0 },
      })
      for _ = 1, 240 do
         world:step(dt)
      end
      near(body.velocity.x, 3, 0.05)
   end)

   it("reports contact impulses in world stats", function()
      local world = World.new(0, 9.81)
      ground(world)
      drop_ball(world, { y = -1, restitution = 0 })

      for _ = 1, 240 do
         world:step(1 / 120)
      end

      assert.is_true(world.stats.contact_count >= 1)
      assert.is_true(world.stats.normal_impulse >= 0)
   end)
end)
