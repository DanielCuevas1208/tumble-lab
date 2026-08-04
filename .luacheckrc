std = "lua51"
max_line_length = 110
max_code_line_length = 110
unused_args = false

-- Never lint downloaded dependencies or build output.
exclude_files = {
  ".luarocks/",
  "luarocks/",
  "build/",
  "dist/",
  "out/",
}

files = {
  ["spec/*.lua"] = { std = "lua51", globals = { "describe", "it" } },
  ["scenarios/*.lua"] = { std = "luajit" },
  ["main.lua"] = { std = "luajit", globals = { "love" } },
  ["conf.lua"] = { std = "luajit", globals = { "love" } },
}
