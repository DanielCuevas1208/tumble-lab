-- Tumble Lab headless snapshot tool.
--
-- Renders a scenario to a binary PPM image without a window. The
-- output uses the same camera transform and palette as the LOVE
-- sandbox, so the two views agree pixel for pixel on identical input.
--
-- Usage:
--   lua tools/snapshot.lua <scenario> <out.ppm> [options]
--
-- Options:
--   --steps N    Steps before capture (default 180)
--   --dt S       Fixed timestep in seconds (default 1/60)
--   --seed N     Seed for seeded scenarios
--
-- Convert the result to PNG with a tool such as ffmpeg:
--   ffmpeg -y -i out.ppm out.png

package.path = "./?.lua;./?/init.lua;" .. package.path

local scenarios = require("scenarios")

local WIDTH = 960
local HEIGHT = 720
local PPM = 40

local COLOR_BACKGROUND = { 18, 20, 31 }
local COLOR_GRID = { 33, 38, 54 }
local COLOR_STATIC = { 133, 140, 153 }
local COLOR_DYNAMIC = { 242, 161, 48 }
local COLOR_CONTACT = { 89, 235, 235 }
local COLOR_ACCENT = { 191, 217, 242 }

local function world_to_screen(wx, wy)
   return WIDTH * 0.5 + wx * PPM, HEIGHT * 0.5 - wy * PPM
end

local function screen_to_world(sx, sy)
   local x = (sx - WIDTH * 0.5 + 0.5) / PPM
   local y = (HEIGHT * 0.5 - sy - 0.5) / PPM
   return x, y
end

local function inside_circle(body, x, y)
   local dx = x - body.position.x
   local dy = y - body.position.y
   return dx * dx + dy * dy <= body.shape.radius * body.shape.radius
end

local function inside_polygon(body, x, y)
   local vertices = body:world_vertices()
   local count = #vertices
   for i = 1, count do
      local v0 = vertices[i]
      local v1 = vertices[i % count + 1]
      local ex = v1.x - v0.x
      local ey = v1.y - v0.y
      local px = x - v0.x
      local py = y - v0.y
      if ex * py - ey * px < 0 then
         return false
      end
   end
   return true
end

local function inside_body(body, x, y)
   local aabb = body:get_aabb()
   if x < aabb.min_x or x > aabb.max_x or y < aabb.min_y or y > aabb.max_y then
      return false
   end
   if body.shape.type == "circle" then
      return inside_circle(body, x, y)
   end
   return inside_polygon(body, x, y)
end

local function nearest_axis(value)
   return math.abs(value - math.floor(value + 0.5)) <= 0.5 / PPM
end

local function pixel_color(world, contacts, sx, sy, wx, wy)
   local color = COLOR_BACKGROUND
   if nearest_axis(wx) or nearest_axis(wy) then
      color = COLOR_GRID
   end
   if math.abs(wy) <= 0.5 / PPM then
      color = COLOR_ACCENT
   end

   local static_hit = false
   local dynamic_hit = false
   for _, body in ipairs(world.bodies) do
      if inside_body(body, wx, wy) then
         if body:is_dynamic() then
            dynamic_hit = true
            break
         else
            static_hit = true
         end
      end
   end
   if dynamic_hit then
      color = COLOR_DYNAMIC
   elseif static_hit then
      color = COLOR_STATIC
   end

   for _, contact in ipairs(contacts) do
      for _, point in ipairs(contact.points) do
         local px, py = world_to_screen(point.x, point.y)
         if (sx - px) * (sx - px) + (sy - py) * (sy - py) <= 9 then
            color = COLOR_CONTACT
            break
         end
      end
   end
   return color
end

local function render(world, contacts)
   local rows = {}
   for sy = 0, HEIGHT - 1 do
      local row = {}
      for sx = 0, WIDTH - 1 do
         local wx, wy = screen_to_world(sx, sy)
         local color = pixel_color(world, contacts, sx, sy, wx, wy)
         row[#row + 1] = string.char(color[1], color[2], color[3])
      end
      rows[#rows + 1] = table.concat(row)
   end
   return table.concat(rows)
end

local function write_ppm(path, data)
   local file = assert(io.open(path, "wb"))
   file:write(string.format("P6\n%d %d\n255\n", WIDTH, HEIGHT))
   file:write(data)
   file:close()
end

local function parse_args(argv)
   local opts = { steps = 180, dt = 1 / 60 }
   local positional = {}
   local i = 1
   while i <= #argv do
      local arg = argv[i]
      if arg == "--steps" then
         opts.steps = tonumber(argv[i + 1])
         i = i + 2
      elseif arg == "--dt" then
         opts.dt = tonumber(argv[i + 1])
         i = i + 2
      elseif arg == "--seed" then
         opts.seed = tonumber(argv[i + 1])
         i = i + 2
      else
         positional[#positional + 1] = arg
         i = i + 1
      end
   end
   opts.scenario_name = positional[1]
   opts.output = positional[2]
   return opts
end

local opts = parse_args(arg)
if not opts.scenario_name or not opts.output then
   io.stderr:write("usage: lua tools/snapshot.lua <scenario> <out.ppm> [--steps N]\n")
   os.exit(2)
end

local builder = scenarios[opts.scenario_name]
if not builder then
   io.stderr:write("unknown scenario: " .. opts.scenario_name .. "\n")
   os.exit(2)
end

local world = builder({ seed = opts.seed })
for _ = 1, opts.steps do
   world:step(opts.dt)
end
local contacts = world:detect_contacts()
write_ppm(opts.output, render(world, contacts))

print(
   string.format(
      "wrote %s | %dx%d | steps %d | dt %s | bodies %d | contacts %d",
      opts.output,
      WIDTH,
      HEIGHT,
      opts.steps,
      opts.dt,
      #world.bodies,
      #contacts
   )
)
