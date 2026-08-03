local manifold = require("engine.collide.manifold")

-- Circle against convex polygon.
-- The circle is body a, the polygon is body b.
return function(circle, polygon)
   local cx, cy = circle.position.x, circle.position.y
   local radius = circle.shape.radius
   local verts = polygon:world_vertices()
   local normals = polygon:world_normals()
   local n = #verts

   local best_dist_sq = math.huge
   local best_x, best_y = 0, 0
   for i = 1, n do
      local j = i % n + 1
      local v0, v1 = verts[i], verts[j]
      local ex, ey = v1.x - v0.x, v1.y - v0.y
      local t = ((cx - v0.x) * ex + (cy - v0.y) * ey) / (ex * ex + ey * ey)
      if t < 0 then
         t = 0
      elseif t > 1 then
         t = 1
      end
      local px = v0.x + ex * t
      local py = v0.y + ey * t
      local dist_sq = (cx - px) * (cx - px) + (cy - py) * (cy - py)
      if dist_sq < best_dist_sq then
         best_dist_sq = dist_sq
         best_x, best_y = px, py
      end
   end

   local inside = true
   for i = 1, n do
      local s = (cx - verts[i].x) * normals[i].x + (cy - verts[i].y) * normals[i].y
      if s > 0 then
         inside = false
         break
      end
   end

   local contact
   if inside then
      local best_sep = -math.huge
      local best_face = 1
      for i = 1, n do
         local s = (cx - verts[i].x) * normals[i].x + (cy - verts[i].y) * normals[i].y
         if s > best_sep then
            best_sep = s
            best_face = i
         end
      end
      contact = manifold.new(circle, polygon)
      contact.normal.x = -normals[best_face].x
      contact.normal.y = -normals[best_face].y
      contact.depth = radius - best_sep
      contact:add_point(cx + contact.normal.x * radius, cy + contact.normal.y * radius)
   else
      if best_dist_sq >= radius * radius then
         return nil
      end
      local dist = math.sqrt(best_dist_sq)
      contact = manifold.new(circle, polygon)
      contact.normal.x = (best_x - cx) / dist
      contact.normal.y = (best_y - cy) / dist
      contact.depth = radius - dist
      contact:add_point(cx + contact.normal.x * radius, cy + contact.normal.y * radius)
   end
   contact:compute_tangent()
   return contact
end
