local scenes = require("scenes")

local function noop() end

local function install_love_stub()
   local love = {
      event = {
         quit = noop,
      },
      graphics = {
         getDimensions = function()
            return 960, 720
         end,
         clear = noop,
         setColor = noop,
         line = noop,
         circle = noop,
         polygon = noop,
         print = noop,
      },
      timer = {
         getFPS = function()
            return 60
         end,
      },
      math = {
         random = function(low, high)
            if high then
               return low + (high - low) * 0.5
            end
            if low then
               return low * 0.5
            end
            return 0.5
         end,
      },
   }
   _G.love = love
   return love
end

describe("sandbox", function()
   it("builds a scene for every scenario", function()
      assert.are.equal(4, #scenes.names)
      for _, name in ipairs(scenes.names) do
         local scene = scenes.new(name)
         assert.is_true(#scene.world.bodies >= 1)
         assert.are.equal(name, scene.name)
      end
   end)

   it("steps a scene with a fixed timestep", function()
      local scene = scenes.new("drop")
      local ball = scene.world.bodies[2]
      local start_y = ball.position.y
      for _ = 1, 60 do
         scene:update(1 / 60)
      end
      assert.are.equal(60, scene.world.step_count)
      assert.is_true(ball.position.y > start_y)
   end)

   it("accumulates multiple physics steps in one update", function()
      local scene = scenes.new("drop")
      scene:update(1 / 30)
      assert.are.equal(2, scene.world.step_count)
   end)

   it("respects pause, single step, and reset", function()
      local scene = scenes.new("drop")
      scene:update(1 / 60)
      scene.paused = true
      scene:update(1)
      assert.are.equal(1, scene.world.step_count)
      scene:step_once()
      assert.are.equal(2, scene.world.step_count)
      scene:reset()
      assert.are.equal(0, scene.world.step_count)
   end)

   it("wires the LOVE callbacks in main.lua", function()
      local love_stub = install_love_stub()
      dofile("main.lua")
      love_stub.load()
      love_stub.update(1 / 60)
      love_stub.draw()
      love_stub.keypressed("2")
      love_stub.keypressed("space")
      love_stub.mousepressed(480, 300, 1)
      love_stub.keypressed("r")
   end)
end)
