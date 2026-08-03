-- Interactive sandbox scenes for the LOVE framework.
--
-- A Scene owns one live world, a fixed timestep loop, and the camera
-- transform between world meters and screen pixels. Scenes reuse the
-- shared scenario builders, so the sandbox and the headless runner run
-- the same engine code.

local scenarios = require("scenarios")
local shape = require("engine.shape")

local Scene = {}
Scene.__index = Scene

local PPM = 40
local STEP_DT = 1 / 60
local MAX_FRAME_TIME = 0.25

local COLORS = {
   background = { 0.07, 0.08, 0.12 },
   grid = { 0.13, 0.15, 0.21 },
   static = { 0.52, 0.55, 0.60 },
   dynamic = { 0.95, 0.63, 0.19 },
   contact = { 0.35, 0.92, 0.92 },
   text = { 0.92, 0.93, 0.95 },
   accent = { 0.75, 0.85, 0.95 },
}

local function collect_scene_names()
   local names = {}
   for name in pairs(scenarios) do
      if type(scenarios[name]) == "function" then
         names[#names + 1] = name
      end
   end
   table.sort(names)
   return names
end

local NAMES = collect_scene_names()

function Scene.new(name)
   local self = setmetatable({}, Scene)
   self.name = name
   self.ppm = PPM
   self.paused = false
   self.accumulator = 0
   self:reset()
   return self
end

-- Rebuilds the world from the scenario builder.
function Scene:reset()
   self.world = scenarios[self.name]()
   self.accumulator = 0
end

-- Advances the simulation with a fixed timestep. Physics stays
-- independent of the display frame rate. A paused scene drains the
-- accumulator so unpausing does not cause a sudden jump.
function Scene:update(dt)
   dt = math.min(dt, MAX_FRAME_TIME)
   self.accumulator = self.accumulator + dt
   while self.accumulator >= STEP_DT do
      if not self.paused then
         self.world:step(STEP_DT)
      end
      self.accumulator = self.accumulator - STEP_DT
   end
end

-- Advances the world by exactly one step, even while paused.
function Scene:step_once()
   self.world:step(STEP_DT)
end

-- Camera: world y grows downward, screen y grows downward. The world
-- origin sits at the center of the window.
local function world_to_screen(self, x, y)
   local width, height = love.graphics.getDimensions()
   return width * 0.5 + x * self.ppm, height * 0.5 - y * self.ppm
end

local function screen_to_world(self, sx, sy)
   local width, height = love.graphics.getDimensions()
   local x = (sx - width * 0.5) / self.ppm
   local y = (height * 0.5 - sy) / self.ppm
   return x, y
end

local function draw_grid(self)
   local width, height = love.graphics.getDimensions()
   local half_w = math.ceil(width / self.ppm * 0.5) + 1
   local half_h = math.ceil(height / self.ppm * 0.5) + 1
   love.graphics.setColor(COLORS.grid)
   for y = -half_h, half_h do
      local _, sy = world_to_screen(self, 0, y)
      love.graphics.line(0, sy, width, sy)
   end
   for x = -half_w, half_w do
      local sx, _ = world_to_screen(self, x, 0)
      love.graphics.line(sx, 0, sx, height)
   end
   love.graphics.setColor(COLORS.accent)
   local _, ground_y = world_to_screen(self, 0, 0)
   love.graphics.line(0, ground_y, width, ground_y)
end

local function draw_body(self, body)
   local center_x, center_y = world_to_screen(self, body.position.x, body.position.y)
   if body.shape.type == "circle" then
      love.graphics.circle("fill", center_x, center_y, body.shape.radius * self.ppm, 32)
      return
   end
   local points = {}
   for _, vertex in ipairs(body:world_vertices()) do
      local px, py = world_to_screen(self, vertex.x, vertex.y)
      points[#points + 1] = px
      points[#points + 1] = py
   end
   love.graphics.polygon("fill", points)
end

local function draw_contacts(self)
   local contacts = self.world:detect_contacts()
   love.graphics.setColor(COLORS.contact)
   for _, contact in ipairs(contacts) do
      for _, point in ipairs(contact.points) do
         local px, py = world_to_screen(self, point.x, point.y)
         love.graphics.circle("fill", px, py, 4, 12)
      end
   end
end

local function draw_hud(self)
   local width, height = love.graphics.getDimensions()
   love.graphics.setColor(COLORS.text)
   love.graphics.print("Tumble Lab", 16, 16)
   love.graphics.print("scene: " .. self.name, 16, 40)
   love.graphics.print(
      string.format("bodies: %d   contacts: %d", #self.world.bodies, self.world.stats.contact_count),
      16,
      64
   )
   love.graphics.print(
      string.format(
         "steps: %d   time: %.2f s",
         self.world.step_count,
         self.world.step_count * STEP_DT
      ),
      16,
      88
   )

   love.graphics.print(string.format("fps: %.0f", love.timer.getFPS()), width - 120, 16)
   if self.paused then
      love.graphics.setColor(COLORS.accent)
      love.graphics.print("paused", width - 120, 40)
   end

   love.graphics.setColor(COLORS.text)
   love.graphics.print("1-4 scene  space pause  s step  r reset  click drop", 16, height - 28)
end

function Scene:draw()
   love.graphics.clear(COLORS.background)
   draw_grid(self)

   love.graphics.setColor(COLORS.static)
   for _, body in ipairs(self.world.bodies) do
      if not body:is_dynamic() then
         draw_body(self, body)
      end
   end

   love.graphics.setColor(COLORS.dynamic)
   for _, body in ipairs(self.world.bodies) do
      if body:is_dynamic() then
         draw_body(self, body)
      end
   end

   draw_contacts(self)
   draw_hud(self)
end

-- Drops a random body at a world position. The sandbox is interactive,
-- so the shape and motion use LOVE's nondeterministic generator.
function Scene:mousepressed(sx, sy)
   local world_x, world_y = screen_to_world(self, sx, sy)
   local radius = love.math.random(8, 18) / 40
   local body_shape
   if love.math.random() < 0.5 then
      body_shape = shape.circle(radius)
   else
      body_shape = shape.box(radius, radius)
   end
   self.world:add_body({
      shape = body_shape,
      position = { x = world_x, y = world_y },
      angle = love.math.random() * math.pi * 2,
      velocity = { x = love.math.random(-2, 2) * 0.5, y = love.math.random(-2, 0) },
      angular_velocity = love.math.random(-3, 3),
      friction = 0.5,
   })
end

Scene.names = NAMES

return Scene
