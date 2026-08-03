local scenarios = require("scenarios")

describe("scenarios", function()
   it("builds every scenario with a positive duration", function()
      for _, name in ipairs({ "stack", "drop", "throw", "heap" }) do
         local builder = scenarios[name]
         assert.is_function(builder)
         assert.is_true(scenarios.duration[name] > 0)
         local world = builder()
         assert.is_true(#world.bodies >= 1)
         assert.is_true(world.gravity.y > 0)
      end
   end)

   it("makes the heap scenario seeded and deterministic", function()
      local a = scenarios.heap({ seed = 3 })
      local b = scenarios.heap({ seed = 3 })
      assert.are.equal(#a.bodies, #b.bodies)
      for i = 1, #a.bodies do
         assert.are.equal(a.bodies[i].position.x, b.bodies[i].position.x)
         assert.are.equal(a.bodies[i].position.y, b.bodies[i].position.y)
         assert.are.equal(a.bodies[i].angle, b.bodies[i].angle)
      end
   end)

   it("supports scenario options", function()
      local tall = scenarios.stack({ count = 3 })
      local short = scenarios.stack({ count = 5 })
      assert.are.equal(4, #tall.bodies)
      assert.are.equal(6, #short.bodies)
   end)
end)
