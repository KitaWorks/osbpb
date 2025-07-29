--[[
   osbdb - a db implementation for osbpb
]]

local oop = require 'osbpb.oop'

local DB_PATHNAME='/var/lib/osbpb/db'

local db = oop.class {
   new = function(self)
   end
}

return db

