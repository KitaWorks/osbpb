local function help(args)
   local parser = args.parser

   print(parser:get_help())
end

return help

