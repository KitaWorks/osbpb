#!/usr/bin/lua

-- @indent tab
-- @syntax lua 5.1

--[[
	MIT License

	Copyright (c) 2021-2023 JulianDroid

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
]]

local io = require 'io'

local function safe_stringify(str)
	return str:gsub('[^%w_]', '_')
end

local function printerr(...)
	local args = {...}
	io.stderr:write(table.concat(args, '\t'))
	io.stderr:write('\n')
	io.stderr:flush()
end

local __last_name = nil
local __writable = false
local infiles = {}
local __infile_pipe_defined = false
local outfile = '-'

local function show_help()
	printerr('Usage: bin2c [-o <output_file>] ( [[-n <var_name>] [-w] <input_file>] ... )')
end

-- parse args
do
	local i = 1
	while i <= #arg do
		local a = arg[i]
		if a == '-h' then
			show_help()
			return 0
		elseif a == '-o' then
			i = i + 1
			outfile = arg[i]
		elseif a == '-w' then
			__writable = true
		elseif a == '-n' then
			i = i + 1
			__last_name = arg[i]
		else
			local path = arg[i]
			infiles[#infiles + 1] = {
				name = safe_stringify(__last_name or path),
				path = path,
				writable = __writable
			}
			__last_name = nil
			__writable = false
			if path == '-' then
				assert(not __infile_pipe_defined, 'cannot use pipe in two infiles')
				__infile_pipe_defined = true
			end
		end
		i = i + 1
	end
end

if #infiles == 0 then
	show_help()
	return 1
end

local outfp, outfp_err = outfile == '-' and io.stdout or io.open(outfile, 'w')

if outfp_err then
	printerr('cannot open output file: ' .. outfp_err)
	return 1
end

local hexter = '%02x'

for i, infile_info in pairs(infiles) do
	local name, path = infile_info.name, infile_info.path
	printerr('processing ' .. path .. ' as "' .. name .. '"')

	local infp, infp_err = path == '-' and io.stdin or io.open(path, 'r')
	if not infp_err then
		local infile_len = 0
		local prefix = infile_info.writable and '' or 'const '
		outfp:write(prefix .. 'unsigned char ' .. name .. '[] = {\n')
		local chunk
		repeat
			chunk = infp:read(512)
			if not chunk then break end
			for i = 1, #chunk do
				local char = chunk:byte(i)
				outfp:write('0x' .. hexter:format(char) .. ',')
				if i % 16 == 0 then outfp:write('\n') end
			end
			infile_len = infile_len + #chunk
		until (#chunk < 512);
		outfp:write('\n0};\n')
		outfp:write('long long int ' .. name .. '_len = ' .. infile_len .. ';\n')
		if infp ~= io.stdin then infp:close() end
	else
		printerr('cannot open input file "' .. path .. '": ' .. infp_err)
	end
end

if outfp ~= io.stdout then outfp:close() end
