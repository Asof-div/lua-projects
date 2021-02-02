-- package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]
local curl = require 'curl';
local json = require 'json';

CallLog = {json = json, curl = curl, session = nil, callee = nil, caller = nil, start_time=nil, end_time=nil, answer_time=nil, duration=nil, source=nil }

function CallLog:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function CallLog:bridgeEndpoint()
	while(session:ready() == true) do

	end
end


function CallLog:sipCall()
	


		self.session:consoleLog('info', 'time difference');
		self.session:consoleLog('info', self.status);
		self.session:consoleLog('info', self.callee);
		self.session:consoleLog('info', self.session:getVariable('status') );
		self.session:consoleLog('info', self.session:getVariable('Caller-Channel-Answered-Time') );
		local start_time = self.start_time;
		local end_time = self.end_time;
		local uuid = self.session:getVariable('uuid');
		local duration = self.session:getVariable('duration');
		local billsec = self.session:getVariable('billsec');
		local call_type = self.session:getVariable('log_dest_type');
		local rate = 0;

		if session:getVariable('DIALSTATUS') == 'SUCCESS' then
			answer_time = self.session:getVariable('answer_stamp');

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'SUCCESS', start_time, answer_time, end_time, duration, billsec, rate, '');
			
		elseif session:getVariable('DIALSTATUS') == 'DONTCALL' then
			
			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'REJECTED', start_time, end_time, end_time, duration, billsec, rate, '');
			
		elseif session:getVariable('DIALSTATUS') == 'CANCEL' then
			
			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'CANCELED', start_time, '', end_time, duration, billsec, rate, '');
			

		elseif session:getVariable('DIALSTATUS') == 'USER_NOT_REGISTERED' then

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'UNREACHABLE', start_time, '', end_time, duration, billsec, rate, '');
			
		elseif session:getVariable('DIALSTATUS') == 'BUSY' then

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'NO ANSWER', start_time, '', end_time, duration, billsec, rate, '');
			

		end



end


function CallLog:inbound()
	


		self.session:consoleLog('info', 'time difference');
		self.session:consoleLog('info', self.status);
		self.session:consoleLog('info', self.callee);
		self.session:consoleLog('info', self.session:getVariable('status') );
		self.session:consoleLog('info', self.session:getVariable('Caller-Channel-Answered-Time') );
		local start_time = self.start_time;
		local end_time = self.end_time;
		local uuid = self.session:getVariable('uuid');
		local duration = self.session:getVariable('duration');
		local billsec = self.session:getVariable('billsec');
		local call_type = self.session:getVariable('log_dest_type');
		local recording = self.session:getVariable('log_call_recording');
		local rate = 0;

		if session:getVariable('DIALSTATUS') == 'SUCCESS' then
			answer_time = self.session:getVariable('answer_stamp');

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, self.source, 'Inbound', 'SUCCESS', start_time, answer_time, end_time, duration, billsec, rate, recording);
			
		elseif session:getVariable('DIALSTATUS') == 'DONTCALL' then
			
			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, self.source, 'Inbound', 'REJECTED', start_time, end_time, end_time, duration, billsec, rate, '');
			
		elseif session:getVariable('DIALSTATUS') == 'CANCEL' then
			
			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, self.source, 'Inbound', 'CANCELED', start_time, '', end_time, duration, billsec, rate, '');
			

		elseif session:getVariable('DIALSTATUS') == 'USER_NOT_REGISTERED' then

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, self.source, 'Inbound', 'UNREACHABLE', start_time, '', end_time, duration, billsec, rate, '');
			
		elseif session:getVariable('DIALSTATUS') == 'BUSY' then

			self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, self.source, 'Inbound', 'NO ANSWER', start_time, '', end_time, duration, billsec, rate, '');
			

		end



end

function CallLog:failedLocal()
	Inbound = self.session:getVariable("uuid");
	answered_time = nil;
	start_time = self.start_time;
		
	end_time = self.end_time;
	local duration = self.session:getVariable('duration');
	local billsec = self.session:getVariable('billsec');
	local call_type = self.session:getVariable('log_dest_type');
	local rate = 0;		
	self.session:consoleLog('info', self.tenant_id);
	self.session:consoleLog('info', self.start_time);
	self.session:consoleLog('info', self.end_time);

	self:log(self.tenant_id, self.caller, self.callee, uuid, call_type, 'Local', 'Intercom', 'INVALID', start_time, '', end_time, duration, billsec, rate, '');
		

end

function CallLog:gsmCall(gateway, timelimit)
	uuid = self.session:getVariable("uuid");
	hangup_time = nil;
	answered_time = nil;
	start_time = os.date("%Y-%m-%d %X", self.start_time);

	if gateway ~= nil and tonumber(timelimit) >= 5 then
		
		self.session:execute("set","call_timeout=30")
	    self.session:execute("set","continue_on_fail=true")
	    self.session:execute("set","hangup_after_bridge=true")
	    self.session:execute("set","ringback=%(2000,4000,440.0,480.0)")
	    self.session:execute("set", string.format("sched_hangup=+%s alloted_timeout", timelimit) )
	    self.session:setVariable("caller_id_number", self.caller);
		self.session:setVariable("sip_h_X-caller_id_number", self.caller);
		self.session:setVariable("sip_h_X-caller-id-number", self.caller);
		self.session:execute("bridge", string.format("sofia/gateway/%s/%s", gateway, self.callee));
		end_timestamp = os.time()

		status = self.session:getVariable("originate_disposition") ;
		end_time = os.date("%Y-%m-%d %X", end_timestamp);
		
		if status == 'SUCCESS' then
			answered_timestamp = self.session:getVariable('answered_time');
			hangup_timestamp = self.session:getVariable('hangup_time');
			hangup_timestamp = self.session:getVariable('Event-Date-Timestamp');

			duration = hangup_timestamp - answered_timestamp

			answered_time = os.date("%Y-%m-%d %X", answered_timestamp);
			hangup_time = os.date("%Y-%m-%d %X", hangup_timestamp);
			if hangup_timestamp == nil then
				hangup_time = os.date("%Y-%m-%d %X", end_timestamp);
			end

			self.session:consoleLog('info', 'time stamp difference');
			self.session:consoleLog('info', answered_timestamp);
			self.session:consoleLog('info', hangup_timestamp);
			self.session:consoleLog('info', duration);

			self.session:consoleLog('info', 'time difference');
			self.session:consoleLog('info', answered_time);
			self.session:consoleLog('info', hangup_time);
			
			self.session:consoleLog('info', 'header time difference');
			self.session:consoleLog('info', self.session:getVariable('Caller-Channel-Answered-Time') );
			self.session:consoleLog('info', self.session:getVariable('Event-Date-Timestamp'));
			

			-- self:deductCredits(self.caller, self.callee, answered_time, hangup_time);
			
			self:log(self.caller, self.callee, uuid, 'gsm', 'outbound', 'DIALED', start_time, answered_time, hangup_time);

		elseif status == 'NO_ANSWER' then
			
			self:log(self.caller, self.callee, uuid, 'gsm', 'outbound', 'DIALED', start_time, end_time, end_time);
		
		elseif status == 'NORMAL_CLEARING' then

			self:log(self.caller, self.callee, uuid, 'gsm', 'outbound', 'DIALED', start_time, end_time, end_time);
		
		elseif status == 'ORIGINATOR_CANCEL' then

			self:log(self.caller, self.callee, uuid, 'gsm', 'outbound', 'DIALED', start_time, end_time, end_time);
		
		end

	else

		self.session:execute("answer")
		self.session:set_tts_params("flite", "slt");
		self.session:speak("Your airtime is insufficient ...")
		self.session:sleep(10) 
		self.session:hangup()
	
		self:log(self.caller, self.callee, uuid, 'gsm', 'outbound', 'DIALED', start_time, end_time, end_time);

	end


end


function CallLog:deductCredits(caller,callee,start_time,end_time)
	self.session:consoleLog('info', 'Credit end time')
	self.session:consoleLog('info', start_time);
	self.session:consoleLog('info', end_time);
	
	url = string.format("172.16.2.235/api/call/deductcredits")
	c = curl:easy_init();
	c:setopt(curl.OPT_URL, url);
	headers = {
	  "Accept: application/json",
	  -- "Content-Type: application/json",
	  "Accept-Language: en",
	  "Accept-Charset: iso-8859-1,*,utf-8",
	  "Cache-Control: no-cache"
	};

	c:setopt(curl.OPT_HTTPHEADER, headers);
	c:setopt(curl.OPT_POSTFIELDS, string.format("caller=%s&callee=%s&start_time=%s&end_time=%s", caller,callee,start_time,end_time));
	c:setopt(curl.OPT_WRITEFUNCTION, function(str, size)
		data = str;
		length = size;
		return size;
		end
		)

	c:perform();
	self.session:consoleLog('info', data);

end

function CallLog:log(tenant_id, caller,callee,uuid,dest_type,source, direction,status,start_time,answer_time,end_time, duration, billsec, rate, recording)
	self.session:consoleLog('info', 'Log end time')
	self.session:consoleLog('info', end_time);

	url = string.format("192.168.234.43/api/call/log")
	c = curl:easy_init();
	c:setopt(curl.OPT_URL, url);
	headers = {
	  "Accept: application/json",
	  -- "Content-Type: application/json",
	  "Accept-Language: en",
	  "Accept-Charset: iso-8859-1,*,utf-8",
	  "Cache-Control: no-cache"
	};
	if recording == nil then
		recorded = false;
	else
		recorded = true;
	end

	postdata = string.format("caller=%s&callee=%s&start_time=%s&end_time=%s&answer_time=%s&uuid=%s&source=%s&direction=%s&status=%s&tenant_id=%s&dest_type=%s&duration=%s&billsec=%s&call_rate=%s&recorded=%s&call_recording=%s", 
			caller,callee,start_time,end_time,answer_time,uuid,source,direction,status,tenant_id,dest_type,duration,billsec,rate,recorded,recording);
	c:setopt(curl.OPT_HTTPHEADER, headers);
	c:setopt(curl.OPT_POSTFIELDS, postdata);
	c:setopt(curl.OPT_WRITEFUNCTION, function(str, size)
		data = str;
		length = size;
		return size;
		end
		)

	c:perform();
	self.session:consoleLog('info', 'Loging info mation' );
	self.session:consoleLog('info', data);

end

function CallLog:bridge()
	curl = self.curl;
	json = self.json;
	caller = self.caller;
	callee = self.callee;

	url = string.format("192.168.234.43/api/call/credentials?caller=%s&callee=%s", caller, callee)
	c = curl:easy_init();
	c:setopt(curl.OPT_URL, url);
	headers = {
	  "Accept: application/json",
	  "Accept-Language: en",
	  "Accept-Charset: iso-8859-1,*,utf-8",
	  "Cache-Control: no-cache"
	};
	c:setopt(curl.OPT_HTTPHEADER, headers);
	c:setopt(curl.OPT_WRITEFUNCTION, function(str, size)
		self.data = str;
		self.length = size;
		return size;
		end
		)
	c:perform();

	local data = json.decode(self.data).data;
	local errormsg = json.decode(self.data).errors;
	local number = nil;
	self.session:consoleLog('info', self.data)

	if data ~= nil and errormsg == nil then
		local status = data.status;
	
		if status == 'sip' then
			number = data.extension;
			self:sipCall(number);
			self.session:consoleLog('info', number);	
		elseif status == 'gsm' then
			number = data.seconds;
			self:gsmCall(data.gateway, data.seconds);
			self.session:consoleLog('info', number);	

		end
	else
		self.session:consoleLog('info', 'error')
	end
	-- send the call to sip if it sip

end


function CallLog:CDR(entry)

	local start_time = os.date("%Y-%m-%d %X", entry.start_time);
	local answer_time = os.date("%Y-%m-%d %X", entry.answer_time);
	local end_time = os.date("%Y-%m-%d %X", entry.end_time);
	self.session:consoleLog("info", 'end time: '   .. end_time );	
	self.session:consoleLog("info", 'answer time: '   .. answer_time );	
	local answer_time = os.date("%Y-%m-%d %X", entry.start_time);
	-- answer_time = nil;


	

end

return {
	CallLog = CallLog
}
