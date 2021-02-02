package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]
local DB = require "DatabaseConnection"
local json = require "json"
 
local DatabaseConnection = DB.DatabaseConnection

local db = DatabaseConnection:new{}
local con = db:connect()

local CDR = {tenant_id=nil,uuid=nil,caller_id_name=nil, caller_id_num=nil,direction=nil,callee_id_num=nil,dest=nil,dest_type=nil,status=nil,duration=nil,start_time=nil,answer_time=nil,end_time=nil}
function CDR:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

LocalMobile = { session = nil, context = nil, callee = nil, caller = nil, con = con, db = db, gateway = "shola_gateway", start_time=nil,tenant_id=nil }

function LocalMobile:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end


function LocalMobile:bridgeEndpoint()
	local cdr = CDR:new{tenant_id=self.tenant_id,start_time=self.start_time,caller_id_num=self.session:getVariable('effective_caller_id_number'),
		direction='outbound', uuid=self.session:getVariable('uuid'), dest=self.callee, dest_type='mobile',
	};	
	cur, errorString = self.con:execute(string.format("select * from extensions where exten_reg='%s' and context='%s' limit 1", self.caller, self.context))
	self.session:consoleLog('info', string.format("select * from extensions where exten_reg='%s' and context='%s' limit 1", self.caller, self.context))
	if errorString then
		self.session:execute("answer")
		self.session:set_tts_params("flite", "slt");
		self.session:speak("The number you have call is not available");
		cdr.status = 'Unreachable';
		self.session:hangup("UNALLOCATED_NUMBER")
		self:CDR(cdr);
		
	elseif cur then
	
		destination = cur:fetch({}, "a")
		
		if destination ~= nil then

			if destination then



				self.session:setVariable("sip_h_X-A-Number", '07001237000');
				self.session:setVariable("caller_id_number", '07001237000');
				self.session:setVariable("sip_h_X-Primary-DID", '07001237000');
				self.session:setVariable("ani", '07001237000');
				-- self.session:setVariable("sip_h_X-Secondary-DID", destination.secondary_outbound_did);
				self.session:consoleLog("info", 'let me know if you are using this dialplan '   .. '07001237000' )
				self:bridgeExten()
				self.session:consoleLog("info", 'primary DID: '   .. '07001237000' )
				cdr.status = self.session:getVariable('state');
				cdr.answer_time = self.session:getVariable('answered_time');
				cdr.end_time = self.session:getVariable('hangup_time');
				self:CDR(cdr);


			else
				self.session:execute("answer")
				self.session:set_tts_params("flite", "slt");
				self.session:speak("You are not Allowed to dial this number. Thank you.");
				cdr.status = 'Non Allowed';
				self.session:hangup("UNALLOCATED_NUMBER")
				self:CDR(cdr);

			end

		else

			self.session:execute("answer")
			self.session:set_tts_params("flite", "slt");
			self.session:speak("The number you have call is not available");
			cdr.status = 'Unreachable';
			self:CDR(cdr);

		end
		cur:close()
	end

end

function LocalMobile:bridgeExten()

	-- self.session:execute("bridge", string.format("sofia/gateway/%s/%s", self.gateway, self.callee));
	self.session:consoleLog("info", 'let me know your gateway '   .. self.gateway )
	self.session:execute("bridge", string.format("sofia/gateway/shola_gateway/%s", self.callee));

end

function LocalMobile:CDR(entry)

	local start_time = os.date("%Y-%m-%d %X", entry.start_time);
	local answer_time = os.date("%Y-%m-%d %X", entry.answer_time);
	local end_time = os.date("%Y-%m-%d %X", entry.end_time);
	self.session:consoleLog("info", 'end time: '   .. end_time );	
	self.session:consoleLog("info", 'answer time: '   .. answer_time );	


	self.con:execute(string.format([[INSERT INTO cdrs (tenant_id, uuid, caller_num, caller_name, direction, callee_num, destination, destination_type, 
		status, duration, start_time, answer_time, end_time) 
		VALUES ('%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s') 
		]], entry.tenant_id, entry.uuid, entry.caller_id_num, entry.caller_id_name, entry.direction,
		 entry.callee_id_num, entry.dest, entry.dest_type, entry.status, 
		 entry.duration, start_time, answer_time, end_time));

end


start_time = os.time()
local localExten = LocalMobile:new{session = session, caller=argv[1], callee=argv[2], context=argv[3], tenant_id=argv[4],start_time=os.time(), }
localExten:bridgeEndpoint()
end_time = os.time()
elapsed_time = os.difftime(end_time-start_time)
db:close()
-- session:consoleLog("info", 'start time: '   .. start_time )
-- session:consoleLog("info", 'end time: '     .. end_time )
session:consoleLog("info", 'time elapsed: ' .. elapsed_time )
