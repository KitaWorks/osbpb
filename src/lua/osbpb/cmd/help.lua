local function help(args)
   local parser = args

   print(parser:get_usage())
end

return help

