local version = "1.0.0";

--[[==============================================================
USAGE:

local platform = require("FRC_Modules.FRC_Platform.FRC_Platform");
print(platform.detected);

Possible values for platform.detected:

- apple
- google
- nook
- amazon
- tabeo
- samsung

In the Corona Simulator, platform.detected will be the same
value as module.debugPlatform (defaults to "apple")

module.androidPlatform is `true` for any android-based platform.
==============================================================]]--

local module = {};
module.debugPlatform = "apple";
module.androidPlatform = false;
module.debugMode = false;

if (system.getInfo("environment") == "simulator") then
	module.detected = module.debugPlatform;
	module.debugMode = true;
	return module;
end

local devicePlatformName = system.getInfo("platformName");
if (devicePlatformName == "iPhone OS") then
	module.detected = "apple";
	module.androidPlatform = false;
elseif (devicePlatformName == "WinPhone") then
	module.detected = "windows";
	module.androidPlatform = false;
else
	local deviceTargetAppStore = system.getInfo("targetAppStore");
	if (deviceTargetAppStore == "nook") then
		module.detected = "nook";
		module.androidPlatform = true;
	elseif (deviceTargetAppStore == "amazon") then
		module.detected = "amazon";
		module.androidPlatform = true;
	elseif (deviceTargetAppStore == "samsung") then
		module.detected = "samsung";
		module.androidPlatform = true;
	elseif (devicePlatformName == "Android") then
		-- check for Tabeo device
		if (string.find(system.getInfo("model"), "TABEO")) then
			module.detected = "tabeo";
		else
			module.detected = "google";
		end
		module.androidPlatform = true;
	else
		module.detected = detected;
	end
end

-- DEBUG
-- native.showAlert("Platform Test", "Current platform is: " .. module.detected, { "OK" }); --  .. " AND androidPlatform is: " .. module.androidPlatform);

return module;
