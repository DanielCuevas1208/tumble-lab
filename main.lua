-- Tumble Lab interactive sandbox.
-- The sandbox uses the same scenario builders and fixed-step world as the CLI.

local config = require("engine.config")
local version = require("engine.version")
local scenarios = require("scenarios")

local FIXED_DT = 1 / 60
local SIDEBAR_WIDTH = 286
local WORLD_SCALE = 32
local WORLD_ORIGIN_Y = 430

local colors = {
  background = { 0.035, 0.047, 0.071 },
  canvas = { 0.055, 0.071, 0.102 },
  sidebar = { 0.078, 0.098, 0.133 },
  panel = { 0.102, 0.125, 0.165 },
  panel_highlight = { 0.145, 0.184, 0.235 },
  text = { 0.89, 0.93, 0.97 },
  muted = { 0.53, 0.61, 0.70 },
  grid = { 0.11, 0.14, 0.19 },
  axis = { 0.26, 0.34, 0.43 },
  ground = { 0.32, 0.38, 0.48 },
  contact = { 0.98, 0.49, 0.30 },
  velocity = { 0.39, 0.82, 0.93 },
  accent = { 0.35, 0.74, 0.91 },
  green = { 0.39, 0.84, 0.57 },
  orange = { 0.95, 0.60, 0.34 },
}

local body_colors = {
  { 0.37, 0.66, 0.91 },
  { 0.53, 0.77, 0.95 },
  { 0.65, 0.68, 0.94 },
  { 0.72, 0.57, 0.89 },
  { 0.95, 0.60, 0.50 },
  { 0.95, 0.72, 0.43 },
}

local scene_specs = {
  {
    key = "stack",
    label = "Stack",
    summary = "Boxes settle under gravity.",
    build = scenarios.stack,
  },
  { key = "drop", label = "Drop", summary = "A circle tests restitution.", build = scenarios.drop },
  {
    key = "throw",
    label = "Throw",
    summary = "A free-flight trajectory stays analytic.",
    build = scenarios.throw,
  },
  {
    key = "heap",
    label = "Heap",
    summary = "Seeded bodies show mixed contacts.",
    build = scenarios.heap,
  },
}

local app = {
  scene_index = 1,
  seed = 42,
  paused = false,
  time_scale = 1,
  accumulator = 0,
  simulated_time = 0,
  world = nil,
}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

local function set_color(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
end

local function scene()
  return scene_specs[app.scene_index]
end

local function reset_scene()
  local selected = scene()
  app.world = selected.build({ seed = app.seed })
  app.accumulator = 0
  app.simulated_time = 0
  app.paused = false
end

local function next_scene(direction)
  app.scene_index = (app.scene_index - 1 + direction) % #scene_specs + 1
  reset_scene()
end

local function step_once()
  app.world:step(FIXED_DT)
  app.simulated_time = app.simulated_time + FIXED_DT
end

local function update_simulation(frame_dt)
  if app.paused then
    return
  end
  app.accumulator = app.accumulator + math.min(frame_dt, 0.25) * app.time_scale
  local steps = 0
  while app.accumulator >= FIXED_DT and steps < config.max_substeps do
    step_once()
    app.accumulator = app.accumulator - FIXED_DT
    steps = steps + 1
  end
  if steps == config.max_substeps and app.accumulator >= FIXED_DT then
    app.accumulator = 0
  end
end

local function screen_position(x, y)
  local width = love.graphics.getWidth()
  local canvas_width = width - SIDEBAR_WIDTH
  return SIDEBAR_WIDTH + canvas_width * 0.52 + x * WORLD_SCALE, WORLD_ORIGIN_Y + y * WORLD_SCALE
end

local function draw_grid()
  local width, height = love.graphics.getWidth(), love.graphics.getHeight()
  local left = SIDEBAR_WIDTH
  set_color(colors.canvas)
  love.graphics.rectangle("fill", left, 0, width - left, height)
  love.graphics.setLineWidth(1)
  set_color(colors.grid)
  for x = -20, 20 do
    local sx = screen_position(x, 0)
    love.graphics.line(sx, 0, sx, height)
  end
  for y = -12, 10 do
    local _, sy = screen_position(0, y)
    love.graphics.line(left, sy, width, sy)
  end
  set_color(colors.axis)
  local axis_x = screen_position(0, 0)
  local _, axis_y = screen_position(0, 0)
  love.graphics.line(axis_x, 0, axis_x, height)
  love.graphics.line(left, axis_y, width, axis_y)
end

local function draw_body(body)
  local sx, sy = screen_position(body.position.x, body.position.y)
  local fill = body.kind == "static" and colors.ground
    or body_colors[(body.id - 1) % #body_colors + 1]
  set_color(fill)
  if body.shape.type == "circle" then
    love.graphics.circle("fill", sx, sy, body.shape.radius * WORLD_SCALE)
    set_color(colors.text)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", sx, sy, body.shape.radius * WORLD_SCALE)
  else
    local points = {}
    for _, vertex in ipairs(body:world_vertices()) do
      local vx, vy = screen_position(vertex.x, vertex.y)
      points[#points + 1] = vx
      points[#points + 1] = vy
    end
    love.graphics.polygon("fill", points)
    set_color(colors.text)
    love.graphics.setLineWidth(1.5)
    love.graphics.polygon("line", points)
  end

  if body:is_dynamic() then
    set_color(colors.velocity, 0.78)
    love.graphics.setLineWidth(2)
    local velocity_x = sx + body.velocity.x * 0.08 * WORLD_SCALE
    local velocity_y = sy + body.velocity.y * 0.08 * WORLD_SCALE
    love.graphics.line(sx, sy, velocity_x, velocity_y)
    set_color(colors.text)
    love.graphics.circle("fill", sx, sy, 2.5)
  end
end

local function draw_contacts()
  local contacts = app.world:detect_contacts()
  set_color(colors.contact)
  for _, contact in ipairs(contacts) do
    for _, point in ipairs(contact.points) do
      local x, y = screen_position(point.x, point.y)
      love.graphics.circle("fill", x, y, 4)
    end
  end
end

local function draw_world()
  draw_grid()
  for _, body in ipairs(app.world.bodies) do
    draw_body(body)
  end
  draw_contacts()
end

local function print_text(text, x, y, color)
  set_color(color or colors.text)
  love.graphics.print(text, x, y)
end

local function draw_sidebar()
  local _, height = love.graphics.getWidth(), love.graphics.getHeight()
  set_color(colors.sidebar)
  love.graphics.rectangle("fill", 0, 0, SIDEBAR_WIDTH, height)
  set_color(colors.panel_highlight)
  love.graphics.rectangle("fill", 0, 0, 5, height)

  print_text("TUMBLE LAB", 28, 26, colors.accent)
  print_text("2D RIGID-BODY SANDBOX", 28, 54, colors.text)
  print_text("v" .. version.version, 28, 77, colors.muted)

  print_text("SCENES", 28, 120, colors.muted)
  for index, item in ipairs(scene_specs) do
    local y = 148 + (index - 1) * 55
    if index == app.scene_index then
      set_color(colors.panel_highlight)
      love.graphics.rectangle("fill", 20, y - 8, SIDEBAR_WIDTH - 40, 43, 6, 6)
      print_text(string.format("%d", index), 31, y + 4, colors.accent)
      print_text(item.label, 57, y, colors.text)
      print_text(item.summary, 57, y + 19, colors.muted)
    else
      print_text(string.format("%d", index), 31, y + 4, colors.muted)
      print_text(item.label, 57, y, colors.muted)
    end
  end

  local status_y = 390
  print_text("SIMULATION", 28, status_y, colors.muted)
  local status = app.paused and "PAUSED" or "RUNNING"
  local status_color = app.paused and colors.orange or colors.green
  print_text(status, 28, status_y + 25, status_color)
  print_text(
    string.format("time       %06.2f s", app.simulated_time),
    28,
    status_y + 52,
    colors.text
  )
  print_text(string.format("steps      %06d", app.world.step_count), 28, status_y + 72, colors.text)
  print_text(string.format("bodies     %06d", #app.world.bodies), 28, status_y + 92, colors.text)
  print_text(
    string.format("contacts   %06d", app.world.stats.contact_count),
    28,
    status_y + 112,
    colors.text
  )
  print_text(string.format("time scale %0.2fx", app.time_scale), 28, status_y + 132, colors.text)

  set_color(colors.panel)
  love.graphics.rectangle("fill", 20, height - 130, SIDEBAR_WIDTH - 40, 104, 6, 6)
  print_text("CONTROLS", 32, height - 116, colors.muted)
  print_text("1-4  select scene", 32, height - 94, colors.text)
  print_text("R    reset    Space  pause", 32, height - 74, colors.text)
  print_text("N    step     +/-    time scale", 32, height - 54, colors.text)
  print_text("[ ]  previous or next scene", 32, height - 34, colors.text)
end

local function draw_canvas_labels()
  local width, height = love.graphics.getWidth(), love.graphics.getHeight()
  print_text(string.upper(scene().label), SIDEBAR_WIDTH + 28, 24, colors.text)
  print_text(scene().summary, SIDEBAR_WIDTH + 28, 48, colors.muted)
  print_text("contact points", width - 140, 24, colors.contact)
  print_text("velocity", width - 140, 48, colors.velocity)
  set_color(colors.panel)
  love.graphics.rectangle(
    "fill",
    SIDEBAR_WIDTH + 20,
    height - 46,
    width - SIDEBAR_WIDTH - 40,
    26,
    5,
    5
  )
  print_text(
    "Same fixed-step engine as the headless runner",
    SIDEBAR_WIDTH + 32,
    height - 40,
    colors.muted
  )
end

function love.load()
  love.graphics.setBackgroundColor(colors.background)
  love.graphics.setDefaultFilter("nearest", "nearest")
  app.font = love.graphics.newFont(14)
  app.heading_font = love.graphics.newFont(20)
  love.graphics.setFont(app.font)
  reset_scene()
end

function love.update(dt)
  update_simulation(dt)
end

function love.draw()
  love.graphics.setFont(app.font)
  draw_world()
  draw_sidebar()
  draw_canvas_labels()
end

function love.keypressed(key)
  local selected = tonumber(key)
  if selected and selected >= 1 and selected <= #scene_specs then
    app.scene_index = selected
    reset_scene()
  elseif key == "r" then
    reset_scene()
  elseif key == "space" then
    app.paused = not app.paused
  elseif key == "n" then
    step_once()
  elseif key == "[" then
    next_scene(-1)
  elseif key == "]" then
    next_scene(1)
  elseif key == "-" then
    app.time_scale = clamp(app.time_scale - 0.25, 0.25, 4)
  elseif key == "+" or key == "=" then
    app.time_scale = clamp(app.time_scale + 0.25, 0.25, 4)
  end
end
