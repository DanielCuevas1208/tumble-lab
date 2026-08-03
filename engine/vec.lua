-- Immutable 2D vector helpers.
-- Vectors are plain tables with x and y fields.

local vec = {}

function vec.new(x, y)
  return { x = x or 0, y = y or 0 }
end

function vec.add(a, b)
  return { x = a.x + b.x, y = a.y + b.y }
end

function vec.sub(a, b)
  return { x = a.x - b.x, y = a.y - b.y }
end

function vec.scale(a, s)
  return { x = a.x * s, y = a.y * s }
end

function vec.dot(a, b)
  return a.x * b.x + a.y * b.y
end

function vec.cross(a, b)
  return a.x * b.y - a.y * b.x
end

function vec.length(a)
  return math.sqrt(a.x * a.x + a.y * a.y)
end

function vec.length_sq(a)
  return a.x * a.x + a.y * a.y
end

function vec.distance(a, b)
  return math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
end

function vec.normalize(a)
  local length = vec.length(a)
  if length <= 0 then
    return { x = 0, y = 1 }
  end
  return { x = a.x / length, y = a.y / length }
end

function vec.perpendicular(a)
  return { x = -a.y, y = a.x }
end

function vec.rotate(a, cos_a, sin_a)
  return { x = a.x * cos_a - a.y * sin_a, y = a.x * sin_a + a.y * cos_a }
end

return vec
