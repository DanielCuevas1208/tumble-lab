std = "lua51"
max_line_length = 110
max_code_line_length = 110
unused_args = false

files = {
  ["spec/*.lua"] = { std = "busted" },
  ["scenes/*.lua"] = { std = "luajit", globals = { "love" } },
  ["main.lua"] = { std = "luajit", globals = { "love" } },
  ["conf.lua"] = { std = "luajit", globals = { "love" } },
}
