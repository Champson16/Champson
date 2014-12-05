local AudioHandle = {};

local AudioManager = require("FRC_Modules.FRC_AudioManager.FRC_AudioManager");
local AudioGroup = require("FRC_Modules.FRC_AudioManager.FRC_AudioGroup");

local function throw(errorMessage)
	error("[" .. AudioManager.name .. " ERROR]: " .. errorMessage);
end

local function warn(warnMessage)
	print("[" .. AudioManager.name .. " WARNING]: " .. warnMessage);
end

local public = {};

function public:play(options)
	options = options or {};
	local cached_onComplete = options.onComplete;
	options.onComplete = function(event)
		if (event.completed) then
			self.channel = nil;
		end
		if (cached_onComplete) then
			cached_onComplete(event);
		end
	end

	-- this allows us to require a delay before queuing in the sound
	local startDelay = options.startDelay or 0;

	if (self.group) then
		local channel;
		if (self.channel and options.force) then
			channel = self.channel;
			self:stop();
		else
			channel = self.group:findFreeChannel();
		end

		if (channel) then
			options.channel = channel;
			local playChannel;
			self.currentTimer = timer.performWithDelay(startDelay, function()
				pcall(function() playChannel = audio.play(self.handle, options); end);
				if (playChannel and playChannel ~= 0) then
					self.channel = playChannel;
				end
			end, 1);

			-- append channel to end of group's channel array (so group.channels[1] is always least recently used)
			local removeCount = 0;
			for i=#self.group.channels,1,-1 do
				if (self.group.channels[i] == channel) then
					table.remove(self.group.channels, i);
					removeCount = removeCount + 1;
				end
			end
			if (removeCount > 0) then
				table.insert(self.group.channels, channel);
			end
		else
			-- something wrong happened - completely out of audio channels probably
		end
	else
		-- instance does not belong to a group; treat it as a raw call to audio.play()
		local playChannel;
		self.currentTimer = timer.performWithDelay(startDelay, function()
			pcall(function() playChannel = audio.play(self.handle, options); end);
			if (playChannel and playChannel ~= 0) then
				self.channel = playChannel;
			end
		end, 1);
	end
	return self.channel or 0;
end

function public:isPlaying()
	local result = false;
	if (self.channel) then
		result = true;
	end
	return result;
end

function public:stop(options)
	options = options or {};
	-- shut down any timer
	if self.currentTimer then
		timer.cancel(self.currentTimer);
		self.currentTimer = nil;
	end
	if (self.channel) then
		if (options.delay) then
			pcall(function() audio.stopWithDelay(options.delay, { channel = self.channel }); end);
		else
			pcall(function() audio.stop(self.channel); end);
		end
		self.channel = nil;
	end
	return self;
end

function public:pause()
	if (self.channel) then
		pcall(function() audio.pause(self.channel); end);
	end
	if (self.currentTimer) then
		pcall(function() timer.pause(self.currentTimer); end);
	end
	return self;
end

function public:resume()
	if (self.channel) then
		pcall(function() audio.resume(self.channel); end);
	end
	if (self.currentTimer) then
		pcall(function() timer.resume(self.currentTimer); end);
	end
	return self;
end

function public:getChannel()
	return self.channel;
end

function public:getDuration()
	local duration = 0;
	pcall(function() duration = audio.getDuration(self.handle); end);
	return duration;
end

function public:getVolume()
	local volume = nil;
	pcall(function() volume = audio.getVolume(self.channel); end);
	return volume;
end

function public:setVolume(volume)
	pcall(function() audio.setVolume(volume, {channel = self.channel}); end);
	return self;
end

function public:dispose()
	self:stop();
	-- shut down any timer
	if self.currentTimer then
		timer.cancel(self.currentTimer);
		self.currentTimer = nil;
	end
	-- if the handle is part of a group, we need to remove it from the group first
	if self.group then
		if self.group:findHandle(self) then
			-- remove it
			-- DEBUG:
			print("AudioHandle:dispose is now removing the handle: ", self.name, " from the group: ", self.group);
			self.group:removeHandle(self);
		end
		self.group = nil;
	end
	self.name = nil;
	self.path = nil;
	pcall(function() audio.dispose(self.handle); end);
	self.handle = nil;
end

function AudioHandle.new(options)
	options = options or {};
	-- valid options are: name (string), path (string), useLoadSound (boolean), group (group object or string)
	if (options.name) then
		if (AudioManager:isHandleNameTaken(options.name)) then
			local chosenName = options.name;
			options.name = AudioManager:getUniqueHandleName();
			warn("AudioHandle name " .. chosenName .. " is already in use; using unique name: " .. options.name);
		end
	end

	if (not options.path) then throw("You must specify a [path] option when instantiating a new AudioHandle."); end
	local audioHandle = {};
	if (options.useLoadSound) then
		audioHandle.handle = audio.loadSound(options.path);
	else
		audioHandle.handle = audio.loadStream(options.path);
	end
	audioHandle.name = options.name or AudioManager:getUniqueHandleName();
	audioHandle.path = options.path;

	-- add all public instance methods
	for k,v in pairs(public) do
		audioHandle[k] = v;
	end

	-- options.group can either be a group name (string) or an AudioGroup instance
	if (options.group) then
		local group;
		if (type(options.group) == "string") then
			group = AudioManager:findGroup(options.group);
		else
			group = options.group;
		end
		if (group) then
			group:addHandle(audioHandle);
		end
	end

	return audioHandle;
end

return AudioHandle;
