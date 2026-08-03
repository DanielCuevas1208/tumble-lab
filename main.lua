-- Tumble Lab sandbox: LOVE entry point.
-- The sandbox loads one interactive scene at a time. Scenes come from
-- the shared scenarios module, so the sandbox and the headless runner
-- execute the same engine.
--
-- Automated captures use environment variables:
--   TUMBLE_STEPS=N      Step the world N times before the first frame.
--   TUMBLE_SHOT=file    Save one frame as a PNG, then quit.

local scenes = require("scenes")

local scene = nil
local shot_file = nil
local shot_steps = 0
local shot_taken = false

local function load_capture_options()
   shot_file = os.getenv("TUMBLE_SHOT")
   shot_steps = tonumber(os.getenv("TUMBLE_STEPS")) or 0
end

local function switch_to(index)
   local name = scenes.names[index]
   if name then
      scene = scenes.new(name)
   end
end

function love.load()
   load_capture_options()
   switch_to(1)
   for _ = 1, shot_steps do
      scene:step_once()
   end
end

function love.update(dt)
   if scene then
      scene:update(dt)
   end
end

function love.draw()
   if scene then
      scene:draw()
   end
   if shot_file and not shot_taken then
      shot_taken = true
      love.graphics.captureScreenshot(shot_file, function()
         love.event.quit()
      end)
   end
end

function love.keypressed(key)
   if not scene then
      return
   end
   if key == "space" then
      scene.paused = not scene.paused
   elseif key == "s" then
      scene:step_once()
   elseif key == "r" then
      scene:reset()
   elseif key == "escape" then
      love.event.quit()
   elseif key >= "1" and key <= "4" then
      switch_to(tonumber(key))
   end
end

function love.mousepressed(x, y, button)
   if scene and button == 1 then
      scene:mousepressed(x, y)
   end
end

function love.resize()
   -- The camera reads the current window size on every draw call.
end
