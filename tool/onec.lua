#!/usr/bin/lua

-- @indent space 2
-- @syntax lua 5.3
-- @width 80

--[[------------------------------------------------------------------------ ]

  MIT License

  Copyright (c) 2021-2023 JulianDroid
  Copyright (c) 2025      JulianDroske

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

--[ ------------------------------------------------------------------------]]

--[[------------------------------------------------------------------------ ]

  Lua source code bundler for Lua

  + Version 1.7:
    - deprecate table.insert()
    - replace tabs with spaces
    - added -C option for relative filepaths
  + Version 1.6:
    - added -i option for adding custom inline module
  + Version 1.5:
    - remove -t(no_min) option - always no minlua
    - speed up compiling - process output data to table and conjunct it
  + Version 1.4:
    - speed up loading
  + Version 1.3:
    - more friendly error messages (line number and file name fixed)
    - bugfix: generate error when loading modules fails
  + Version 1.2:
    - support ES6-like /index.lua for directory modules
    - nested require
  + Version 1.1:
    - bug fix
    - author information
    - minify is optional
    - change custom global function require locally

--[ ------------------------------------------------------------------------]]

local os = require 'os'


--[[------------------------------------------------------------------------ ]

  UTILS

--[ ------------------------------------------------------------------------]]

local function split(str, sp)
  local arr = {}
  local arr_i = 1
  local left = 1
  local right = str:find(sp)
  while right do
    arr[arr_i] = str:sub(left, right-#sp)
    arr_i = arr_i + 1
    left = right + 1
    right = str:find(sp, left)
  end
  if #str - left > 0 then arr[arr_i] = str:sub(left, #str) end
  return arr
end

local function str2hexstr(str)
  local fmt = '\\x%02x'
  return str:gsub(".", function(c)return fmt:format(c:byte())end)
end

local function exec(cmd, IN)
  local fp, err = io.popen(cmd)
  if err then return nil, err end
  if IN then fp:write(IN) end
  fp:flush()
  local out = fp:read('*a')
  local exit_code = fp:close()
  return out, nil, exit_code
end

local function read_file(path)
  local fp, err = io.open(path, 'r')
  if err then return nil, err end
  local data = fp:read('*a')
  fp:close()
  return data
end

local function write_file(path, data)
  local fp, err = io.open(path, 'w')
  if err then
    print('error in write_file')
    return
  end
  fp:write(data)
  fp:close()
end

local os_type = nil
if package.config:sub(1, 1) == '\\' then os_type = 'windows'
else os_type = 'unix' end

local ls_cmd = {
  unix = 'ls ',
  windows = 'dir /D /B '
}
local function ls(dir)
  local files, err = exec(ls_cmd[os_type] .. dir)
  if err then
    print("error in ls")
    return nil, err
  end
  return split(files, '\n')
end

local function is_suffix(file, suf)
  return file:find(suf, #file - #suf, true) and true or false
end

local function is_file_lua(file)
  return is_suffix(file, '.lua')
end

local function is_dir(path)
  local fp, err = io.open(path)
  if err then
    print("error in is_dir")
    return nil, err
  end
  local stat = not fp:read(0) and fp:seek("end") ~= 0
  fp:close()
  return stat
end


--[[------------------------------------------------------------------------ ]

  MAIN

--[ ------------------------------------------------------------------------]]

local help_text = [[
Usage: onec [option..]|<src..>

[option]
  -o <output_file>              result file pathname
                                = bundled.lua
  -m <main_mod_name>            main module executed as entry
  -i <mod_name> <mod_content>   add an inline module
  -C <dir>                      cd to pathname before processing the rest of
                                files
                                = .

[src]
  source file to be bundled, either a .lua file
  or a folder containing .lua files

]]

local function min_lua(content)
  -- return content
    -- :gsub('%-%-%[%[.-%]%]', '')
    -- :gsub('%-%-.-\n', '')
    -- :gsub('[\t\n]+', ' ')
  -- (): shrink return value count to 1
  return (content
    :gsub('%-%-%[%[.-%]%]', '')
    :gsub('%-%-.-\n', '')
    :gsub('%s+', ' ')
    :gsub('([A-Za-z0-9_])%s([^A-Za-z0-9_])', '%1%2')
    :gsub('([^A-Za-z0-9_])%s([A-Za-z0-9_])', '%1%2')
    :gsub('(%p)%s(%p)', '%1%2'))
end

local lua_files = {}
local function dfs_fs(relative_path, context_path)
  context_path = context_path or '.'
  local path = context_path .. '/' .. relative_path

  if is_dir(path) then
    local files, err = ls(path)
    for k, subpath in pairs(files) do
      if subpath ~= '.' and subpath ~= '..' then
        dfs_fs(relative_path .. '/' .. subpath, context_path)
      end
    end
  elseif is_file_lua(path) then
    -- table.insert(lua_files, path)
    lua_files[#lua_files + 1] = {
      filepath = path,
      relative_path = relative_path,
    }
  end
end

local source = {}
local main_module_name = nil
local dest = 'bundled.lua'
local custom_modules = {}
local context_path = '.'
-- local no_min = true
-- load args
do
  local i=1
  while i <= #arg do
    local a = arg[i]
    if a == '-o' then
      i = i + 1
      dest = arg[i]
    elseif a == '-m' then
      i = i + 1
      main_module_name = arg[i]
    -- elseif a == '-t' then
      -- no_min = false
    elseif a == '-i' then
      i = i + 1
      custom_modules[arg[i]] = arg[i + 1]
      i = i + 1
    elseif a == '-C' then
      i = i + 1
      context_path = arg[i] or '.'
    else
      -- table.insert(source, arg[i])
      source[#source + 1] = {
        path = arg[i],
        context_path = context_path,
      }
    end
    i = i + 1
  end
end

function show_help()
  print(help_text)
end

if #source == 0 then
  show_help()
  os.exit(1)
end

for k, v in pairs(source) do
  dfs_fs(v.path, v.context_path)
end

local FILE_DATA = {
  '--[[ Bundled by ONECLUA written by Julian Droske ]]\n',
  min_lua([[
    local __pkg__ = {}
    __pkg__.compiled = {}
    __pkg__.funcs = {}
    local __require__ = _G.require
    local __require_patched__ = function(mod_name)
      -- version 1.2
      if not  __pkg__.funcs[mod_name] and __pkg__.funcs[mod_name .. '.index'] then
        mod_name = mod_name .. '.index'
      end
      if __pkg__.funcs[mod_name] then
        if not __pkg__.compiled[mod_name] then __pkg__.compiled[mod_name] = table.pack(__pkg__.funcs[mod_name]()) end
        return table.unpack(__pkg__.compiled[mod_name])
      else
        return __require__(mod_name)
      end
    end
    -- table.insert(package.searchers, 1, __require_patched__)
    local require = __require_patched__

    -- for submodules
    local __env__ = {
      require = require
    }
    setmetatable(__env__, {__index = _G})
  ]])
  -- ^ do not forget to export the `require` function
}

local function append_data(data)
  FILE_DATA[#FILE_DATA + 1] = data
end

-- if not no_min then FILE_DATA = FILE_DATA:gsub('[\t\n]+', ' ') end

function module_as_function(infoname, name, data)
  -- local f, err = load(data)
  -- if err then
    -- print(('error in package "%s": %s'):format(infoname, err))
    -- os.exit(1)
  -- end
  -- local binary_data = string.dump(f, true)
  return
    min_lua(([[
      __pkg__.funcs["%s"] = (function()
        local f, err = load("%s", "%s", "bt", __env__)
        if not f then error(err) end
        return f()
      end)
    ]]):format(name, str2hexstr(data), infoname))
end

for k, context in pairs(lua_files) do
  local filepath, relative_path = context.filepath, context.relative_path

  local mod_data, err = read_file(filepath)
  if err then
    print('Error: cannot read file ' .. filepath)
  else
    -- remove all prefix
    local mod_name = relative_path
      :gsub('^[./\\]+', '')
      :gsub('%.lua$', '')
      :gsub('[/\\]+', '.')
    local modded_file_name = '$/' .. mod_name:gsub('%.', '/') .. '.lua'
    -- if not no_min then mod_data = min_lua(mod_data) end
    append_data(module_as_function(modded_file_name, mod_name, mod_data))
  end
end

for k, v in pairs(custom_modules) do
  append_data(module_as_function('inline:' .. k, k, v))
end

if main_module_name then
  append_data(' __pkg__.funcs["' .. main_module_name .. '"]()')
end

-- if not no_min then FILE_DATA = min_lua(FILE_DATA) end

-- export `require`
append_data('\n' .. min_lua([[
  local _M = {require = __require_patched__} return _M
]]))

local final_file_data = table.concat(FILE_DATA)
write_file(dest, final_file_data)

