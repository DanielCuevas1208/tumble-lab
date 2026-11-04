-- Continuous collision queries for the documented primitive slice.
-- This module currently supports a dynamic circle against a static circle.

local continuous = {}

local TIME_EPSILON = 1e-12

local function supported_pair(a, b)
  if a.shape.type ~= "circle" or b.shape.type ~= "circle" then
    return nil
  end
  if a:is_dynamic() and not b:is_dynamic() then
    return a, b
  end
  if b:is_dynamic() and not a:is_dynamic() then
    return b, a
  end
  return nil
end

local function circle_circle_time(a, b, limit)
  local dynamic, target = supported_pair(a, b)
  if not dynamic then
    return nil
  end

  local dx = dynamic.position.x - target.position.x
  local dy = dynamic.position.y - target.position.y
  local vx = dynamic.velocity.x - target.velocity.x
  local vy = dynamic.velocity.y - target.velocity.y
  local radius = dynamic.shape.radius + target.shape.radius
  local distance_sq = dx * dx + dy * dy
  if distance_sq <= radius * radius then
    return nil
  end

  local speed_sq = vx * vx + vy * vy
  if speed_sq <= TIME_EPSILON then
    return nil
  end

  local distance_velocity = dx * vx + dy * vy
  if distance_velocity >= 0 then
    return nil
  end

  local discriminant = distance_velocity * distance_velocity
    - speed_sq * (distance_sq - radius * radius)
  if discriminant < 0 then
    return nil
  end

  local time = (-distance_velocity - math.sqrt(discriminant)) / speed_sq
  if time <= TIME_EPSILON or time > limit + TIME_EPSILON then
    return nil
  end
  return time
end

-- Returns the earliest supported impact within the remaining fixed step.
function continuous.find_earliest(bodies, limit)
  local best_time = nil
  local events = {}
  for i = 1, #bodies do
    for j = i + 1, #bodies do
      local a, b = bodies[i], bodies[j]
      local time = circle_circle_time(a, b, limit)
      if time then
        local candidate = { time = time, a = a, b = b }
        if not best_time or time < best_time - TIME_EPSILON then
          best_time = time
          events = { candidate }
        elseif math.abs(time - best_time) <= TIME_EPSILON then
          events[#events + 1] = candidate
        end
      end
    end
  end
  if not best_time then
    return nil
  end
  table.sort(events, function(first, second)
    if first.a.id ~= second.a.id then
      return first.a.id < second.a.id
    end
    return first.b.id < second.b.id
  end)
  return { time = best_time, a = events[1].a, b = events[1].b, events = events }
end

return continuous
