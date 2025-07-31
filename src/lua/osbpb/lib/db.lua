--[[
   osbdb - a db implementation for osbpb
]]

local misc = require 'osbpb.misc'

local DB_PATHNAME='/var/lib/osbpb/db'

local db = misc.class {
   new = function(self)
   end
}

return db

