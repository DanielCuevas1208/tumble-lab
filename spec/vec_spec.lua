local vec = require("engine.vec")

local function near(a, b, eps)
   assert.are.near(a, b, eps or 1e-9)
end

describe("vec", function()
   it("constructs a vector with default coordinates", function()
      local v = vec.new()
      assert.are.equal(0, v.x)
      assert.are.equal(0, v.y)
   end)

   it("adds and subtracts vectors", function()
      local sum = vec.add({ x = 1, y = 2 }, { x = 3, y = 4 })
      local diff = vec.sub(sum, { x = 2, y = 6 })
      assert.are.equal(2, diff.x)
      assert.are.equal(0, diff.y)
   end)

   it("scales a vector", function()
      local scaled = vec.scale({ x = 3, y = -4 }, 0.5)
      assert.are.equal(1.5, scaled.x)
      assert.are.equal(-2, scaled.y)
   end)

   it("computes dot and cross products", function()
      assert.are.equal(11, vec.dot({ x = 1, y = 2 }, { x = 3, y = 4 }))
      assert.are.equal(-2, vec.cross({ x = 1, y = 2 }, { x = 3, y = 4 }))
   end)

   it("computes length and squared length", function()
      assert.are.equal(5, vec.length({ x = 3, y = 4 }))
      assert.are.equal(25, vec.length_sq({ x = 3, y = 4 }))
   end)

   it("computes distance", function()
      assert.are.equal(5, vec.distance({ x = 0, y = 0 }, { x = 3, y = 4 }))
   end)

   it("normalizes a vector to unit length", function()
      local unit = vec.normalize({ x = 3, y = 4 })
      near(vec.length(unit), 1)
      near(unit.x, 0.6)
      near(unit.y, 0.8)
   end)

   it("gives a stable fallback for the zero vector", function()
      local unit = vec.normalize({ x = 0, y = 0 })
      assert.are.equal(0, unit.x)
      assert.are.equal(1, unit.y)
   end)

   it("computes perpendicular and rotation", function()
      local perp = vec.perpendicular({ x = 1, y = 0 })
      assert.are.equal(0, perp.x)
      assert.are.equal(1, perp.y)

      local rotated = vec.rotate({ x = 1, y = 0 }, 0, 1)
      near(rotated.x, 0)
      near(rotated.y, 1)
   end)
end)
