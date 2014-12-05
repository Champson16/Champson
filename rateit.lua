local R = {}

local AppleURL;
local AndroidURL;
local iOS7URL;
 
local setiTunesURL = function (id)
  AppleURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa"
  iOS7URL = 'itms-apps://itunes.apple.com/app/id' .. id .. '?onlyLatestVersion=false';
  AppleURL = AppleURL .. "/wa/viewContentsUserReviews?"
  AppleURL = AppleURL .. "type=Purple+Software&id="
  AppleURL = AppleURL .. id
end
 
R.setiTunesURL = setiTunesURL;
 
local setAndroidURL = function (id)
  AndroidURL = "market://details?id="
  AndroidURL = AndroidURL .. id
end
 
R.setAndroidURL = setAndroidURL
 
local openURL = function ()
  local platform = system.getInfo("platformName")

  if platform == "Android" then
    system.openURL(AndroidURL)
  else
    -- iOS 7 uses a different URl for app ratings, so detect major
    -- platform version number on iOS before proceeding
    if (tonumber(system.getInfo("platformVersion").sub(1, 1)) >= 7) then
      system.openURL(iOS7URL);
    else
      system.openURL(AppleURL);
    end
  end
end
 
R.openURL = openURL
 
return R