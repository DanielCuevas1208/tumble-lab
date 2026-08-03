-- Sequential impulse solver with warm starting.
-- Restitution and Baumgarte position correction are expressed as a
-- velocity bias inside the velocity solve, following the classic
-- Box2D-lite formulation.

local config = require("engine.config")

local solver = {}

local function pair_key(a, b)
   local low, high = a.id, b.id
   if low > high then
      low, high = high, low
   end
   return low * 1048576 + high
end

local function relative_velocity(contact, point)
   local a, b = contact.a, contact.b
   local rax = point.x - a.position.x
   local ray = point.y - a.position.y
   local rbx = point.x - b.position.x
   local rby = point.y - b.position.y
   return {
      x = (b.velocity.x - b.angular_velocity * rby) - (a.velocity.x - a.angular_velocity * ray),
      y = (b.velocity.y + b.angular_velocity * rbx) - (a.velocity.y + a.angular_velocity * rax),
   }
end

local function apply_impulse(contact, point, px, py)
   local a, b = contact.a, contact.b
   local rax = point.x - a.position.x
   local ray = point.y - a.position.y
   local rbx = point.x - b.position.x
   local rby = point.y - b.position.y
   a.velocity.x = a.velocity.x - px * a.inv_mass
   a.velocity.y = a.velocity.y - py * a.inv_mass
   a.angular_velocity = a.angular_velocity - a.inv_inertia * (rax * py - ray * px)
   b.velocity.x = b.velocity.x + px * b.inv_mass
   b.velocity.y = b.velocity.y + py * b.inv_mass
   b.angular_velocity = b.angular_velocity + b.inv_inertia * (rbx * py - rby * px)
end

local function solve_normal(contact, point)
   local a, b = contact.a, contact.b
   local rax = point.x - a.position.x
   local ray = point.y - a.position.y
   local rbx = point.x - b.position.x
   local rby = point.y - b.position.y
   local n = contact.normal
   local rn_a = rax * n.y - ray * n.x
   local rn_b = rbx * n.y - rby * n.x
   local kn = a.inv_mass + b.inv_mass + a.inv_inertia * rn_a * rn_a + b.inv_inertia * rn_b * rn_b
   if kn == 0 then
      return
   end
   local dv = relative_velocity(contact, point)
   local vn = dv.x * n.x + dv.y * n.y
   local impulse = (-vn + contact.bias) / kn
   local new_pn = point.pn + impulse
   if new_pn < 0 then
      new_pn = 0
   end
   impulse = new_pn - point.pn
   point.pn = new_pn
   apply_impulse(contact, point, impulse * n.x, impulse * n.y)
end

local function solve_tangent(contact, point)
   local a, b = contact.a, contact.b
   local rax = point.x - a.position.x
   local ray = point.y - a.position.y
   local rbx = point.x - b.position.x
   local rby = point.y - b.position.y
   local t = contact.tangent
   local rt_a = rax * t.y - ray * t.x
   local rt_b = rbx * t.y - rby * t.x
   local kt = a.inv_mass + b.inv_mass + a.inv_inertia * rt_a * rt_a + b.inv_inertia * rt_b * rt_b
   if kt == 0 then
      return
   end
   local dv = relative_velocity(contact, point)
   local vt = dv.x * t.x + dv.y * t.y
   local impulse = -vt / kt
   local max_pt = contact.friction * point.pn
   local new_pt = point.pt + impulse
   if new_pt > max_pt then
      new_pt = max_pt
   elseif new_pt < -max_pt then
      new_pt = -max_pt
   end
   impulse = new_pt - point.pt
   point.pt = new_pt
   apply_impulse(contact, point, impulse * t.x, impulse * t.y)
end

-- Prepares contacts for the step: restitution, position bias, warm
-- starting, and cache lookups.
function solver.prepare(contacts, cache, dt)
   local inv_dt = 1 / dt
   for _, contact in ipairs(contacts) do
      local point = contact.points[1]
      local dv = relative_velocity(contact, point)
      local vn = dv.x * contact.normal.x + dv.y * contact.normal.y
      contact.bias = 0
      if vn < -config.restitution_threshold and contact.restitution > 0 then
         contact.bias = -contact.restitution * vn
      end
      -- Skip position bias on a bouncing contact. Adding both would
      -- inflate the rebound impulse beyond the restitution coefficient.
      if contact.bias == 0 then
         contact.bias = config.baumgarte * inv_dt * math.max(contact.depth - config.slop, 0)
      end

      local key = pair_key(contact.a, contact.b)
      local previous = cache[key]
      if
         previous
         and (previous.normal.x * contact.normal.x + previous.normal.y * contact.normal.y) > 0
      then
         for i, pt in ipairs(contact.points) do
            local cached = previous.points[i] or previous.points[#previous.points]
            pt.pn = cached.pn
            pt.pt = cached.pt
         end
      end
      for _, pt in ipairs(contact.points) do
         if pt.pn ~= 0 or pt.pt ~= 0 then
            local n = contact.normal
            local t = contact.tangent
            apply_impulse(contact, pt, n.x * pt.pn + t.x * pt.pt, n.y * pt.pn + t.y * pt.pt)
         end
      end
   end
end

-- Stores accumulated impulses for the next step's warm start.
function solver.store(contacts, cache, stats)
   stats.normal_impulse = 0
   stats.tangent_impulse = 0
   for _, contact in ipairs(contacts) do
      local key = pair_key(contact.a, contact.b)
      local entry = { normal = { x = contact.normal.x, y = contact.normal.y }, points = {} }
      for i, pt in ipairs(contact.points) do
         entry.points[i] = { pn = pt.pn, pt = pt.pt }
         stats.normal_impulse = stats.normal_impulse + pt.pn
         stats.tangent_impulse = stats.tangent_impulse + math.abs(pt.pt)
      end
      cache[key] = entry
   end
end

function solver.solve(contacts, cache, stats, dt)
   solver.prepare(contacts, cache, dt)
   for _ = 1, config.velocity_iterations do
      for _, contact in ipairs(contacts) do
         for _, point in ipairs(contact.points) do
            solve_normal(contact, point)
            solve_tangent(contact, point)
         end
      end
   end
   solver.store(contacts, cache, stats)
end

return solver
