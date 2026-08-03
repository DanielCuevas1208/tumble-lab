local shape = require("engine.shape")

local function near(a, b, eps)
   assert.are.near(a, b, eps or 1e-9)
end

local function signed_area(vertices)
   local area = 0
   for i = 1, #vertices do
      local j = i % #vertices + 1
      area = area + vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y
   end
   return area * 0.5
end

describe("shape", function()
   describe("circle", function()
      it("builds a circle shape", function()
         local circle = shape.circle(0.25)
         assert.are.equal("circle", circle.type)
         assert.are.equal(0.25, circle.radius)
      end)

      it("rejects a non-positive radius", function()
         assert.has_error(function()
            shape.circle(0)
         end)
      end)
   end)

   describe("box", function()
      it("builds a four-vertex counter-clockwise polygon", function()
         local box = shape.box(0.25, 0.5)
         assert.are.equal("polygon", box.type)
         assert.are.equal(4, #box.vertices)
         assert.are.equal(-0.25, box.vertices[1].x)
         assert.are.equal(-0.5, box.vertices[1].y)
         assert.is_true(signed_area(box.vertices) > 0)
      end)

      it("rejects a non-positive half size", function()
         assert.has_error(function()
            shape.box(-1, 1)
         end)
      end)
   end)

   describe("polygon", function()
      it("normalizes clockwise input to counter-clockwise order", function()
         local polygon = shape.polygon({
            { x = 0, y = 0 },
            { x = 0, y = 1 },
            { x = 1, y = 1 },
            { x = 1, y = 0 },
         })
         assert.is_true(signed_area(polygon.vertices) > 0)
      end)

      it("centers the polygon on its centroid", function()
         local polygon = shape.polygon({
            { x = 2, y = 0 },
            { x = 0, y = 2 },
            { x = -2, y = 0 },
            { x = 0, y = -2 },
         })
         local sum_x, sum_y = 0, 0
         for _, vertex in ipairs(polygon.vertices) do
            sum_x = sum_x + vertex.x
            sum_y = sum_y + vertex.y
         end
         near(sum_x, 0)
         near(sum_y, 0)
      end)

      it("rejects concave vertices", function()
         assert.has_error(function()
            shape.polygon({
               { x = 0, y = 0 },
               { x = 2, y = 0 },
               { x = 1, y = 1 },
               { x = 2, y = 2 },
               { x = 0, y = 2 },
            })
         end)
      end)

      it("rejects fewer than three vertices", function()
         assert.has_error(function()
            shape.polygon({ { x = 0, y = 0 }, { x = 1, y = 0 } })
         end)
      end)
   end)

   describe("mass properties", function()
      it("computes circle mass and inertia", function()
         local radius, density = 0.2, 2.0
         local mass, inertia = shape.mass_properties(shape.circle(radius), density)
         near(mass, math.pi * radius * radius * density)
         near(inertia, 0.5 * math.pi * radius * radius * density * radius * radius)
      end)

      it("computes box mass and inertia", function()
         local half_width, half_height, density = 0.25, 0.25, 1.0
         local mass, inertia = shape.mass_properties(shape.box(half_width, half_height), density)
         local area = 4 * half_width * half_height
         local radius_sq = half_width * half_width + half_height * half_height
         near(mass, area * density)
         near(inertia, area * density * radius_sq / 3)
      end)
   end)
end)
