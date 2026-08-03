-- A rigid body. Dynamic bodies move under gravity and impulses.
-- Static bodies never move; they act as immovable colliders.

local shape = require("engine.shape")

local Body = {}
Body.__index = Body

function Body.new(world, def)
  local self = setmetatable({}, Body)
  self.world = world
  self.id = world:next_body_id()
  self.shape = def.shape
  self.kind = def.kind == "static" and "static" or "dynamic"
  self.position = { x = def.position and def.position.x or 0, y = def.position and def.position.y or 0 }
  self.angle = def.angle or 0
  self.velocity = { x = def.velocity and def.velocity.x or 0, y = def.velocity and def.velocity.y or 0 }
  self.angular_velocity = def.angular_velocity or 0
  self.force = { x = 0, y = 0 }
  self.torque = 0
  self.density = def.density or 1
  self.friction = def.friction or 0.4
  self.restitution = def.restitution or 0
  self.user_data = def.user_data
  if self.kind == "static" then
    self.mass = 0
    self.inv_mass = 0
    self.inertia = 0
    self.inv_inertia = 0
  else
    local mass, inertia = shape.mass_properties(self.shape, self.density)
    self.mass = mass
    self.inv_mass = 1 / mass
    self.inertia = inertia
    self.inv_inertia = 1 / inertia
  end
  self._dirty = true
  return self
end

function Body:is_dynamic()
  return self.inv_mass > 0
end

function Body:set_position(x, y)
  self.position.x = x
  self.position.y = y
  self._dirty = true
end

function Body:set_angle(angle)
  self.angle = angle
  self._dirty = true
end

function Body:set_velocity(x, y)
  self.velocity.x = x
  self.velocity.y = y
end

function Body:set_angular_velocity(w)
  self.angular_velocity = w
end

-- Applies an impulse at a world point, or at the center of mass.
function Body:apply_impulse(ix, iy, px, py)
  self.velocity.x = self.velocity.x + ix * self.inv_mass
  self.velocity.y = self.velocity.y + iy * self.inv_mass
  if px then
    local rx = px - self.position.x
    local ry = py - self.position.y
    self.angular_velocity = self.angular_velocity + self.inv_inertia * (rx * iy - ry * ix)
  end
end

-- Accumulates a force. Forces are consumed at the next world step.
function Body:apply_force(fx, fy)
  self.force.x = self.force.x + fx
  self.force.y = self.force.y + fy
end

function Body:apply_torque(torque)
  self.torque = self.torque + torque
end

-- World-space polygon vertices, cached until the body changes.
function Body:world_vertices()
  if self._dirty or not self._world_vertices then
    local cos_a = math.cos(self.angle)
    local sin_a = math.sin(self.angle)
    self._cos, self._sin = cos_a, sin_a
    local px, py = self.position.x, self.position.y
    local verts = {}
    for i, v in ipairs(self.shape.vertices) do
      verts[i] = {
        x = px + v.x * cos_a - v.y * sin_a,
        y = py + v.x * sin_a + v.y * cos_a,
      }
    end
    self._world_vertices = verts
    self._world_normals = nil
    self._dirty = false
  end
  return self._world_vertices
end

-- World-space outward face normals, one per polygon vertex.
function Body:world_normals()
  self:world_vertices()
  if not self._world_normals then
    local verts = self._world_vertices
    local normals = {}
    for i = 1, #verts do
      local j = i % #verts + 1
      local dx = verts[j].x - verts[i].x
      local dy = verts[j].y - verts[i].y
      local length = math.sqrt(dx * dx + dy * dy)
      normals[i] = { x = dy / length, y = -dx / length }
    end
    self._world_normals = normals
  end
  return self._world_normals
end

-- Axis-aligned bounding box in world space.
function Body:get_aabb()
  if self._dirty or not self._aabb then
    if self.shape.type == "circle" then
      local radius = self.shape.radius
      local x, y = self.position.x, self.position.y
      self._aabb = {
        min_x = x - radius,
        max_x = x + radius,
        min_y = y - radius,
        max_y = y + radius,
      }
    else
      local verts = self:world_vertices()
      local min_x, min_y = math.huge, math.huge
      local max_x, max_y = -math.huge, -math.huge
      for _, v in ipairs(verts) do
        if v.x < min_x then
          min_x = v.x
        end
        if v.x > max_x then
          max_x = v.x
        end
        if v.y < min_y then
          min_y = v.y
        end
        if v.y > max_y then
          max_y = v.y
        end
      end
      self._aabb = { min_x = min_x, max_x = max_x, min_y = min_y, max_y = max_y }
    end
  end
  return self._aabb
end

return Body
