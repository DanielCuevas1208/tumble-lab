local manifold = require("engine.collide.manifold")

-- Circle against circle.
return function(a, b)
  local ax, ay = a.position.x, a.position.y
  local bx, by = b.position.x, b.position.y
  local dx, dy = bx - ax, by - ay
  local radius_sum = a.shape.radius + b.shape.radius
  local dist_sq = dx * dx + dy * dy
  if dist_sq > radius_sum * radius_sum then
    return nil
  end
  local contact = manifold.new(a, b)
  if dist_sq > 1e-12 then
    local dist = math.sqrt(dist_sq)
    contact.normal.x = dx / dist
    contact.normal.y = dy / dist
    contact.depth = radius_sum - dist
  else
    contact.normal.x = 0
    contact.normal.y = 1
    contact.depth = radius_sum
  end
  contact:add_point(ax + contact.normal.x * (a.shape.radius - contact.depth * 0.5), ay + contact.normal.y * (a.shape.radius - contact.depth * 0.5))
  contact:compute_tangent()
  return contact
end
