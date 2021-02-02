local curl = require 'curl';
local json = require 'json';

SignagePlayer = {data = nil, length = nil, default=nil, schd =nil, currentPlaylist=nil, curl=curl, nxtu=nil, json=json, lastHash=nil, currentHash=nil }

function SignagePlayer:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function SignagePlayer:play()
	os.execute('killall -9 mpg123');
	os.execute('nohup mpg123 -Z@ /home/telvida/playlist > /dev/null 2>&1 &');
	if self.nxtu <= os.time() then

		self.nxtu = os.time() + 60;

	end;
	
end

function SignagePlayer:init()

	os.execute('touch /home/telvida/playlist');
	os.execute('touch /home/telvida/playlog');
	os.execute('echo "" > /home/telvida/playlist');
	os.execute(string.format('echo "%s start playing" > /home/telvida/playlog', os.date() ));

	self:loopstart();

end

function SignagePlayer:loopstart(  )
	local ti = os.time();

	if self.default == nil and self.nxtu == nil and self.currentPlaylist == nil then
		self:getData()
		local s = self.json.decode(self.data).schd;
		self.nxtu = self:timestamp(self.json.decode(self.data).nxtu);
		self.currentHash = self.json.decode(self.data).hash;
		for i=1, #s do
			if s[i].dflt == 1 then

				self.default = s[i];

			else 
			
				self.schd = s[i];

			end

		end

		if self.currentHash ~= self.lastHash then
			self:makePlaylist();
			self:play();
		end
		os.execute(string.format('echo "%s current timestamp ----  %s next timestamp -- playing %s \n" >> /home/telvida/playlog', os.time(), self.nxtu, self.currentPlaylist) );
		sleep_time = os.difftime(tonumber(self.nxtu) - os.time() -10);
		os.execute('sleep '.. sleep_time);
	end

	if self.nxtu ~= nil and self.nxtu >= ti and self.nxtu <= ti+2 then

		self:getData()
		local s = self.json.decode(self.data).schd;
		self.nxtu = self:timestamp(self.json.decode(self.data).nxtu);
		self.currentHash = self.json.decode(self.data).hash;
		for i=1, #s do
			if s[i].dflt == 1 then

				self.default = s[i];

			else 
			
				self.schd = s[i];

			end

		end
		if self.currentHash ~= self.lastHash then
			self:makePlaylist();
			self:play();
		end
		os.execute(string.format('echo "%s current timestamp ----  %s next timestamp -- playing %s \n" >> /home/telvida/playlog', os.time(), self.nxtu, self.currentPlaylist) );
		sleep_time = os.difftime(tonumber(self.nxtu) - os.time() -10);
		os.execute('sleep '.. sleep_time);
		
	end
	if self.nxtu <= os.time() then

		self.nxtu = os.time() + 60;

	end;
	
	os.execute('sleep 2');
	self:loopstart();

end

function SignagePlayer:getData( )
	c = curl:easy_init();
	c:setopt(curl.OPT_URL, 'http://127.0.0.1/signageApi/public/update-content');
	c:setopt(curl.OPT_WRITEFUNCTION, function(str, size)
		self.data = str;
		self.length = size;
		return size;
		end
		)
	c:perform();

end

function SignagePlayer:timestamp(nxtu)
	b = nxtu:gsub('(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)', function(a,b,c,d,e,f)
		return os.time{year=a,month=b,day=c,hour=d,min=e,sec=f}
	end)
	return tonumber(b);
end

function SignagePlayer:makePlaylist()
	if self.schd ~= nil and self.schd.hash == self.currentHash then
		if self:timestamp(self.schd.start_time) <= os.time() and self:timestamp(self.schd.end_time) > os.time() then
			os.execute('echo "" > /home/telvida/playlist');

			for i=1, #self.schd.cont do
				os.execute(string.format("echo %s >> /home/telvida/playlist", self.schd.cont[i]))
			end
			self.schd = nil;
			self.currentPlaylist = 'schedule';
			os.execute('echo "making schedule" >> /home/telvida/playlog');
		end
	elseif self.default ~= nil and self.default.hash == self.currentHash then
		os.execute('echo "" > /home/telvida/playlist');

		for i=1, #self.default.cont do
			os.execute(string.format("echo %s >> /home/telvida/playlist", self.default.cont[i]))
		end
		os.execute('echo "making default" >> /home/telvida/playlog');

		self.currentPlaylist = 'default';
	else
		os.execute('echo "" > /home/telvida/playlist');
		self.currentPlaylist = 'empty';
	end

	self.lastHash = self.currentHash;
	os.execute(string.format('echo "%s -- play  %s" >> /home/telvida/playlog', os.date(), self.currentPlaylist));

end

local signage = SignagePlayer:new{}
signage:init();