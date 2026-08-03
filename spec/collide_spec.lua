local World = require("engine.world")
local shape = require("engine.shape")
local collide = require("engine.collide")

local function near(a, b, eps)
   assert.are.near(a, b, eps or 1e-6)
end

local function world_with_bodies(defs)
   local world = World.new(0, 0)
   local bodies = {}
   for i, def in ipairs(defs) do
      bodies[i] = world:add_body(def)
   end
   return world, bodies
end

describe("collide", function()
   describe("circle against circle", function()
      it("reports a contact with the normal from a to b", function()
         local _, bodies = world_with_bodies({
            { shape = shape.circle(0.2), position = { x = 0, y = 0 } },
            { shape = shape.circle(0.2), position = { x = 0, y = -0.3 } },
         })
         local contact = collide.collide(bodies[1], bodies[2])
         assert.is_not_nil(contact)
         near(contact.depth, 0.1)
         near(contact.normal.x, 0)
         near(contact.normal.y, -1)
         assert.are.equal(1, #contact.points)
      end)

      it("returns nil for separated circles", function()
         local _, bodies = world_with_bodies({
            { shape = shape.circle(0.2), position = { x = 0, y = 0 } },
            { shape = shape.circle(0.2), position = { x = 0, y = -1 } },
         })
         assert.is_nil(collide.collide(bodies[1], bodies[2]))
      end)

      it("handles concentric circles with a fixed normal", function()
         local _, bodies = world_with_bodies({
            { shape = shape.circle(0.2), position = { x = 0, y = 0 } },
            { shape = shape.circle(0.2), position = { x = 0, y = 0 } },
         })
         local contact = collide.collide(bodies[1], bodies[2])
         assert.is_not_nil(contact)
         near(contact.depth, 0.4)
         near(contact.normal.x, 0)
         near(contact.normal.y, 1)
      end)
   end)

   describe("circle against polygon", function()
      it("contacts the nearest face with a normal toward the polygon", function()
         local _, bodies = world_with_bodies({
            { shape = shape.circle(0.2), position = { x = 0, y = -0.1 } },
            { shape = shape.box(8, 0.25), kind = "static", position = { x = 0, y = 0.25 } },
         })
         local contact = collide.collide(bodies[1], bodies[2])
         assert.is_not_nil(contact)
         near(contact.depth, 0.1)
         near(contact.normal.x, 0)
         near(contact.normal.y, 1)
      end)

      it("flips the normal when the polygon is body a", function()
         local _, bodies = world_with_bodies({
            { shape = shape.circle(0.2), position = { x = 0, y = -0.1 } },
            { shape = shape.box(8, 0.25), kind = "static", position = { x = 0, y = 0.25 } },
         })
         local forward = collide.collide(bodies[1], bodies[2])
         local flipped = collide.collide(bodies[2], bodies[1])
         assert.is_not_nil(forward)
         assert.is_not_nil(flipped)
         near(flipped.normal.x, -forward.normal.x)
         near(flipped.normal.y, -forward.normal.y)
         assert.is_true(flipped.a == bodies[2] and flipped.b == bodies[1])
      end)
   end)

   describe("polygon against polygon", function()
      it("reports overlap depth and a face normal", function()
         local _, bodies = world_with_bodies({
            { shape = shape.box(0.25, 0.25), position = { x = 0, y = 0 } },
            { shape = shape.box(0.25, 0.25), position = { x = 0, y = -0.1 } },
         })
         local contact = collide.collide(bodies[1], bodies[2])
         assert.is_not_nil(contact)
         near(contact.depth, 0.4)
         near(contact.normal.x, 0)
         near(contact.normal.y, -1)
         assert.is_true(#contact.points >= 1)
      end)

      it("returns nil for separated polygons", function()
         local _, bodies = world_with_bodies({
            { shape = shape.box(0.25, 0.25), position = { x = 0, y = 0 } },
            { shape = shape.box(0.25, 0.25), position = { x = 3, y = 0 } },
         })
         assert.is_nil(collide.collide(bodies[1], bodies[2]))
      end)
   end)

   describe("broad phase", function()
      it("builds a contact list in body order", function()
         local world = World.new(0, 9.81)
         world:add_body({
            shape = shape.box(8, 0.25),
            kind = "static",
            position = { x = 0, y = 0.25 },
         })
         world:add_body({ shape = shape.circle(0.2), position = { x = 0, y = -0.19 } })
         world:add_body({ shape = shape.circle(0.2), position = { x = 2, y = -0.19 } })
         local contacts = world:detect_contacts()
         assert.are.equal(2, #contacts)
      end)
   end)
end)
