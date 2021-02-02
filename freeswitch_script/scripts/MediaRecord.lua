package.path = package.path .. ";" .. [[/usr/local/freeswitch/scripts/?.lua]]
local DB = require "DatabaseConnection"
local json = require "json"
 
local DatabaseConnection = DB.DatabaseConnection

local db = DatabaseConnection:new{}
local con = db:connect()

MediaRecord = { session = nil, context = nil, callee = nil, caller = nil, con = con, db = db, gateway = "9mobile_gateway" }

function MediaRecord:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end


function MediaRecord:bridgeEndpoint()
	
	self.session:answer()
	local pin_attempt = 1
	local pin_max_attempt = 3

	while pin_attempt <= pin_max_attempt do

		self.session:set_tts_params("flite", "slt");
		self.session:speak("Please Enter Your Voice Code Number ...")
		-- self.session:sleep(10000)
		
		digits = self.session:getDigits(4, "", 5000);


		if digits then

			cur, errorString = self.con:execute(string.format("select * from play_media where source='record' and voice_code='%s' and tenant_id=%d limit 1", digits, self.context))
			if errorString then
				
				self.session:hangup("UNALLOCATED_NUMBER")
				
			elseif cur then
		
				destination = cur:fetch({}, "a")

				if destination ~= nil then

					self.session:consoleLog("info", 'destination: ' ..  destination.source )
					self.session:consoleLog("info", 'exist: ' ..  destination.exist )
					if ((tonumber(destination.exist) == 0 ) or (destination.exist == 'f')) then
						-- record a message
						
						date = os.date("%b-%y")
						name = string.format("COM_%s/record/%s/r%s_%s.wav",destination.code, date, tonumber(os.time()), math.random(10000, 99999))
						os.execute(string.format("mkdir -pm 777 /var/cloudpbx/COM_%s/record/%s",destination.code, date))
						
						filename =  string.format("/var/cloudpbx/%s", name )
						self.session:set_tts_params("flite", "slt");
						self.session:speak("Start Recording Now ...")
						self.session:sleep(1000) 
						self.session:recordFile(filename,300,100,10) 
						self.session:hangup()
						os.execute("chmod -Rf 777 /var/cloudpbx")

						self.session:consoleLog("info", 'before update: '  )
						self.con:execute(string.format("update play_media set mime_type='%s', path='%s', category='%s' where voice_code='%s' and code='%s' ", 'audio/mpeg', name, 'audio', destination.voice_code, destination.code))
						self.session:consoleLog("info", 'after update: '  )
						
					else

						-- play back the recorded msg 
						-- session:streamFile(filename) 

					end
					
				else
					self.session:speak("Invalid Voice Code Number ...")

					self.session:hangup("UNALLOCATED_NUMBER")

				end

				cur:close()

			end

		end
		
		pin_attempt = pin_attempt + 1


	end

end



local localExten = MediaRecord:new{session = session, caller=argv[1], context=argv[2] }
localExten:bridgeEndpoint()
db:close()