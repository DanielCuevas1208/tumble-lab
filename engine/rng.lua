-- Deterministic pseudorandom generator, Park-Miller LCG.
-- Uses 31-bit integer arithmetic only. Every value is exact in an
-- IEEE-754 double, so the same seed gives the same sequence on every
-- platform and interpreter. This keeps simulations reproducible.

local rng = {}
rng.__index = rng

local MODULUS = 2147483647
local MULTIPLIER = 48271

function rng.new(seed)
  local self = setmetatable({}, rng)
  self:seed(seed or 1)
  return self
end

function rng:seed(seed)
  self.state = seed % MODULUS
  if self.state == 0 then
    self.state = 1
  end
  return self
end

function rng:next_int()
  self.state = (self.state * MULTIPLIER) % MODULUS
  return self.state
end

-- Returns a float in the half-open interval [0, 1).
function rng:float()
  return self:next_int() / MODULUS
end

-- Returns a float in the interval [low, high).
function rng:range(low, high)
  return low + (high - low) * self:float()
end

-- Returns an integer in the closed interval [low, high].
function rng:integer(low, high)
  return math.floor(self:range(low, high + 1))
end

return rng
