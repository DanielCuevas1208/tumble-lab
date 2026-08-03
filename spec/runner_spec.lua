local function run_cli(args)
   local handle = io.popen("lua tools/run.lua " .. args .. " 2>&1", "r")
   local output = handle:read("*a")
   handle:close()
   return output
end

local function write_tmp(content)
   local path = os.tmpname()
   local file = assert(io.open(path, "wb"))
   file:write(content)
   file:close()
   return path
end

describe("headless runner", function()
   it("runs a scenario to completion", function()
      local output = run_cli("stack --steps 20 --quiet")
      assert.are.equal("", output)
   end)

   it("reports an unknown scenario", function()
      local output = run_cli("missing --quiet")
      assert.is_not_nil(output:find("unknown scenario"))
      assert.is_not_nil(output:find("available:"))
   end)

   it("verifies a record and replay cycle is identical", function()
      local path = write_tmp("")
      run_cli("heap --steps 200 --seed 11 --record " .. path .. " --quiet")
      local output = run_cli("--replay " .. path)
      assert.is_not_nil(output:find("result: identical"))
      os.remove(path)
   end)

   it("reports a mismatch for a corrupted recording", function()
      local path = write_tmp(
         "TUMBLE 1\n"
            .. "dt 0.016666666666666666\n"
            .. "gravity 0 9.81\n"
            .. "bodies 1\n"
            .. "body 1 circle 0.2 1 0.3 0.5 dynamic\n"
            .. "initial\n"
            .. "state 1 0 -2 0 0 0 0\n"
            .. "frames 10\n"
            .. "frame 0\n"
            .. "state 1 0 -2 0 0 0 0\n"
      )
      local output = run_cli("--replay " .. path)
      assert.is_not_nil(output:find("result: mismatch"))
      os.remove(path)
   end)
end)
