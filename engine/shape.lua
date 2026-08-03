-- Shape definitions and mass properties.
-- Polygons are convex and stored in counter-clockwise order with their
-- centroid at the local origin. The centroid is the body center of mass.

local shape = {}

local function polygon_signed_area(vertices)
  local area = 0
  for i = 1, #vertices do
    local j = i % #vertices + 1
    area = area + vertices[i].x * vertices[j].y - vertices[j].x * vertices[i].y
  end
  return area * 0.5
end

local function copy_vertices(vertices)
  local out = {}
  for i, v in ipairs(vertices) do
    out[i] = { x = v.x, y = v.y }
  end
  return out
end

-- Normalizes vertex winding to counter-clockwise order.
local function ensure_counter_clockwise(vertices)
  local area = polygon_signed_area(vertices)
  if area >= 0 then
    return copy_vertices(vertices)
  end
  local out = {}
  for i = #vertices, 1, -1 do
    out[#out + 1] = { x = vertices[i].x, y = vertices[i].y }
  end
  return out
end

local function assert_convex(vertices)
  local n = #vertices
  for i = 1, n do
    local v0 = vertices[i]
    local v1 = vertices[i % n + 1]
    local v2 = vertices[(i + 1) % n + 1]
    local cross = (v1.x - v0.x) * (v2.y - v1.y) - (v1.y - v0.y) * (v2.x - v1.x)
    if cross <= 1e-9 then
      error("polygon vertices must form a strictly convex shape")
    end
  end
end

function shape.circle(radius)
  assert(radius > 0, "circle radius must be positive")
  return { type = "circle", radius = radius }
end

function shape.box(half_width, half_height)
  assert(half_width > 0 and half_height > 0, "box half sizes must be positive")
  return {
    type = "polygon",
    vertices = {
      { x = -half_width, y = -half_height },
      { x = half_width, y = -half_height },
      { x = half_width, y = half_height },
      { x = -half_width, y = half_height },
    },
  }
end

-- Builds a convex polygon from local-space vertices. The polygon is
-- centered on its centroid and kept in counter-clockwise order.
function shape.polygon(vertices)
  assert(type(vertices) == "table" and #vertices >= 3, "polygon needs at least 3 vertices")
  local verts = ensure_counter_clockwise(vertices)
  assert_convex(verts)
  local n = #verts
  local area = polygon_signed_area(verts)
  assert(math.abs(area) > 1e-9, "polygon is degenerate")
  local cx, cy = 0, 0
  for i = 1, n do
    local j = i % n + 1
    local cross = verts[i].x * verts[j].y - verts[j].x * verts[i].y
    cx = cx + (verts[i].x + verts[j].x) * cross
    cy = cy + (verts[i].y + verts[j].y) * cross
  end
  cx = cx / (6 * area)
  cy = cy / (6 * area)
  local centered = {}
  for i, v in ipairs(verts) do
    centered[i] = { x = v.x - cx, y = v.y - cy }
  end
  return { type = "polygon", vertices = centered }
end

-- Returns mass and moment of inertia about the centroid.
function shape.mass_properties(shp, density)
  if shp.type == "circle" then
    local mass = math.pi * shp.radius * shp.radius * density
    local inertia = 0.5 * mass * shp.radius * shp.radius
    return mass, inertia
  end
  local mass, inertia = 0, 0
  local verts = shp.vertices
  for i = 1, #verts do
    local j = i % #verts + 1
    local v1, v2 = verts[i], verts[j]
    local cross = v1.x * v2.y - v2.x * v1.y
    mass = mass + cross
    inertia =
      inertia + cross * (v1.x * v1.x + v1.y * v1.y + v1.x * v2.x + v1.y * v2.y + v2.x * v2.x + v2.y * v2.y)
  end
  mass = 0.5 * density * math.abs(mass)
  inertia = density * math.abs(inertia) / 12
  return mass, inertia
end

return shape
