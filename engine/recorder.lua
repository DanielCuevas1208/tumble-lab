-- Records a simulation and plays it back.
-- The recording stores the initial body definitions plus one transform
-- snapshot per step. The snapshot format uses full double precision, so
-- a replay reproduces the original run exactly.
--
-- File format (.tumble), one token per field, one record per line:
--   TUMBLE 1
--   dt <seconds>
--   gravity <x> <y>
--   bodies <count>
--   body <id> circle <radius> <density> <friction> <restitution> <kind>
--   body <id> polygon <count> <vx> <vy> ... <density> <friction> <restitution> <kind>
--   initial
--   state <id> <x> <y> <vx> <vy> <angle> <w>
--   frames <count>
--   frame <index>
--   state <id> <x> <y> <vx> <vy> <angle> <w>

local World = require("engine.world")
local shape = require("engine.shape")

local Recorder = {}
Recorder.__index = Recorder

local function fmt(number)
  return string.format("%.17g", number)
end

local function body_definition(body)
  local def = {
    id = body.id,
    shape_type = body.shape.type,
    density = body.density,
    friction = body.friction,
    restitution = body.restitution,
    kind = body.kind,
    x = body.position.x,
    y = body.position.y,
    vx = body.velocity.x,
    vy = body.velocity.y,
    angle = body.angle,
    w = body.angular_velocity,
  }
  if body.shape.type == "circle" then
    def.radius = body.shape.radius
  else
    def.vertices = {}
    for i, v in ipairs(body.shape.vertices) do
      def.vertices[i] = { x = v.x, y = v.y }
    end
  end
  return def
end

function Recorder.new(world)
  local self = setmetatable({}, Recorder)
  self.world = world
  self.dt = 1 / 60
  self.initial = nil
  self.frames = {}
  self.recording = false
  return self
end

-- Captures the initial state and clears any previous frames.
function Recorder:start()
  self.initial = {}
  for _, body in ipairs(self.world.bodies) do
    self.initial[#self.initial + 1] = body_definition(body)
  end
  self.frames = {}
  self.recording = true
  self:capture_frame()
end

function Recorder:stop()
  self.recording = false
end

-- Captures one transform snapshot for every body.
function Recorder:capture_frame()
  local frame = {}
  for _, body in ipairs(self.world.bodies) do
    frame[#frame + 1] = {
      id = body.id,
      x = body.position.x,
      y = body.position.y,
      vx = body.velocity.x,
      vy = body.velocity.y,
      angle = body.angle,
      w = body.angular_velocity,
    }
  end
  self.frames[#self.frames + 1] = frame
end

-- Convenience hook for world:set_on_step.
function Recorder:tick()
  if self.recording then
    self:capture_frame()
  end
end

function Recorder:serialize()
  local lines = {
    "TUMBLE 1",
    string.format("dt %s", fmt(self.dt)),
    string.format("gravity %s %s", fmt(self.world.gravity.x), fmt(self.world.gravity.y)),
    string.format("bodies %d", #self.initial),
  }
  for _, def in ipairs(self.initial) do
    local kind = def.kind == "static" and "static" or "dynamic"
    if def.shape_type == "circle" then
      lines[#lines + 1] = string.format(
        "body %d circle %s %s %s %s %s",
        def.id, fmt(def.radius), fmt(def.density), fmt(def.friction), fmt(def.restitution), kind
      )
    else
      local parts = { string.format("body %d polygon %d", def.id, #def.vertices) }
      for _, v in ipairs(def.vertices) do
        parts[#parts + 1] = string.format("%s %s", fmt(v.x), fmt(v.y))
      end
      parts[#parts + 1] = string.format(
        "%s %s %s %s", fmt(def.density), fmt(def.friction), fmt(def.restitution), kind
      )
      lines[#lines + 1] = table.concat(parts, " ")
    end
  end
  lines[#lines + 1] = "initial"
  for _, def in ipairs(self.initial) do
    lines[#lines + 1] = string.format(
      "state %d %s %s %s %s %s %s",
      def.id, fmt(def.x), fmt(def.y), fmt(def.vx), fmt(def.vy), fmt(def.angle), fmt(def.w)
    )
  end
  lines[#lines + 1] = string.format("frames %d", #self.frames)
  for i, frame in ipairs(self.frames) do
    lines[#lines + 1] = string.format("frame %d", i - 1)
    for _, state in ipairs(frame) do
      lines[#lines + 1] = string.format(
        "state %d %s %s %s %s %s %s",
        state.id, fmt(state.x), fmt(state.y), fmt(state.vx), fmt(state.vy), fmt(state.angle), fmt(state.w)
      )
    end
  end
  return table.concat(lines, "\n") .. "\n"
end

local function split_fields(line)
  local fields = {}
  for token in line:gmatch("%S+") do
    fields[#fields + 1] = token
  end
  return fields
end

function Recorder.deserialize(text)
  local recording = {
    dt = 1 / 60,
    gravity = { x = 0, y = 9.81 },
    initial = {},
    frames = {},
  }
  local mode = "header"
  local current_frame = nil
  for line in text:gmatch("[^\r\n]+") do
    local fields = split_fields(line)
    if fields[1] == "dt" then
      recording.dt = tonumber(fields[2])
    elseif fields[1] == "gravity" then
      recording.gravity = { x = tonumber(fields[2]), y = tonumber(fields[3]) }
    elseif fields[1] == "body" then
      local def = { id = tonumber(fields[2]), shape_type = fields[3] }
      if def.shape_type == "circle" then
        def.radius = tonumber(fields[4])
        def.density = tonumber(fields[5])
        def.friction = tonumber(fields[6])
        def.restitution = tonumber(fields[7])
        def.kind = fields[8]
      else
        local count = tonumber(fields[4])
        def.vertices = {}
        local index = 5
        for _ = 1, count do
          def.vertices[#def.vertices + 1] = { x = tonumber(fields[index]), y = tonumber(fields[index + 1]) }
          index = index + 2
        end
        def.density = tonumber(fields[index])
        def.friction = tonumber(fields[index + 1])
        def.restitution = tonumber(fields[index + 2])
        def.kind = fields[index + 3]
      end
      recording.initial[#recording.initial + 1] = def
    elseif fields[1] == "initial" then
      mode = "initial"
    elseif fields[1] == "state" then
      local state = {
        id = tonumber(fields[2]),
        x = tonumber(fields[3]),
        y = tonumber(fields[4]),
        vx = tonumber(fields[5]),
        vy = tonumber(fields[6]),
        angle = tonumber(fields[7]),
        w = tonumber(fields[8]),
      }
      if mode == "initial" then
        for _, def in ipairs(recording.initial) do
          if def.id == state.id then
            def.x, def.y = state.x, state.y
            def.vx, def.vy = state.vx, state.vy
            def.angle, def.w = state.angle, state.w
          end
        end
      elseif mode == "frames" and current_frame then
        current_frame[#current_frame + 1] = state
      end
    elseif fields[1] == "frames" then
      mode = "frames"
      local count = tonumber(fields[2])
      for _ = 1, count do
        recording.frames[#recording.frames + 1] = {}
      end
    elseif fields[1] == "frame" then
      if mode == "frames" then
        current_frame = recording.frames[tonumber(fields[2]) + 1]
      end
    end
  end
  return recording
end

-- Builds a fresh world from a recorded body list.
function Recorder.rebuild_world(recording)
  local world = World.new(recording.gravity.x, recording.gravity.y)
  for _, def in ipairs(recording.initial) do
    local body_shape
    if def.shape_type == "circle" then
      body_shape = shape.circle(def.radius)
    else
      body_shape = shape.polygon(def.vertices)
    end
    world:add_body({
      shape = body_shape,
      kind = def.kind,
      density = def.density,
      friction = def.friction,
      restitution = def.restitution,
      position = { x = def.x, y = def.y },
      angle = def.angle,
      velocity = { x = def.vx, y = def.vy },
      angular_velocity = def.w,
    })
  end
  return world
end

-- Compares two frame lists. A tolerance of 0 requires exact equality.
local transform_fields = { "x", "y", "vx", "vy", "angle", "w" }

function Recorder.frames_match(a, b, tolerance)
  tolerance = tolerance or 0
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    local fa, fb = a[i], b[i]
    if #fa ~= #fb then
      return false
    end
    for k = 1, #fa do
      local sa, sb = fa[k], fb[k]
      if sa.id ~= sb.id then
        return false
      end
      for _, field in ipairs(transform_fields) do
        local difference = math.abs(sa[field] - sb[field])
        if tolerance == 0 then
          if sa[field] ~= sb[field] then
            return false
          end
        elseif difference > tolerance then
          return false
        end
      end
    end
  end
  return true
end

return Recorder
