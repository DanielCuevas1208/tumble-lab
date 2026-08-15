-- Uniform-grid broadphase for collision pair generation.
-- Each body occupies every grid cell its AABB overlaps.
-- Pair order follows body insertion order to keep results deterministic.

local Broadphase = {}
Broadphase.__index = Broadphase

function Broadphase.new(cell_size)
  return setmetatable({
    cell_size = cell_size or 1.0,
    cells = {},
  }, Broadphase)
end

function Broadphase:clear()
  self.cells = {}
end

local function cell_key(cx, cy)
  return cx .. ":" .. cy
end

function Broadphase:cell_range(aabb)
  local size = self.cell_size
  return math.floor(aabb.min_x / size), math.floor(aabb.max_x / size),
    math.floor(aabb.min_y / size), math.floor(aabb.max_y / size)
end

function Broadphase:insert(index, aabb)
  local min_cx, max_cx, min_cy, max_cy = self:cell_range(aabb)
  for cx = min_cx, max_cx do
    for cy = min_cy, max_cy do
      local key = cell_key(cx, cy)
      local cell = self.cells[key]
      if not cell then
        cell = {}
        self.cells[key] = cell
      end
      cell[#cell + 1] = index
    end
  end
end

function Broadphase:build(bodies)
  self:clear()
  for index, body in ipairs(bodies) do
    self:insert(index, body:get_aabb())
  end
end

-- Returns sorted candidate indices greater than the given body index.
function Broadphase:candidates(index, bodies)
  local body = bodies[index]
  local min_cx, max_cx, min_cy, max_cy = self:cell_range(body:get_aabb())
  local seen = {}
  local result = {}
  for cx = min_cx, max_cx do
    for cy = min_cy, max_cy do
      local cell = self.cells[cell_key(cx, cy)]
      if cell then
        for _, other_index in ipairs(cell) do
          if other_index > index and not seen[other_index] then
            seen[other_index] = true
            result[#result + 1] = other_index
          end
        end
      end
    end
  end
  table.sort(result)
  return result
end

-- Invokes callback(i, j) for every broadphase pair in deterministic order.
function Broadphase:for_pairs(bodies, callback)
  for i = 1, #bodies do
    local candidates = self:candidates(i, bodies)
    for _, j in ipairs(candidates) do
      callback(i, j)
    end
  end
end

return Broadphase
