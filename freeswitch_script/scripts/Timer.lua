
Timer = { session = nil, wday = nil, mon = nil, min = nil, sec = nil, day = nil}

function Timer:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end


function Timer:custom(destination)
	start_min, start_sec = string.match(destination.start_time, '^(%d%d)%:(%d%d)$')
	start_time = tonumber( tonumber(start_min) + tonumber("00." .. start_sec) )
	end_min, end_sec = string.match(destination.end_time, '^(%d%d)%:(%d%d)$')
	end_time = tonumber( tonumber(end_min) + tonumber("00." .. end_sec) )
	time = tonumber( tonumber(self.min) + tonumber("00." .. self.sec) )
	wdays = json.decode(destination.wday)

	self.session:consoleLog('info', 'custom method ' .. time)


	if start_time <= time and end_time >= time and self:findWday(wdays) then

		return true
	else

		return false
	end
end

function Timer:date(destination)
	start_min, start_sec = string.match(destination.start_time, '^(%d%d)%:(%d%d)$')
	start_time = tonumber( tonumber(start_min) + tonumber("00." .. start_sec) )
	end_min, end_sec = string.match(destination.end_time, '^(%d%d)%:(%d%d)$')
	end_time = tonumber( tonumber(end_min) + tonumber("00." .. end_sec) )
	time = tonumber( tonumber(self.min) + tonumber("00." .. self.sec) )
	mon = tonumber(destination.mon) 
	day = tonumber(destination.start_day)


	if start_time <= time and end_time >= time and tonumber(self.mon) == mon and tonumber(self.day) == day then
		return true
	else
		return false
	end
end

function Timer:customdate(destination)
	start_min, start_sec = string.match(destination.start_time, '^(%d%d)%:(%d%d)$')
	start_time = tonumber( tonumber(start_min) + tonumber("00." .. start_sec) )
	end_min, end_sec = string.match(destination.end_time, '^(%d%d)%:(%d%d)$')
	end_time = tonumber( tonumber(end_min) + tonumber("00." .. end_sec) )
	time = tonumber( tonumber(self.min) + tonumber("00." .. self.sec) )
	mon = tonumber(destination.mon)
	wdays = json.decode(destination.wday)

	-- every first mon day of january	
	if start_time <= time and end_time >= time and tonumber(self.mon) == mon and self:findWday(wdays) then
		return true
	else
		return false
	end
end

function Timer:rangedate(destination)
	start_min, start_sec = string.match(destination.start_time, '^(%d%d)%:(%d%d)$')
	start_time = tonumber( tonumber(start_min) + tonumber("00." .. start_sec) )
	end_min, end_sec = string.match(destination.end_time, '^(%d%d)%:(%d%d)$')
	end_time = tonumber( tonumber(end_min) + tonumber("00." .. end_sec) )
	time = tonumber( tonumber(self.min) + tonumber("00." .. self.sec) )
	mon = tonumber(destination.mon) 
	startday = tonumber(destination.start_day)
	endday = tonumber(destination.start_day)
	
	-- every first mon day of january	
	if start_time <= time and end_time >= time and tonumber(self.mon) == mon and startday <= tonumber(self.day) and endday >= tonumber(self.day) then
		return true
	else
		return false
	end
end



function Timer:findWday(wdays)
	result = false
	for i, v in pairs(wdays) do
		if tonumber(v) == tonumber(self.wday) then
			result = true
			break
		end 
	end

	return result
end



return {
	Timer = Timer,
}

