-- Collision detection dispatcher. Picks the narrowphase routine for a
-- body pair and normalizes the manifold so the normal always points
-- from body a to body b.

local circle_circle = require("engine.collide.circle_circle")
local circle_polygon = require("engine.collide.circle_polygon")
local poly_poly = require("engine.collide.poly_poly")

local collide = {}

function collide.collide(a, b)
   local a_type = a.shape.type
   local b_type = b.shape.type
   local contact
   if a_type == "circle" and b_type == "circle" then
      contact = circle_circle(a, b)
   elseif a_type == "circle" and b_type == "polygon" then
      contact = circle_polygon(a, b)
   elseif a_type == "polygon" and b_type == "circle" then
      contact = circle_polygon(b, a)
      if contact then
         contact.normal.x = -contact.normal.x
         contact.normal.y = -contact.normal.y
         contact.a = a
         contact.b = b
         contact:compute_tangent()
      end
   else
      contact = poly_poly(a, b)
   end
   return contact
end

return collide
