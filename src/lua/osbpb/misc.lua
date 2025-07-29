local oop = {
   call = function(cls, ...)
      local instance = {
         __index = cls,
      }
      if instance.new then instance:new(...) end
      return instance
   end,
}

oop.class = function(defs)
   local class = {
      __index = defs,
      __call = oop.call,
   }
   setmetatable(class, class)
   return class
end

local module = {
   class = oop.class,

   oncase = function(var, cases, ...)
      for k, v in pairs(cases) do
         if var[k] then v(var, ...) end
      end
   end
}

return module

