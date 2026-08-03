local manifold = require("engine.collide.manifold")

-- Clips a list of points against a half-plane.
-- Points on the far side of the plane are kept. Points in front of the
-- plane are projected onto it.
local function clip(points, plane_x, plane_y, normal_x, normal_y)
   local out = {}
   for i = 1, #points do
      local p1 = points[i]
      local p2 = points[i % #points + 1]
      local d1 = (p1.x - plane_x) * normal_x + (p1.y - plane_y) * normal_y
      local d2 = (p2.x - plane_x) * normal_x + (p2.y - plane_y) * normal_y
      if d1 <= 0 then
         out[#out + 1] = p1
      end
      if (d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0) then
         local t = d1 / (d1 - d2)
         out[#out + 1] = { x = p1.x + (p2.x - p1.x) * t, y = p1.y + (p2.y - p1.y) * t }
      end
   end
   return out
end

-- Convex polygon against convex polygon, using the separating axis
-- theorem followed by reference face clipping.
return function(a, b)
   local va = a:world_vertices()
   local na = a:world_normals()
   local vb = b:world_vertices()
   local nb = b:world_normals()

   local best_sep = -math.huge
   local best_poly = nil
   local best_index = nil

   local function consider(vs, ns, poly, other)
      for i = 1, #vs do
         local n = ns[i]
         local sep = math.huge
         for j = 1, #other do
            local s = (other[j].x - vs[i].x) * n.x + (other[j].y - vs[i].y) * n.y
            if s < sep then
               sep = s
            end
         end
         if sep > best_sep then
            best_sep = sep
            best_poly = poly
            best_index = i
         end
      end
   end

   consider(va, na, a, vb)
   consider(vb, nb, b, va)
   if best_sep > 0 then
      return nil
   end

   local ref_poly = best_poly
   local ref_index = best_index
   local ref_verts = ref_poly == a and va or vb
   local ref_normals = ref_poly == a and na or nb
   local ref_normal = ref_normals[ref_index]
   local ref_vertex = ref_verts[ref_index]
   local ref_vertex2 = ref_verts[ref_index % #ref_verts + 1]
   local other_verts = ref_poly == a and vb or va
   local other_normals = ref_poly == a and nb or na

   local min_dot = math.huge
   local incident_index = 1
   for i = 1, #other_normals do
      local d = other_normals[i].x * ref_normal.x + other_normals[i].y * ref_normal.y
      if d < min_dot then
         min_dot = d
         incident_index = i
      end
   end
   local inc1 = other_verts[incident_index]
   local inc2 = other_verts[incident_index % #other_verts + 1]
   local points = { { x = inc1.x, y = inc1.y }, { x = inc2.x, y = inc2.y } }

   local ex = ref_vertex2.x - ref_vertex.x
   local ey = ref_vertex2.y - ref_vertex.y
   local length = math.sqrt(ex * ex + ey * ey)
   ex = ex / length
   ey = ey / length

   points = clip(points, ref_vertex.x, ref_vertex.y, -ex, -ey)
   if #points < 2 then
      return nil
   end
   points = clip(points, ref_vertex2.x, ref_vertex2.y, ex, ey)

   local kept = {}
   for i = 1, #points do
      local s = (points[i].x - ref_vertex.x) * ref_normal.x
         + (points[i].y - ref_vertex.y) * ref_normal.y
      if s <= 0 then
         kept[#kept + 1] = { x = points[i].x, y = points[i].y, sep = s }
      end
   end
   if #kept == 0 then
      kept[1] = { x = ref_vertex.x, y = ref_vertex.y, sep = best_sep }
   end

   local contact = manifold.new(a, b)
   local sign = ref_poly == a and 1 or -1
   contact.normal.x = ref_normal.x * sign
   contact.normal.y = ref_normal.y * sign
   contact.depth = -kept[1].sep
   for i = 1, #kept do
      if -kept[i].sep > contact.depth then
         contact.depth = -kept[i].sep
      end
      contact:add_point(kept[i].x, kept[i].y)
   end
   contact:compute_tangent()
   return contact
end
