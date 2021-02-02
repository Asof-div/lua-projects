luasql = require "luasql.postgres"

local server = "192.168.234.43"
local username = "postgres"
local password = "postgres"
local db = "apponereach"

DatabaseConnection = {
	server = server, db = db, username = username, 
	password = password, con = nil, env = nil,  
}

function DatabaseConnection:connect()
	local ErrSt
	self.env, ErrSt = assert(luasql.postgres())
	if self.env then
		self.con  = assert(self.env:connect(self.db, self.username, self.password, self.server))

		if self.con then
			return self.con
		end
	end

	if ErrSt then
		print("Unable to connect to with luasql module")
		return false
	end

	if ErrStr then
		print("Unable to connect to Database")
		return false
	end

	return self.con
end

function DatabaseConnection:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function DatabaseConnection:close()
	
	if self.env then
		
		if self.con then

			self.con:close()
		
		end

		self.env:close()
	end

end

return {
	DatabaseConnection = DatabaseConnection
}
