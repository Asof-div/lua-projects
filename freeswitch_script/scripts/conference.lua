package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]
local DB = require "DatabaseConnection"
local json = require "json"
 
local DatabaseConnection = DB.DatabaseConnection

local db = DatabaseConnection:new{}
local con = db:connect()

Conference = { session=nil, context=nil, call_type="Local", callee=nil, caller=nil, con=con, db=db, gateway="192.168.234.9", profile="default" }

function Conference:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end



function Conference:join()

	if self.call_type == "Local" then

		local conf = LocalConference:new({con=self.con, session=self.session, context=self.context})		
		conf:getConferenceNumber(self.callee)


	elseif self.call_type == "Public" then



	elseif self.call_type == "Private" then



	elseif self.call_type == "Video" then



	end

end


LocalConference = Conference:new{};
PublicConference = Conference:new{};
PrivateConference = Conference:new{};
VideoConference = Conference:new{};

function LocalConference:getConferenceNumber(num)
	
	cur, errorString = self.con:execute(string.format("select * from conferences where number='%s' and context='%s' limit 1", num, self.context))
	self.session:consoleLog("info", string.format("select * from conferences where number='%s' and context='%s' limit 1", num, self.context))
	if errorString then
		
		self.session:hangup("UNALLOCATED_NUMBER")
		
	elseif cur then
	
		conference = cur:fetch({}, "a")
	
		if conference ~= nil then

			self.moderator_pin = conference.admin_pin 
			self.guest_pin = conference.guest_pin 

			if( self:getConferencePin(1,4,3,4000) == true ) then

				self:join(conference.number)

			else

				-- Conference %d invalid PIN entered, Looping again --

			end

		else

			self.session:execute("phrase", "conference_bad_num")

		end
		cur:close()
		self.session:hangup()
	end	

end

function LocalConference:getConferencePin(min, max, attempts, timeout)

	local pin_attempt = 1
	local pin_max_attempt = 3

	while pin_attempt <= pin_max_attempt do

		-- conference_pin = self.session:playAndGetDigits(min,max,attempts,timeout, '#', 'phrase:conference_pin', '', '\\d+')
	    self.session:set_tts_params("flite", "slt");
	    self.session:speak("Enter Your Conference Pin");
    	conference_pin = self.session:getDigits(5,'#',timeout)
		if tonumber(conference_pin) == tonumber(self.guest_pin) then
			self.user_account = 'guest'
			return true
		elseif tonumber(conference_pin) == tonumber(self.moderator_pin) then
			self.user_account = 'moderator'
			return true
		else
			self.session:execute('phrase', 'conference_bad_pin')
		end
		pin_attempt = pin_attempt + 1
	end
	return false
end

function LocalConference:join(num)
	self.db:close()
	if(self.user_account == 'moderator') then

		self.session:execute('conference', string.format("%s@%s", num, self.profile))
	else

		self.session:execute('conference', string.format("%s@%s", num, self.profile))
	end

end



function PrivateConference:getConferenceNumber(num)
	
	cur, errorString = self.con:execute(string.format("select * from conferences where id='%d' limit 1", num))
	self.session:consoleLog("info", string.format("select * from conferences where id='%d' limit 1", num))
	if errorString then
		
		self.session:hangup("UNALLOCATED_NUMBER")
		
	elseif cur then
	
		conference = cur:fetch({}, "a")
	
		if conference ~= nil then

			self.moderator_pin = conference.admin_pin 
			self.guest_pin = conference.guest_pin 

			if( self:getConferencePin(1,4,3,4000) == true ) then

				self:join(conference.number)

			else

				-- Conference %d invalid PIN entered, Looping again --

			end

		else

			self.session:execute("phrase", "conference_bad_num")

		end
		cur:close()
		self.session:hangup()
	end	

end

function PrivateConference:getConferencePin(min, max, attempts, timeout)

	local pin_attempt = 1
	local pin_max_attempt = 3

	while pin_attempt <= pin_max_attempt do

		-- conference_pin = self.session:playAndGetDigits(min,max,attempts,timeout, '#', 'phrase:conference_pin', '', '\\d+')
	    self.session:set_tts_params("flite", "slt");
	    self.session:speak("Enter Your Conference Pin");
    	conference_pin = self.session:getDigits(5,'#',timeout)
		if tonumber(conference_pin) == tonumber(self.guest_pin) then
			self.user_account = 'guest'
			return true
		elseif tonumber(conference_pin) == tonumber(self.moderator_pin) then
			self.user_account = 'moderator'
			return true
		else
			self.session:execute('phrase', 'conference_bad_pin')
		end
		pin_attempt = pin_attempt + 1
	end
	return false
end

function PrivateConference:join(num)
	self.db:close()
	if(self.user_account == 'moderator') then

		self.session:execute('conference', string.format("%s@%s", num, self.profile))
	else

		self.session:execute('conference', string.format("%s@%s", num, self.profile))
	end

end

return {
	PrivateConference = PrivateConference,
	LocalConference = LocalConference,
}





start_time = os.time()
local conf = Conference:new{session = session, caller=argv[1], callee=argv[2], context=argv[3]  }
conf:join()
end_time = os.time()
elapsed_time = os.difftime(end_time-start_time)
session:consoleLog("info", 'start time: '   .. start_time )
session:consoleLog("info", 'end time: '     .. end_time )
session:consoleLog("info", 'time elapsed: ' .. elapsed_time )


