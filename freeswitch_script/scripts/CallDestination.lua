local json = require "json"
local conference = require "Local_Conference"

Destination = { session = nil, con = con, action = nil, value = nil, gateway = "9mobile_gateway" }

function Destination:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

Extension = Destination:new{}
Number = Destination:new{}
Group = Destination:new{}
Receptionist = Destination:new{IVRMENU = {}}
Voicemail = Destination:new{}
PlayMedia = Destination:new{}
Conference = conference.PrivateConference



function Extension:call()
	local number ;

	if self.action == "bridge" then
		number = self.value;
		self.session:execute("bridge", string.format("user/%s", self.value))
		self.session:setVariable('log_call_to', self.value);
				self.session:setVariable('log_dest_type', 'Extension');

	elseif self.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from extensions where id='%d' limit 1", self.value))
		if errorString then
			
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")
			if destination then
				number = destination.number;
				self.session:execute("bridge", string.format("user/%s", destination.exten_reg));
				self.session:setVariable('log_call_to', destination.number);
				self.session:setVariable('log_dest_type', 'Extension');

			end
			cur:close()
		end

	end
	return number;
end

function Number:call()
	local number ;
	if self.action == "bridge" then
		number = self.value;
		self.session:execute("bridge", string.format("sofia/gateway/%s/%s", self.gateway, self.value))
		self.session:consoleLog("info", 'bridge '   .. string.format("sofia/gateway/%s/%s", self.gateway, self.value) )
		self.session:setVariable('log_call_to', self.value);
		self.session:setVariable('log_dest_type', 'Number');

	elseif self.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from numbers where id='%d' limit 1", self.value))
		if errorString then
			
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")
			if destination then
				number = destination.number;
				self.session:execute("bridge", string.format("sofia/gateway/%s/%s", self.gateway, destination.number))
				self.session:consoleLog("info", 'table '   .. string.format("sofia/gateway/%s/%s", self.gateway, destination.number) )
				self.session:setVariable('log_call_to', destination.number);
				self.session:setVariable('log_dest_type', 'Number');

			end
			
			cur:close()
		end

	end
	return number;
end

function Group:play()
	local number ;
	if self.action == "bridge" then

		local dial_string = ""

		for k,member in pairs(self.value) do

			if member.type == 'sip_profile' then
				number = number .. string.format("%s, ", member.number);
				dial_string = dial_string .. string.format("user/%s,", member.number)

			elseif member.type == 'number' then
				number = number .. string.format("%s, ", member.number);
				dial_string = dial_string .. string.format("gateway/%s/%s,", self.gateway, member.number)

			end

		end

		self.session:execute("bridge", dial_string)		
		self.session:setVariable('log_call_to', dial_string);
		self.session:setVariable('log_dest_type', 'Group');

	elseif self.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from group_calls where id='%d' limit 1 ", self.value))
		if errorString then
			
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")

			local group_dest = json.decode(destination.members)

			
			local dial_string = ""

			for k,member in pairs(group_dest) do

				if member.type == 'sip_profile' then

					number = number .. string.format("%s, ", member.number);
					dial_string = dial_string .. string.format("user/%s%s,", destination.context, member.number)

				elseif member.type == 'number' then

					number = number .. string.format("%s, ", member.number);
					dial_string = dial_string .. string.format("gateway/%s/%s,", self.gateway, member.number)

				end

			end

			self.session:execute("bridge", dial_string)	
			self.session:setVariable('log_call_to', destination.number);
			self.session:setVariable('log_dest_type', 'Group');


		end


	end
	return number;
end

function PlayMedia:play()
	local number;
	if self.action == "bridge" then

		if self.value.type == 'tts' then
			
			self.session:set_tts_params("flite", "slt");
			self.session:speak(self.value.param)
			number = string.format("text: %s", self.value.param);
			
		elseif self.value.type == 'file' then

			number = string.format("sound: %s", self.value.param);
			local sound = "/var/cloudpbx/"..self.value.param
			self.session:execute("playback", sound)

		else 

			self.session:hangup("UNALLOCATED_NUMBER")
		
		end

	elseif self.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from play_media where id='%d' limit 1 ", self.value))
		if errorString then
			
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			destination = cur:fetch({}, "a")

			if destination.application == 'tts' then

				number = string.format("text: %s", destination.content);
				self.session:speak(destination.content)
		
			elseif destination.application == 'file' then

				self.session:consoleLog('info', "PlayMedia " .. destination.application)
				self.session:execute("set_zombie_exec")
				self.session:sleep(1000)
				number = string.format("text: %s", destination.path);
				local sound = "/var/cloudpbx/" .. destination.path
				self.session:execute("playback", sound)

			else 

				self.session:hangup("UNALLOCATED_NUMBER")
			
			end
		end

	end

	return number;
end

function Voicemail:record(entry)
	local number;
	self.session:consoleLog("info", 'Voicemail '.. entry.tenant_id  )
	if self.value ~= nil then

		date = os.date("%b-%y")
		name = string.format("COM_%s/voicemail/%s/%s_%s.wav",self.destination.code, self.value, date, self.uuid)
		os.execute(string.format("mkdir -pm 777 /var/cloudpbx/COM_%s/voicemail/%s", self.destination.code, self.value))
		local start_time = os.date("%Y-%m-%d %X", entry.start_time);

		number = string.format("voicemail: %s", self.value);
		filename =  string.format("/var/cloudpbx/%s", name )
		self.session:set_tts_params("flite", "slt");
		self.session:speak("You have been redirected to voicemail.")
		self.session:sleep(20) 
		self.session:speak("Kindly leave your voice message.")
		self.session:sleep(1000) 
		self.session:recordFile(filename,300,100,10) 
		self.session:hangup()

		os.execute("chmod -Rf 777 /var/cloudpbx")
		self.session:consoleLog("info", 'before update: '  )
		self.con:execute(string.format([[INSERT INTO voicemails (tenant_id, cdr_uuid, caller_id_num, caller_id_name, number_type, number, destination_type, 
		filename) 
		VALUES ('%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s') 
		]], entry.tenant_id, entry.uuid, entry.caller_id_num, entry.caller_id_name, 'Pilotline', self.value, 'voicemail', name));
		self.session:consoleLog("info", 'after update: '  )
		
	end
	return number;
end

-- function Conference:play()

-- 	local conf = PrivatConference:new({con=self.con, session=self.session, context=self.context})		
-- 	conf:getConferenceNumber(self.callee)

-- end

function Receptionist:play() 
	local number = nil;
	if self.action == "table" then

		cur, errorString = self.con:execute(string.format("select * from virtual_receptionists where id='%d' limit 1", self.value))
		if errorString then
			
			self.session:hangup("UNALLOCATED_NUMBER")
			
		elseif cur then

			self.session:setVariable('log_dest_type', 'IVR');
			Menu = cur:fetch({}, "a")
			if Menu.ivr_type == "file" then

				local sound = "/var/cloudpbx/"..Menu.ivr_msg
				self.session:execute("playback", sound)
				number = self:menu();

			elseif Menu.ivr_type == "tts" then

				self.session:speak(Menu.ivr_msg)
				number = self:menu();

			else 

				self.session:hangup("UNALLOCATED_NUMBER")

			end
			cur:close()
		end


	end
	return number;
end

function Receptionist:menu()
	local number = nil;
	cur, errorString = self.con:execute(string.format("select * from virtual_receptionist_menus where virtual_receptionist_id='%d' order by key_press asc", self.value))
	
	if errorString then
		
		self.session:consoleLog('info', 'errorString ' .. self.value)
		self.session:hangup("UNALLOCATED_NUMBER")
		
	elseif cur then
		Row = cur:fetch({}, 'a')

		while Row do

			table.insert(self.IVRMENU, Row)
			Row = cur:fetch({}, 'a')				
		end
		-- self.session:speak("");

		local min = 1
		local max = 3
		local attempt = 1
		local max_attempt = 3
		local timeout = 1

		-- digits = self.session:playAndGetDigits(min,max,max_attempt,timeout, '', 'phrase:conference_pin', '', '\\d+')
		local result = self:getOption(3,5000);
		if result ~= nil then
			number = self:call(result, self.cdr);
		end

		cur:close()
		self.session:hangup()

	end

	return number;
end

function Receptionist:getOption(max, timeout)

	local attempt = 1
	local max_attempt = max

	while attempt <= max_attempt do

	    self.session:speak("Select your option");
		digits = self.session:getDigits(1, "", timeout);
		if digits then

			result = self:search(digits, self.IVRMENU)

			if result ~= nil then

				return result
			else

			    self.session:speak("Invalid menu option");

			end
		else

		    self.session:speak("Invalid menu option");
		end 

		attempt = attempt + 1
		if attempt < max_attempt then
		    self.session:speak("Try again");
		end
	end
	return nil;
end

function Receptionist:call(destination, cdr)
	local number;
	local pdestination = self.pdestination
	local dest_type = destination.action
	local dest_params = json.decode(destination.params)

	if dest_type == "extension" then
						
		local extension = Extension:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		number = extension:call()
	
	elseif dest_type == "number" then

		local numb = Number:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})
		number = numb:call()
	
	elseif dest_type == "group" then
	
		local group = Group:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		number = group:play()
	
	elseif dest_type == "receptionist" then
	
		local reception = Receptionist:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value, pdestination = pdestination, cdr=cdr})		
		number = reception:play()
	
	elseif dest_type == "voicemail" then
	
		self.session:consoleLog("info", self.pdestination.voicemail_number )
		local voicemail = Voicemail:new({con = self.con, session = self.session, destination = destination, value = pdestination.voicemail_number, uuid=self.session:getVariable('uuid')});		
		number = voicemail:record(cdr);
	
	elseif dest_type == "playback" then
	
		local playMedia = PlayMedia:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		number = playMedia:play(dest_params.action, dest_params.value)

	elseif dest_type == "conference" then
	
		local conference = Conference:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		number = conference:play(dest_params.action, dest_params.value)

	end

	return number;
end

function Receptionist:search(key, menu)

	for _, v in pairs(menu) do

		if tonumber(key) == tonumber(v.key_press) then

			return v
		end
	end

	return nil
end

function Receptionist:RowsIter()
	local Row = {}
	return self.Cursor:fetch(Row, 'a')
end


return {
	Group = Group,
	Extension = Extension,
	Number = Number,
	Receptionist = Receptionist,
	Voicemail = Voicemail,
	PlayMedia = PlayMedia,
	Conference = Conference
}

