package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]

local DB = require "DatabaseConnection"
local CallDestination = require "CallDestination"
local Timer = require "Timer"
local json = require "json"
 
local DatabaseConnection = DB.DatabaseConnection

local db = DatabaseConnection:new{}
local con = db:connect()

local Timer = Timer.Timer

local CDR = {tenant_id=nil,uuid=nil,caller_id_name=nil, caller_id_num=nil,direction=nil,callee_id_num=nil,dest=nil,dest_type=nil,status=nil,duration=nil,start_time=nil,answer_time=nil,end_time=nil}
function CDR:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

DID = { session = nil, callee = nil, caller = nil, con = con, db = db, Timer = Timer, 
	CallDestination = CallDestination, defaultDestination = nil, autoAttendant = nil, wday = nil, mon = nil, min = nil, sec = nil, day = nil }

function DID:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function DID:bridgeEndpoint()
	while(session:ready() == true) do

		cur, errorString = self.con:execute( string.format([[select * from call_flows where direction = 'inbound' and dial_string='%s' order By priority asc]], self.callee))
		-- self.session:consoleLog('info', cur);
		-- self.session:consoleLog('info', string.format([[select * from call_flows where direction = 'inbound' and dial_string='%s' order By priority asc]], self.callee))
		-- self.session:consoleLog('info', errorString);
		if errorString then
			return false
		end

		local time = os.date('*t')
		local timer = self.Timer:new{session = self.session, wday = time.wday, mon = time.month, min = time.hour, sec = time.min, day = time.day}

		self.defaultDestination = nil
		self.autoAttendant = nil

		Row = cur:fetch({}, 'a')
		self.session:setVariable('log_call_type', 'inbound');

		while Row  do
			self.session:consoleLog('info', 'conditions ' .. Row.conditions)

			if tonumber(Row.priority) == 0 and Row.conditions == 'destination' then
				self.defaultDestination = Row
				self.session:consoleLog('info', 'default '.. Row.conditions )

			else

				if Row.conditions == 'all' then

					self.autoAttendant = Row
					self.session:consoleLog('info', 'all timer ' )

					break

				elseif Row.conditions == 'custom' then
					self.session:consoleLog('info', 'custom timer ' )

					if timer:custom(Row) then
						self.autoAttendant = Row
						self.session:consoleLog('info', 'custom timer 2 ' )

						break
					end

				elseif Row.conditions == 'date' then
					if timer:date(Row) then
						self.autoAttendant = Row
						self.session:consoleLog('info', 'date timer ' )
						break
					end
				elseif Row.conditions == 'custom_date' then
					if timer:customdate(Row) then
						self.autoAttendant = Row
						self.session:consoleLog('info', 'custom date timer ' )
						break
					end
				elseif Row.conditions == 'range' then
					if timer:rangedate(Row) then
						self.autoAttendant = Row
						self.session:consoleLog('info', 'range timer ' )
						break
					end
				end
			end
		
			Row = cur:fetch({}, 'a')

		end

		if self.autoAttendant ~= nil then

			self.session:consoleLog('info', 'autoAttendant ')
			self:call(self.autoAttendant)

			self.session:hangup("UNALLOCATED_NUMBER")

		elseif self.defaultDestination ~= nil then

			self.session:consoleLog('info', 'defaultDestination ')
			self:call(self.defaultDestination)

			self.session:hangup("UNALLOCATED_NUMBER")

		else
			self.session:hangup("UNALLOCATED_NUMBER")
		end

		self.session:hangup()

		cur:close()
		
	end
end


function DID:call(destination)
	self.finalDestination = destination;
	local cdr = CDR:new{tenant_id=destination.tenant_id,start_time=self.start_time,caller_id_num=self.caller,
		direction='inbound', uuid=self.session:getVariable('uuid'), dest=self.callee, dest_type='mobile',
		callee_id_num=self.callee, status="unanswered"
	};
	local recording_filename;
	local moh_filename;
	self.session:preAnswer()
	-- self.session:execute("answer")
	cdr.start_time = os.time();
	self.session:setVariable("sip_h_X-A-Number", self.caller);
	self.session:setVariable("caller_id_number", self.callee);
	self.session:setVariable("sip_h_X-B-Number", self.callee);
	self.session:setVariable("sip_h_X-Contact", self.callee);
	self.session:setVariable("sip_h_X-contact", self.callee);
	self.session:setVariable("ani", self.callee);
	self.session:consoleLog('info', 'Caller  ' .. self.caller);
	self.session:consoleLog('info', 'Callee  ' .. self.callee);
	self.session:setVariable('log_call_from', self.caller);
	self.session:setVariable('log_tenant_id', destination.tenant_id);
	self.session:setVariable('log_source', self.callee);



	-- self.session:execute("bridge", string.format("sofia/gateway/%s/%s", self.gateway, '08032368778'))

	-- Start recording --
	recording_filename = self:startRecording();
	cdr.call_recording = recording_filename;
	greeting_filename = self:greeting(destination.greeting_param, destination.greeting_type)
	moh_filename = self:moh(destination.moh_param, destination.moh_type)
	cdr.play_media_name = moh_filename;
	
	local dest_values = nil;
	local dest_type = destination.dest_type
	local dest_params = json.decode(destination.dest_params)

	if dest_type == "Extension" then
						
		local extension = self.CallDestination.Extension:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		dest_values = extension:call()
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "extension";
		cdr.dest = dest_values;

	elseif dest_type == "Number" then

		local number = self.CallDestination.Number:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})
		dest_values = number:call();
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "number";
		cdr.dest = dest_values;

	elseif dest_type == "Group" then
	
		local group = self.CallDestination.Group:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})		
		dest_values = group:play();
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "group";
		cdr.dest = dest_values;

	elseif dest_type == "Receptionist" then
	
		local reception = self.CallDestination.Receptionist:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value, cdr=cdr, pdestination = destination,})		
		dest_values = reception:play();
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "receptionist";
		cdr.dest = dest_values;

	elseif dest_type == "Voicemail" then
	
		local voicemail = self.CallDestination.Voicemail:new({con = self.con, session = self.session, destination = destination, value = destination.voicemail_number, uuid=self.session:getVariable('uuid')});		
		dest_values = voicemail:record(cdr);
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "voicemail";
		cdr.dest = dest_values;

	elseif dest_type == "Playback" then
	
		local playback = self.CallDestination.PlayMedia:new({con = self.con, session = self.session, action = dest_params.action, value = dest_params.value})
		dest_values = playback:play();
		cdr.status = self.session:getVariable('originate_disposition');
		cdr.answer_time = self.session:getVariable('answered_time');
		cdr.end_time = self.session:getVariable('hangup_time');
		cdr.dest_type = "moh";
		cdr.dest = dest_values;

	end

	self:CDR(cdr);	

end

function DID:findWday(wdays)
	wday = false
	for i, v in pairs(wdays) do
		if tonumber(v) == tonumber(self.wday) then
			wday = true
			break
		end 
	end
	return wday
end


function DID:moh(moh, moh_type)
	local number = nil;
	if moh_type == 'tts' then
		
		self.session:set_tts_params("flite", "slt");
		self.session:speak(moh)
		number = string.format("text: %s", moh);

	elseif moh_type == "file" or moh_type == "sound" then

		number = string.format("sound: %s", moh);
		self.session:execute("playback", string.format("%s/%s",'/var/cloudpbx', moh))
	
	end
	return number;
end

function DID:greeting(moh, moh_type)
	local number = nil;
	if moh_type == 'tts' then
		
		self.session:set_tts_params("flite", "slt");
		self.session:speak(moh)
		number = string.format("text: %s", moh);

	elseif moh_type == "file" or moh_type == "sound" then

		number = string.format("sound: %s", moh);
		self.session:execute("playback", string.format("%s/%s",'/var/cloudpbx', moh))
	
	end
	return number;
end


function DID:startRecording()
	
	recording_dir = '/tmp/'
	filename =  string.format("%s_%s_%s_record.wav", self.callee, self.caller, self.session:getVariable("uuid") );
	path =  string.format("COM_%s/recording/%s", self.finalDestination.code, os.date("%Y-%m-%d-%H-%M", self.start_time) );
	recording_filename = string.format('%s/%s', path, filename)
	max_len_secs = 30
	silence_threshold = 30
	silence_secs = 5

	self.session:setVariable('log_recording_path', recording_filename);

	os.execute(string.format("mkdir -pm 777 /var/cloudpbx/%s", path ));

	self.session:execute("set", string.format("RECORD_TITLE=Recording %s %s %s", self.callee, self.caller, os.date("%Y-%m-%d %H:%M", self.start_time)));
	self.session:execute("set", "RECORD_ARTIST=ABIODUN_ADEYINKA");
	self.session:execute("set", "RECORD_COMMENT=ABIODUN_ADEYINKA_CLOUDPBX");
	self.session:execute("set", "RECORD_STEREO=true");
	-- self.session:execute("record_session", string.format("/var/cloudpbx/%s", recording_filename));
	self.session:execute("export", string.format("execute_on_answer=record_session /var/cloudpbx/%s", recording_filename));
	os.execute(string.format("chmod -Rf 777 /var/cloudpbx/%s", recording_filename ));
	return recording_filename;
	-- self.session.recordFile(recording_filename, max_len_secs, silence_threshold, silence_secs)

end


function DID:bridge()

	self:bridgeEndpoint()

end

function DID:CDR(entry)

	local start_time = os.date("%Y-%m-%d %X", entry.start_time);
	local answer_time = os.date("%Y-%m-%d %X", entry.answer_time);
	local end_time = os.date("%Y-%m-%d %X", entry.end_time);
	-- entry.duration = os.difftime(entry.end_time-entry.start_time)
	local record = 0;
	local answer_time = os.date("%Y-%m-%d %X", entry.start_time);
	-- answer_time = nil;
	if entry.call_recording ~= nil then

		record = 1;

	end

	self.con:execute(string.format([[INSERT INTO cdrs (tenant_id, uuid, caller_id_num, caller_id_name, direction, callee_id_num, destination, destination_type, 
		status, duration, start_timestamp, answer_timestamp, end_timestamp, call_recording, recorded, source, play_media_name) 
		VALUES ('%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%d', '%s', '%s') 
		]], entry.tenant_id, entry.uuid, entry.caller_id_num, entry.caller_id_name, entry.direction,
		 entry.callee_id_num, entry.dest, entry.dest_type, entry.status, 
		 entry.duration, start_time, answer_time, end_time, entry.call_recording, record, entry.callee_id_num, entry.play_media_name));

	os.execute(string.format("chmod -Rf 777 /var/cloudpbx" ));

end


start_time = os.time()
local inbound = DID:new{session = session, caller=argv[1], callee=argv[2], start_time=os.time() }
inbound:bridge()
db:close()
end_time = os.time()
elapsed_time = os.difftime(end_time-start_time)
session:consoleLog("info", 'start time: '   .. start_time )
session:consoleLog("info", 'end time: '     .. end_time )
session:consoleLog("info", 'time elapsed: ' .. elapsed_time )