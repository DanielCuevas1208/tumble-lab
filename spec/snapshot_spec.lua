local function run_cli(args)
   local handle = io.popen("lua tools/snapshot.lua " .. args .. " 2>&1", "r")
   local output = handle:read("*a")
   handle:close()
   return output
end

local function read_ppm(path)
   local file = assert(io.open(path, "rb"))
   local content = file:read("*a")
   file:close()
   local magic, width, height, maxval = content:match("(P6)%s+(%d+)%s+(%d+)%s+(%d+)%s+")
   local header_len = #magic + #width + #height + #maxval + 4
   return content, tonumber(width), tonumber(height), header_len + 1
end

local function pixel(content, offset, width, sx, sy)
   local i = offset + (sy * width + sx) * 3
   return content:byte(i), content:byte(i + 1), content:byte(i + 2)
end

describe("headless snapshot", function()
   it("renders a scenario to a well-formed PPM", function()
      local path = os.tmpname()
      local output = run_cli("stack " .. path .. " --steps 120")
      assert.is_not_nil(output:find("wrote"))
      local content, width, height, offset = read_ppm(path)
      assert.are.equal(960, width)
      assert.are.equal(720, height)
      assert.are.equal(15 + 960 * 720 * 3, #content)
      assert.are.equal(16, offset)
      os.remove(path)
   end)

   it("fills bodies, ground, and sky with the sandbox palette", function()
      local path = os.tmpname()
      run_cli("stack " .. path .. " --steps 120")
      local content, _, _, offset = read_ppm(path)

      local function screen_px(wx, wy)
         local sx = math.floor(480 + wx * 40)
         local sy = math.floor(360 - wy * 40)
         return pixel(content, offset, 960, sx, sy)
      end

      assert.same({ 242, 161, 48 }, { screen_px(0, -0.3) })
      assert.same({ 133, 140, 153 }, { screen_px(0, 0.05) })
      assert.same({ 18, 20, 31 }, { screen_px(-6, -3) })
      os.remove(path)
   end)

   it("rejects an unknown scenario", function()
      local output = run_cli("missing out.ppm")
      assert.is_not_nil(output:find("unknown scenario"))
   end)
end)
