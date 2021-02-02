package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]
local DB = require "DatabaseConnection"
local json = require "json"
local Log = require "call_logs"
 
local DatabaseConnection = DB.DatabaseConnection
local CallLog = Log.CallLog

local db = DatabaseConnection:new{}
local con = db:connect()

local CDR = {tenant_id=nil,uuid=nil,caller_id_name=nil, caller_id_num=nil,direction=nil,callee_id_num=nil,dest=nil,dest_type=nil,status=nil,duration=nil,start_time=nil,answer_time=nil,end_time=nil}
function CDR:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

LocalExtension = { session = nil, context = nil, callee = nil, caller = nil, con = con, db = db, gateway = "9mobile_gateway", start_time=nil,tenant_id=nil }

function LocalExtension:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end


function LocalExtension:bridgeEndpoint()

	self.session:consoleLog("info", 'first: ' ..  string.format("select * from call_flows where direction='intercom' and conditions='destination' and dial_string='%s' and context='%s' limit 1", self.callee, self.context) )
	
	self.session:setVariable('log_call_type', 'sipcall');
	self.session:setVariable('log_callee_num', self.callee);
	self.session:setVariable('log_tenant_id', self.tenant_id);
	self.session:setVariable('log_user_id', self.session:getVariable('user_id') );
	self.session:setVariable('log_uuid', self.session:getVariable('uuid') );

	local call = CallLog:new{session = self.session, caller=self.session:getVariable('effective_caller_id_number'), callee=self.callee,start_time=self.start_time};
	self.call = call;
	cur, errorString = self.con:execute(string.format("select * from call_flows where direction='intercom' and conditions='destination' and dial_string='%s' and context='%s' limit 1", self.callee, self.context))
	if errorString then
		
		self.session:setVariable('log_dest_type', 'UNKNOWN');
		self.session:setVariable('log_status', 'UNREACHABLE');
		self.session:hangup("UNALLOCATED_NUMBER")
		
		
	elseif cur then
		self.session:consoleLog("info", 'problem here: ' ..  string.format("select * from call_flows where direction='intercom' and conditions='destination' and dial_string='%s' and context='%s' limit 1", self.callee, self.context) )

		destination = cur:fetch({}, "a")
		
		if destination ~= nil then

			if destination.dest_type == "Extension" then

				self:bridgeExten(destination)

			elseif destination.dest_type == "Group" then

				self:bridgeGroup(destination)

			elseif destination.dest_type == "Conference" then

				self:bridgeConference(destination)

			else
				self.call.status = 'Unreachable';
				self.session:hangup("UNALLOCATED_NUMBER")
				-- self:CDR(cdr);

			end

		else

			self.session:set_tts_params("flite", "slt");
			self.session:speak("The number you have call is not available");
			self.session:hangup("UNALLOCATED_NUMBER")
			self.session:setVariable('log_dest_type', 'UNKNOWN');
			self.session:setVariable('log_status', 'UNREACHABLE');
			self.session:hangup("UNALLOCATED_NUMBER")
			
		end

		cur:close()
	end
	

end

function LocalExtension:bridgeGroup(destination)
	
	local Endpoint = destination;	

	self.session:setVariable('log_dest_type', 'Group');

	local group = json.decode(Endpoint.dest_params);

	if group.action == "bridge" then

		local dial_string = ""

		for k,member in pairs(group.value) do

			if member.type == 'sip_profile' then

				self.session:consoleLog('info', k);
				self.session:consoleLog('info', member.number);
				dial_string = dial_string .. string.format("user/%s|", member.number)

			elseif member.type == 'number' then

				dial_string = dial_string .. string.format("sofia/gateway/%s/%s|", self.gateway, member.number)

			end

		end

		self.session:execute("bridge", dial_string);
		self.session:consoleLog('info', dial_string);
		self.session:consoleLog('info', g);

	end

	-- self:CDR(cdr);


end

function LocalExtension:bridgeExten(destination)
	
	local Endpoint = destination;	


	self.session:setVariable('log_dest_type', 'Extension');

	exten = json.decode(Endpoint.dest_params);

	if exten.action == "bridge" then
		self.session:setVariable('log_dest_type', 'Extension');
		self.session:execute("bridge", string.format("user/%s", exten.value))

	elseif exten.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from extensions where id='%d' ", exten.value))
		if errorString then
			
			self.call.status = 'Unreachable';
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")
			if destination then

				self.session:execute("bridge", string.format("user/%s", destination.exten_reg))
				-- self.session:hangup();
			end
		end
		cur:close()

	end

	self.session:hangup();


	-- self:CDR(cdr);

end


function LocalExtension:bridgeConference(destination)
	
	local Endpoint = destination;	
	self.session:setVariable('log_dest_type', 'Conference');

	conf = json.decode(Endpoint.dest_params);

	if conf.action == "bridge" then

		-- self.session:execute("bridge", string.format("user/%s", conf.value))

	elseif conf.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from conferences where id='%d' ", conf.value))
		if errorString then
			
			cdr.status = 'Unreachable';
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")
			if destination then

				local members = json.decode(destination.members)

				local user_account = "guest"

				for k,member in pairs(members) do

					if member.member_type == 'extension' and member.member_number == self.session:getVariable('effective_caller_id_number') then

						user_account = 'moderator';
						break;

					end

				end

				if user_account == 'moderator' then
					
					self.session:execute('conference', string.format("%s@%s", destination.number, 'default'))
				else 

	
					if( self:getConferencePin(1,4,3,4000, conference.guest_pin) == true ) then

						self.session:execute('conference', string.format("%s@%s", destination.number, 'default'))
						
					end

				end

				self.session:hangup();

			end
		end
		cur:close()

	end

	-- self:CDR(cdr);

end


function LocalExtension:getConferencePin(min, max, attempts, timeout, pin)

	local pin_attempt = 1
	local pin_max_attempt = 3

	while pin_attempt <= pin_max_attempt do

		-- conference_pin = self.session:playAndGetDigits(min,max,attempts,timeout, '#', 'phrase:conference_pin', '', '\\d+')
	    self.session:set_tts_params("flite", "slt");
	    self.session:speak("Enter Your Conference Pin");
    	conference_pin = self.session:getDigits(4,'',timeout)
		if tonumber(conference_pin) == tonumber(pin) then
			return true
		else
			self.session:execute('phrase', 'conference_bad_pin')
		end
		pin_attempt = pin_attempt + 1
	end
	return false
end

-- {uuid='', caller_id_num='', tenant_id='', direction='',callee_id_num='',destination='',status='',duration=''}
function LocalExtension:CDR(entry)

	local start_time = os.date("%Y-%m-%d %X", entry.start_time);
	local answer_time = os.date("%Y-%m-%d %X", entry.answer_time);
	local end_time = os.date("%Y-%m-%d %X", entry.end_time);

	-- self.session:consoleLog("info", os.time(end_time) )
	-- self.session:consoleLog("info", 'duration: '   .. os.difftime(entry.end_time-entry.answer_time) )

	self.con:execute(string.format([[INSERT INTO cdrs (tenant_id, uuid, caller_id_num, caller_id_name, direction, callee_id_num, destination, destination_type, 
		status, duration, start_timestamp, answer_timestamp, end_timestamp) 
		VALUES ('%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') 
		]], entry.tenant_id, entry.uuid, entry.caller_id_num, entry.caller_id_name, entry.direction,
		 entry.callee_id_num, entry.dest, entry.dest_type, entry.status, 
		 entry.duration, start_time, answer_time, end_time));

end


start_time = os.time()
local localExten = LocalExtension:new{session = session, caller=argv[1], callee=argv[2], context=argv[3], tenant_id=argv[4],start_time=os.time(), }
localExten:bridgeEndpoint()
end_time = os.time()
-- elapsed_time = os.difftime(end_time-start_time)
session:hangup()
db:close()
session:consoleLog("info", 'start time: '   .. start_time )
session:consoleLog("info", 'end time: '     .. end_time )
-- session:consoleLog("info", 'time elapsed: ' .. elapsed_time )