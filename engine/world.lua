-- A physics world owns bodies, steps the simulation, and solves
-- contacts. All behavior is deterministic: bodies are processed in
-- insertion order and the contact list is built in body order.

local Body = require("engine.body")
local collide = require("engine.collide")
local solver = require("engine.solver")

local World = {}
World.__index = World

function World.new(gravity_x, gravity_y)
   local self = setmetatable({}, World)
   self.gravity = { x = gravity_x or 0, y = gravity_y or 9.81 }
   self.bodies = {}
   self._next_body_id = 1
   self.contact_cache = {}
   self.step_count = 0
   self.on_step = nil
   self.stats = { normal_impulse = 0, tangent_impulse = 0, contact_count = 0 }
   return self
end

function World:set_gravity(x, y)
   self.gravity.x = x
   self.gravity.y = y
end

function World:next_body_id()
   local id = self._next_body_id
   self._next_body_id = self._next_body_id + 1
   return id
end

function World:add_body(def)
   local body = Body.new(self, def)
   self.bodies[#self.bodies + 1] = body
   return body
end

function World:remove_body(body)
   for i = #self.bodies, 1, -1 do
      if self.bodies[i] == body then
         table.remove(self.bodies, i)
         return
      end
   end
end

function World:clear()
   self.bodies = {}
   self.contact_cache = {}
   self._next_body_id = 1
   self.step_count = 0
end

function World:body_by_id(id)
   for _, body in ipairs(self.bodies) do
      if body.id == id then
         return body
      end
   end
   return nil
end

function World:set_on_step(callback)
   self.on_step = callback
end

-- Steps the simulation by a fixed time slice.
function World:step(dt)
   for _, body in ipairs(self.bodies) do
      body._dirty = true
   end
   for _, body in ipairs(self.bodies) do
      if body:is_dynamic() then
         body.velocity.x = body.velocity.x + (self.gravity.x + body.force.x * body.inv_mass) * dt
         body.velocity.y = body.velocity.y + (self.gravity.y + body.force.y * body.inv_mass) * dt
         body.angular_velocity = body.angular_velocity + body.torque * body.inv_inertia * dt
         body.force.x = 0
         body.force.y = 0
         body.torque = 0
      end
   end

   local contacts = self:detect_contacts()
   self.stats.contact_count = #contacts
   solver.solve(contacts, self.contact_cache, self.stats, dt)

   for _, body in ipairs(self.bodies) do
      if body:is_dynamic() then
         body.position.x = body.position.x + body.velocity.x * dt
         body.position.y = body.position.y + body.velocity.y * dt
         body.angle = body.angle + body.angular_velocity * dt
         body._dirty = true
      end
   end

   self.step_count = self.step_count + 1
   if self.on_step then
      self.on_step(self, dt)
   end
end

-- Builds the contact list for this step. Pair order follows body order,
-- which keeps the result deterministic.
function World:detect_contacts()
   local contacts = {}
   local bodies = self.bodies
   for i = 1, #bodies do
      local a = bodies[i]
      for j = i + 1, #bodies do
         local b = bodies[j]
         if a:is_dynamic() or b:is_dynamic() then
            if self:aabb_overlap(a, b) then
               local contact = collide.collide(a, b)
               if contact then
                  contacts[#contacts + 1] = contact
               end
            end
         end
      end
   end
   return contacts
end

local function boxes_overlap(a, b)
   return a.max_x >= b.min_x and a.min_x <= b.max_x and a.max_y >= b.min_y and a.min_y <= b.max_y
end

function World:aabb_overlap(a, b)
   return boxes_overlap(a:get_aabb(), b:get_aabb())
end

return World
