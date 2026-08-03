-- LOVE configuration for the Tumble Lab sandbox.

function love.conf(t)
   t.identity = "tumble-lab"
   t.version = "11.5"
   t.window.title = "Tumble Lab Sandbox"
   t.window.width = 960
   t.window.height = 720
   t.window.resizable = true
   t.window.vsync = 1
   t.window.msaa = 4
   t.modules.joystick = false
   t.modules.physics = false
   t.modules.touch = false
   t.modules.video = false
end
