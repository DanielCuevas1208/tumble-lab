-- A contact manifold describes one pair of touching bodies.
-- The normal points from body a toward body b.

local manifold = {}
manifold.__index = manifold

function manifold.new(a, b)
  return setmetatable({
    a = a,
    b = b,
    normal = { x = 0, y = 0 },
    tangent = { x = 0, y = 0 },
    depth = 0,
    friction = math.min(a.friction, b.friction),
    restitution = math.max(a.restitution, b.restitution),
    bias = 0,
    points = {},
  }, manifold)
end

function manifold:add_point(x, y)
  self.points[#self.points + 1] = { x = x, y = y, pn = 0, pt = 0 }
end

function manifold:compute_tangent()
  self.tangent.x = -self.normal.y
  self.tangent.y = self.normal.x
end

return manifold
