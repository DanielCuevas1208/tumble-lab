local rng = require("engine.rng")

describe("rng", function()
   it("produces the known Park-Miller first value", function()
      assert.are.equal(48271, rng.new(1):next_int())
   end)

   it("reproduces the same sequence for the same seed", function()
      local a = rng.new(1234)
      local b = rng.new(1234)
      for _ = 1, 20 do
         assert.are.equal(a:next_int(), b:next_int())
      end
   end)

   it("produces different sequences for different seeds", function()
      local a = rng.new(1)
      local b = rng.new(2)
      local different = false
      for _ = 1, 10 do
         if a:next_int() ~= b:next_int() then
            different = true
            break
         end
      end
      assert.is_true(different)
   end)

   it("keeps the state away from zero after seeding", function()
      assert.are.equal(1, rng.new(0).state)
   end)

   it("returns floats in the half-open interval [0, 1)", function()
      local generator = rng.new(7)
      for _ = 1, 1000 do
         local value = generator:float()
         assert.is_true(value >= 0 and value < 1)
      end
   end)

   it("returns values inside the requested range", function()
      local generator = rng.new(9)
      for _ = 1, 1000 do
         local value = generator:range(-5, 5)
         assert.is_true(value >= -5 and value < 5)
      end
   end)

   it("returns integers inside the closed interval", function()
      local generator = rng.new(11)
      for _ = 1, 2000 do
         local value = generator:integer(1, 6)
         assert.is_true(value >= 1 and value <= 6)
         assert.are.equal(value, math.floor(value))
      end
   end)

   it("resets the sequence after reseeding", function()
      local generator = rng.new(42)
      local first = generator:next_int()
      generator:seed(42)
      assert.are.equal(first, generator:next_int())
   end)
end)
