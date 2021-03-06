-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

--== special function overrides
--require("spark").init();

--[[
timer.delayOffset = 0;
timer.cached_delay = timer.performWithDelay;
function timer.performWithDelay(delay, listener, iterations)
  if (delay + timer.delayOffset) > 0 then
    delay = delay + timer.delayOffset;
  end
  return timer.cached_delay(delay, listener, iterations);
end

local marked = system.getTimer();

timer.performWithDelay(17, function()
  local now = system.getTimer();
  timer.delayOffset = (now - marked) - 500;
  if (timer.delayOffset < 0) then
    timer.delayOffset = 0;
  end
  print("timer.delayOffset", timer.delayOffset);
  marked = system.getTimer();
end, -1);
--]]

--override print() function to improve performance when running on device
if ( system.getInfo("environment") == "device" ) then
   print = function() end
end

system.setAccelerometerInterval( 20 );

display.setStatusBar(display.HiddenStatusBar);

--require('dispose');
local zip = require( "plugin.zip" );
require("FRC_Modules.FRC_Import.FRC_Import");
require("FRC_Modules.FRC_MultiTouch.FRC_MultiTouch");
require("FRC_Modules.FRC_MultiTouch.FRC_PinchLib");
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_DataLib = require('FRC_Modules.FRC_DataLib.FRC_DataLib');
local FRC_Util = require('FRC_Modules.FRC_Util.FRC_Util');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');

--== APP SETTINGS BEGIN ==--

FRC_AppSettings.init();

-- constants
-- FRC_AppSettings.set("DEBUG_PURCHASES", true); -- need to document more carefully what this does to IAP

-- sets up app for fresh launch experience (title animation and title song)
-- if (not FRC_AppSettings.hasKey("freshLaunch")) then
FRC_AppSettings.set("freshLaunch", true);
-- end

-- == HELP INSTALLION START == --

local function copyFile( srcName, srcPath, dstName, dstPath, overwrite )
  local results = true;               -- assume no errors

  -- Copy the source file to the destination file
  local rfilePath = system.pathForFile( srcName, srcPath );
  local wfilePath = system.pathForFile( dstName, dstPath );

  local rfh = io.open( rfilePath, "rb" );
  local wfh = io.open( wfilePath, "wb" );

  if  not wfh then
    print( "writeFileName open error!" );
    results = false;                 -- error
  else
    -- Read the file from the Resource directory and write it to the destination directory
    local data = rfh:read( "*a" );

    if not data then
      print( "read error!" );
      results = false;     -- error
    else
      if not wfh:write( data ) then
        print( "write error!" );
        results = false; -- error
      end
    end
  end

  -- Clean up our file handles
  rfh:close();
  wfh:close();

  return results;
end

local function helpInstallListener( event )
  local results, reason;
  if ( event.isError ) then
    print( "Error!" );
  else
    print( "event.name: " .. event.name );
    print( "event.type: " .. event.type );
    if ( event.response and type(event.response) == "table" ) then
      for i = 1, #event.response do
        print( event.response[i] )
      end
    end
    --example response
    --event.response = {
    --[1] = "space.jpg",
    --[2] = "space1.jpg",
    --}
    -- remove the Help file now that it has been uncompressed
    results, reason = os.remove( system.pathForFile( "Help.zip", system.DocumentsDirectory ) );

    if results then
      print( "Help file removed." );
    else
      print( "Help file does not exist. Uh oh.", reason );
    end

    -- now explicitly for iOS, we need to disable the iCloud backup of the Help files
    -- to prevent the application submission from getting rejected
    -- we are targeting the entire Help subfolder that we unpacked from the .zip earlier
    results, reason = native.setSync( "Help/", { iCloudBackup = false } );
    if results then
      print( "Help files marked DO NOT BACKUP by iCloud Backup." );
    else
      print( "Help files were NOT marked DO NOT BACKUP by iCloud Backup. Uh oh.", reason );
    end
  end
end

-- install Help files if needed
if (not FRC_AppSettings.get("helpInstalled")) then
  -- copy the .zip file from the system.ResourceDirectory to system.DocumentsDirectory
  if copyFile( "Help.zip", system.ResourceDirectory, "Help.zip", system.DocumentsDirectory ) then
    -- unpack the .zip
    local zipOptions =
    {
        zipFile = "Help.zip",
        zipBaseDir = system.DocumentsDirectory,
        dstBaseDir = system.DocumentsDirectory,
        listener = helpInstallListener
    };
    zip.uncompress( zipOptions );
    -- update the AppSettings
    FRC_AppSettings.set("helpInstalled", true);
  end
end

-- == HELP INSTALLION START == --

--== APP SETTINGS END ==--

_G.ANDROID_DEVICE = (system.getInfo("platformName") == "Android");
_G.NOOK_DEVICE = (system.getInfo("targetAppStore") == "nook");
_G.KINDLE_DEVICE = (system.getInfo("targetAppStore") == "amazon");
if ((_G.NOOK_DEVICE) or (_G.KINDLE_DEVICE)) then
  _G.ANDROID_DEVICE = true;
end

-- perform Google Play licensing check
if system.getInfo("environment") ~= "simulator" then
  if (_G.ANDROID_DEVICE) then
    local licensing = require( "licensing" );
    licensing.init( "google" );

    local function licensingListener( event )

       local verified = event.isVerified;
       if not event.isVerified then
          --failed verify app from the play store, we print a message
          -- print( "Pirates: Walk the Plank!!!" )
          native.showAlert( "Licensing Check Failed!", "There was a problem verifying the application license with Google Play, please try again.", { "OK" } );
          native.requestExit();  --assuming this is how we handle pirates
       end
    end

    licensing.verify( licensingListener );
  end
end

-- Initialize analytics module and log launch event
local analytics = import("analytics");
analytics.init("flurry");
analytics.logEvent("GENULaunch");

local storyboard = require('storyboard');
storyboard.purgeOnSceneChange = true;
storyboard.isDebug = false;

-- initialize ratings module
local FRC_Ratings = import("ratings").init(); -- FRC_Ratings.show() will display "rate" dialog on supported platforms

local function onSystemEvent(event)
  if (event.type == "applicationExit" or event.type == "applicationSuspend") then
    -- saveAppSettings();
  end
  if (not _G.ANDROID_DEVICE and (not system.getInfo("environment") == "simulator")) then return; end
  if (event.type == "applicationSuspend") then
    local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
    if (currentScene and currentScene.suspendHandler) then
      currentScene.suspendHandler();
    end
  elseif (event.type == "applicationResume") then
      local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
      if (currentScene and currentScene.resumeHandler) then currentScene.resumeHandler(); end
  end
end
Runtime:addEventListener("system", onSystemEvent);

-- android back button
if (_G.ANDROID_DEVICE) then
  local function onKeyEvent(event)
    if ( "back" == event.keyName and event.phase == "up" ) then
      local currentScene = storyboard.getScene(storyboard.getCurrentSceneName());
      if (currentScene and currentScene.backHandler) then
        currentScene.backHandler();
      end
      return true;
     end
  end
  Runtime:addEventListener("key", onKeyEvent);
end

--- END APP RATING

---------------------------------------------------------------------------------
-- UNIFY ALL SCENE TRANSITIONS

local cached_gotoScene = storyboard.gotoScene;
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local loader_scene = storyboard.newScene('LoaderScene');
function loader_scene.createScene(self, event)
  local scene = self;
  local view = scene.view;

  local screenW, screenH = FRC_Layout.getScreenDimensions();
  local bg = display.newRect(view, 0, 0, screenW, screenH);
  bg.x = display.contentCenterX;
  bg.y = display.contentCenterY;
  bg:setFillColor(0, 0, 0, 1.0);
  view:insert(bg);
end
function loader_scene.enterScene(self, event)
  local scene = self;
  local view = scene.view;

  storyboard.purgeScene(event.params.nextScene);
  cached_gotoScene(event.params.nextScene, { effect=nil, time=0 });
end
loader_scene:addEventListener('createScene');
loader_scene:addEventListener('enterScene');
storyboard.gotoScene = function(sceneName, options)
  if (not options) then options = {}; end
  if (not options.params) then options.params = {}; end
  options.params.nextScene = sceneName;
  options.effect = nil;
  options.time = 0;

  if (options.useLoader) then
    cached_gotoScene('LoaderScene', options);
  else
    cached_gotoScene(sceneName, options);
  end
end

---------------------------------------------------------------------------------

math.randomseed(os.time());
table.shuffle = function(t)
    local n = #t;

    while n >= 2 do
        -- n is now the last pertinent index
        local k = math.random(n); -- 1 <= k <= n
        -- Quick swap
        t[n], t[k] = t[k], t[n];
        n = n - 1;
    end

    return t;
end

-- reserve channels below SFX_CHANNEL
-- audio.reserveChannels(4); -- FRC_AppSettings.get("SFX_CHANNEL") - 1);

-- set up audio group
local ambientMusic = FRC_AudioManager:newGroup({
  name = "ambientMusic",
  startChannel = FRC_AppSettings.get("AMBIENTMUSIC_CHANNEL"),
  maxChannels = FRC_AppSettings.get("MAX_AMBIENTMUSIC_CHANNELS")
});
ambientMusic:setVolume(0);

-- this sets up the one time only playback of the application intro
FRC_AudioManager:newHandle({
  name = "TitleAudio",
  path = "FRC_Assets/GENU_Assets/Audio/GENU_global_BGMUSIC_Vday_040500288-inspiring-short-version.mp3",
  group = "ambientMusic"
});
-- load up the background tracks for the title screen
FRC_AudioManager:newHandle({
  name = "UofChewTheme1",
  path = "FRC_Assets/GENU_Assets/Audio/GENU_global_BGMUSIC_Vday_000842106-easy-beat-loopable.mp3",
  group = "ambientMusic"
});
FRC_AudioManager:newHandle({
  name = "UofChewTheme2",
  path = "FRC_Assets/GENU_Assets/Audio/GENU_global_BGMUSIC_Vday_041919335-inspirational-elegant-minimal.mp3",
  group = "ambientMusic"
});

-- set volumes based on previous settings
--[[ if (FRC_AppSettings.get("ambientSoundOn")) then
  -- FRC_AudioManager:findGroup("intro"):setVolume(1.0);
  FRC_AudioManager:findGroup("ambientMusic"):setVolume(1.0);
else
  -- FRC_AudioManager:findGroup("intro"):setVolume(0);
  FRC_AudioManager:findGroup("ambientMusic"):setVolume(0);
end
--]]

-- subscene storybook text display by default
_G.storybookTextContainerDisplayMode = "subscene";

display.setDefault('background', 0.004, 0.196, 0.125, 1.0); -- 0, 0, 0, 1.0);
display.setDefault( "textureWrapX", "clampToEdge" );
display.setDefault( "textureWrapY", "clampToEdge" );
math.randomseed( os.time() );  -- make math.random() more random

storyboard.gotoScene('Scenes.Splash');
