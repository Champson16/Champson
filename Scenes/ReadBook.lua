local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local bookparser = require('FRC_Modules.FRC_BookParser.FRC_BookParser')
local storyboard = require('storyboard');
local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');

local physics = require('physics');

local scene = storyboard.newScene();

-- this is a temporary solution to minimize the hard coding in this module to support a specific book
-- TODO:  Create a JSON config file for these values
local bookJSONPath = 'FRC_Assets/GENU_Assets/Book/thechocolatechihuahua/bookdata.json';

local animationSequences = {};
local animationXMLBase = 'FRC_Assets/GENU_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/GENU_Assets/Animation/Images/';


function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';

	local transArray = {};

	local swingButtonLeft, swingButtonRight;

	local removeControls, dropControls;

	scene.floor = display.newRect( display.contentCenterX, display.contentHeight, display.contentWidth, 10 );
	scene.floor.fill = { 0,0,0,0 };


	function swingButtonLeft( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1000, rotation = 15, onComplete = function() swingButtonRight( button ) end } )
	end

	function swingButtonRight( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1000, rotation = -15, onComplete = function() swingButtonLeft( button ) end } )
	end

	local bg = display.newGroup();
	bg.anchorChildren = true;
	bg.anchorX = 0.5;
	bg.anchorY = 0.5;

	local bgImage = display.newImageRect(animationImageBase .. 'GENU_Home_LandingPage_Background.png', 1152, 768);
	bg:insert(bgImage);
	FRC_Layout.scaleToFit(bgImage);
	bgImage.x, bgImage.y = 0, 0;

	--[[ -- setup the logo
	local bgLogo = display.newImageRect(animationImageBase .. 'GENU_Home_LandingPage_Logo.png', 1152, 768);
	bgLogo.x = display.contentCenterX; -- -(display.contentWidth/2) + bgLogo.width;
	bgLogo.y = display.contentCenterY - 200;
	bgLogo.xScale = 0.35;
	bgLogo.yScale = 0.35;


	bg:insert(bgLogo);

	--]]

	-- setup the book cover image
	local bgBookImage = display.newImageRect(animationImageBase .. 'A-New-Home-for-Charlie-title.png', 1281, 131);
	bg:insert(bgBookImage);
	bgBookImage.alpha = 0;
	FRC_Layout.scaleToFit(bgBookImage);
	bgBookImage.x = display.contentCenterX;
	bgBookImage.y = display.contentCenterY - 170;
	bgBookImage.xScale = 0.75;
	bgBookImage.yScale = 0.75;

	transArray[ #transArray + 1 ] = transition.to( bgBookImage, { delay = 0, time = 1000, alpha = 1, transition = easing.inOutQuad});

-- position at top center above buttons

	bg.xScale = screenW / display.contentWidth;
	bg.yScale = bg.xScale;

	-- position background image at correct location
	bgImage.x = display.contentCenterX;
	bgImage.y = display.contentCenterY;
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	view:insert(bg);

	local readToMeButton, readToMyselfButton, watchAnimationButton, playActivitiesButton;

	local function stopPhysics()
		-- remove the physics so we can control the objects again
		physics.removeBody(scene.floor);
		physics.removeBody(scene.readToMeButton);
		physics.removeBody(scene.readToMyselfButton);
		physics.removeBody(scene.watchAnimationButton);
		-- physics.removeBody(scene.watchNarratedStoryButton);
		physics.removeBody(scene.playActivitiesButton);

		-- remove the physics objects
		if (scene.floor) then scene.floor:removeSelf(); end
		if (scene.readToMeButton) then scene.readToMeButton:removeSelf(); end
		if (scene.readToMyselfButton) then scene.readToMyselfButton:removeSelf(); end
		if (scene.watchAnimationButton) then scene.watchAnimationButton:removeSelf(); end
		if (scene.playActivitiesButton) then scene.playActivitiesButton:removeSelf(); end

		physics.stop();

	end

	local function dropControls(selectedControl)
		-- DEBUG:
		print("DROPPING CONTROLS!");
		-- put the selectedControl in front of the other items
	  if (selectedControl) then
			selectedControl:toFront();
			selectedControl.onReleaseActive = true;
		end
		-- animate the selectedControl to the middle
		transArray[#transArray + 1] = transition.to( selectedControl, { time = 1500, x = display.contentCenterX, y = display.contentCenterY, alpha = 0, xScale = 2, yScale = 2, transition = easing.inOutQuad });
		physics.setGravity(0, math.random(50,100));
		if (selectedControl ~= readToMeButton) then
			-- remove transition
			transition.cancel(readToMeButton);
			physics.addBody(readToMeButton, "dynamic", {density = math.random(2.0,4.0), friction = 0.5, bounce = 0.5});
		end
		if (selectedControl ~= readToMyselfButton) then
			-- remove transition
			transition.cancel(readToMyselfButton);
			physics.addBody(readToMyselfButton, "dynamic", {density = math.random(2.0,4.0), friction = 0.5, bounce = 0.5});
		end
		if (selectedControl ~= watchAnimationButton) then
			-- remove transition
			transition.cancel(watchAnimationButton);
			physics.addBody(watchAnimationButton, "dynamic", {density = math.random(2.0,4.0), friction = 0.5, bounce = 0.5});
		end
		--[[if (selectedControl ~= watchNarratedStoryButton) then
			-- remove transition
			transition.cancel(watchNarratedStoryButton);
			physics.addBody(watchNarratedStoryButton, "dynamic", {density = math.random(2.0,4.0), friction = 0.5, bounce = 0.5});
		end--]]
		if (selectedControl ~= playActivitiesButton) then
			-- remove transition
			transition.cancel(playActivitiesButton);
			physics.addBody(playActivitiesButton, "dynamic", {density = math.random(2.0,4.0), friction = 0.5, bounce = 0.5});
		end
	end

	-- add a little animation

	-- setup array of animation sequences
	local titleAnimationFiles = {
	"GENU_Title_Intro_a.xml"
	};
	-- preload the animation data (XML and images) early
	titleAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(titleAnimationFiles, animationXMLBase, animationImageBase);
	view:insert(titleAnimationSequences);
	FRC_Layout.scaleToFit(titleAnimationSequences);

	local ambientAnimationFiles = {
	"GENU_Title_Ambient_a.xml"
	};

	-- preload the animation data (XML and images) early
	ambientAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(ambientAnimationFiles, animationXMLBase, animationImageBase);
	view:insert(ambientAnimationSequences);
	FRC_Layout.scaleToFit(ambientAnimationSequences);

	readToMeButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_ReadToMe_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_ReadToMe_down.png',
		width = 240,
		height = 120,
		x = display.contentCenterX - 200,
		y = display.contentCenterY + 50,
		onRelease = function()
			-- prevent multiple taps at once
			if readToMeButton.onReleaseActive then return; end
			-- set up the switches as needed
			FRC_AppSettings.set("storybookAutoPlay", false);
			FRC_AppSettings.set("storybookAutoFastForward", false);
			FRC_AppSettings.set("storybookPawsForThought", true);
			FRC_AppSettings.set("storybookTouchpointActivity", false);
			FRC_AppSettings.set("storybookTextDisplay", true);
			FRC_AppSettings.set("storybookSoundNarratorOn", true);
			FRC_AppSettings.set("storybookSoundEffectsOn", true);
			FRC_AppSettings.set("storybookSoundBackgroundOn", true);
			-- turn music off by default
			if FRC_AudioManager:findGroup("ambientMusic") then
				FRC_AudioManager:findGroup("ambientMusic"):pause();
			end
			-- transition off the controls
			-- removeControls();
			dropControls(readToMeButton);
			-- startup the book parser
			timer.performWithDelay(2000, function()
				stopPhysics()
				bookparser.parse(bookJSONPath,'001');
				end, 1);
		end
	});
	readToMeButton.alpha = 0;
	bg:insert(readToMeButton);
	transArray[ #transArray + 1] = transition.to( readToMeButton, { time = 750, alpha = 1, onComplete = function() timer.performWithDelay(math.random(1,1000), function() swingButtonLeft(readToMeButton); end, 1); end } );
	scene.readToMeButton = readToMeButton;

	readToMyselfButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_ReadToMyself_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_ReadToMyself_down.png',
		width = 240,
		height = 120,
		x = display.contentCenterX - 125,
		y = display.contentCenterY + 200,
		onRelease = function()
			-- prevent multiple taps at once
			if readToMyselfButton.onReleaseActive then return; end
			-- set up the switches as needed
			FRC_AppSettings.set("storybookAutoPlay", false);
			FRC_AppSettings.set("storybookAutoFastForward", false);
			FRC_AppSettings.set("storybookPawsForThought", true);
			FRC_AppSettings.set("storybookTouchpointActivity", true);
			FRC_AppSettings.set("storybookTextDisplay", true);
			FRC_AppSettings.set("storybookSoundNarratorOn", false);
			FRC_AppSettings.set("storybookSoundEffectsOn", true);
			FRC_AppSettings.set("storybookSoundBackgroundOn", true);
			-- turn music off by default
			if FRC_AudioManager:findGroup("ambientMusic") then
				FRC_AudioManager:findGroup("ambientMusic"):pause();
			end
			-- transition off the controls
			dropControls(readToMyselfButton);
			-- removeControls();
			-- startup the book parser
			timer.performWithDelay(2000, function()
				stopPhysics()
				bookparser.parse(bookJSONPath,'001');
				end, 1);
		end
	});
	readToMyselfButton.alpha = 0;
	bg:insert(readToMyselfButton);
	transArray[ #transArray + 1] = transition.to( readToMyselfButton, { time = 750, alpha = 1, onComplete = function() timer.performWithDelay(math.random(1,1000), function() swingButtonRight(readToMyselfButton); end, 1); end } );
	scene.readToMyselfButton = readToMyselfButton;

	watchAnimationButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Watch_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Watch_down.png',
		width = 240,
		height = 120,
		x = display.contentCenterX + 125,
		y = display.contentCenterY + 50,
		onRelease = function()
			-- prevent multiple taps at once
			if watchAnimationButton.onReleaseActive then return; end
			-- set up the switches as needed
			FRC_AppSettings.set("storybookAutoPlay", true);
			FRC_AppSettings.set("storybookAutoFastForward", false);
			FRC_AppSettings.set("storybookPawsForThought", false);
			FRC_AppSettings.set("storybookTouchpointActivity", false);
			FRC_AppSettings.set("storybookTextDisplay", false);
			FRC_AppSettings.set("storybookSoundNarratorOn", true);
			FRC_AppSettings.set("storybookSoundEffectsOn", true);
			FRC_AppSettings.set("storybookSoundBackgroundOn", true);
			-- turn music off by default
			if FRC_AudioManager:findGroup("ambientMusic") then
				FRC_AudioManager:findGroup("ambientMusic"):pause();
			end
			-- transition off the controls
			dropControls(watchAnimationButton);
			-- removeControls();
			-- startup the book parser
			timer.performWithDelay(2000, function()
				stopPhysics()
				bookparser.parse(bookJSONPath,'001');
				end, 1);
		end
	});
	watchAnimationButton.alpha = 0;
	bg:insert(watchAnimationButton);
	transArray[ #transArray + 1] = transition.to( watchAnimationButton, { time = 750, alpha = 1, onComplete = function() timer.performWithDelay(math.random(1,1000), function() swingButtonRight(watchAnimationButton); end, 1); end } );
	scene.watchAnimationButton = watchAnimationButton;

	playActivitiesButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_PlayBook_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_PlayBook_down.png',
		width = 240,
		height = 120,
		x = display.contentCenterX + 200,
		y = display.contentCenterY + 200,
		onRelease = function()
			-- prevent multiple taps at once
			if playActivitiesButton.onReleaseActive then return; end
			-- set up the switches as needed
			FRC_AppSettings.set("storybookAutoPlay", false);
			FRC_AppSettings.set("storybookAutoFastForward", true);
			FRC_AppSettings.set("storybookPawsForThought", false);
			FRC_AppSettings.set("storybookTouchpointActivity", true);
			FRC_AppSettings.set("storybookTextDisplay", false);
			FRC_AppSettings.set("storybookSoundNarratorOn", false);
			FRC_AppSettings.set("storybookSoundEffectsOn", true);
			FRC_AppSettings.set("storybookSoundBackgroundOn", true);
			-- turn music off by default
			if FRC_AudioManager:findGroup("ambientMusic") then
				FRC_AudioManager:findGroup("ambientMusic"):pause();
			end
			-- transition off the controls
			dropControls(playActivitiesButton);
			-- removeControls();
			-- startup the book parser
			timer.performWithDelay(2000, function()
				stopPhysics()
				bookparser.parse(bookJSONPath,'001');
				end, 1);
		end
	});
	playActivitiesButton.alpha = 0;
	bg:insert(playActivitiesButton);
	transArray[ #transArray + 1] = transition.to( playActivitiesButton, { time = 750, alpha = 1, onComplete = function() timer.performWithDelay(math.random(1,1000), function() swingButtonLeft(playActivitiesButton); end, 1); end } );
	scene.playActivitiesButton = playActivitiesButton;

	local function removeControls(self)
		local transArray = {};
		transArray[ #transArray + 1 ] = transition.to( readToMeButton, { time = 500, y = display.contentCenterY + 460, alpha = 0, transition = easing.inOutQuad });
		transArray[ #transArray + 1 ] = transition.to( readToMyselfButton, { time = 500, y = display.contentCenterY + 460, alpha = 0, transition = easing.inOutQuad });
		transArray[ #transArray + 1 ] = transition.to( watchAnimationButton, { time = 500, y = display.contentCenterY + 460, alpha = 0, transition = easing.inOutQuad });
		-- transArray[ #transArray + 1 ] = transition.to( watchNarratedStoryButton, { time = 500, y = display.contentCenterY + 460, alpha = 0, transition = easing.inOutQuad });
		transArray[ #transArray + 1 ] = transition.to( playActivitiesButton, { time = 500, y = display.contentCenterY + 460, alpha = 0, transition = easing.inOutQuad });
	end

	local function goHome()
		dropControls();
		-- removeControls();
		timer.performWithDelay(2000, function()
			stopPhysics();
			storyboard.gotoScene('Scenes.Home', { effect="crossFade", time="250" });
			end,
		1);
	end
	scene.backHandler = goHome;

	-- create action bar menu at top left corner of screen
	scene.actionBarMenu = FRC_ActionBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_up.png',
		imageDown = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_down.png',
		focusState = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_focused.png',
		disabled = 'FRC_Assets/FRC_ActionBar/Images/GENU_ActionBar_global_Button_ActionBar_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 15,
alwaysVisible = true,
		bgColor = { 1, 1, 1, .95 },
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Home_down.png',
				onRelease = function()
					goHome();
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
				onRelease = function()
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);

					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					local devicePlatformName = import("platform").detected;
					webView:request("http://fatredcouch.com/page.php?t=products&p=" .. devicePlatformName);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf(); closeButton = nil;
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			},
			{
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Help_down.png',
				onRelease = function()
					local screenRect = display.newRect(0, 0, screenW, screenH);
					screenRect.x = display.contentCenterX;
					screenRect.y = display.contentCenterY;
					screenRect:setFillColor(0, 0, 0, 0.75);
					screenRect:addEventListener('touch', function() return true; end);
					screenRect:addEventListener('tap', function() return true; end);
					local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
					webView.x = display.contentCenterX;
					webView.y = display.contentCenterY + 20;
					webView:request("Help/GENU_FRC_WebOverlay_Help_ReadBooks.html", system.DocumentsDirectory);

					local closeButton = ui.button.new({
						imageUp = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						imageDown = imageBase .. 'GENU_Home_global_LandingPage_CloseButton.png',
						width = 50,
						height = 50,
						onRelease = function(event)
							local self = event.target;
							webView:removeSelf(); webView = nil;
							self:removeSelf();
							screenRect:removeSelf(); screenRect = nil;
						end
					});
					closeButton.x = 5 + (closeButton.contentWidth * 0.5) - ((screenW - display.contentWidth) * 0.5);
					closeButton.y = 5 + (closeButton.contentHeight * 0.5) - ((screenH - display.contentHeight) * 0.5);
					webView.closeButton = closeButton;
				end
			}
		}
	});

	-- create settings bar menu at top right corner of screen
	-- turn music off by default
	scene.settingsBarMenu = FRC_SettingsBar.new({
		parent = view,
		imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_up.png',
		imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_down.png',
		focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_focused.png',
		disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_Settings_disabled.png',
		buttonWidth = 100,
		buttonHeight = 100,
		buttonPadding = 15,
alwaysVisible = true,
		bgColor = { 1, 1, 1, .95 },
		buttons = {
			{
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_SoundMusic_focused.png',
				isFocused = FRC_AppSettings.get("ambientSoundOn"),
				onPress = function(event)
					local self = event.target;
					if (FRC_AppSettings.get("ambientSoundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("ambientSoundOn", false);
						FRC_AudioManager:findGroup("ambientMusic"):pause();
					else
						self:setFocusState(true);
						FRC_AppSettings.set("ambientSoundOn", true);
						FRC_AudioManager:findGroup("ambientMusic"):resume();
					end
				end
			}
		}
	});
end

function scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;

	physics.start();
	physics.addBody( scene.floor, "static", {friction=0.9, bounce=0.8} );

	for i=1, titleAnimationSequences.numChildren do
		titleAnimationSequences[i]:play({
			showLastFrame = false,
			playBackward = false,
			autoLoop = false,
			palindromicLoop = false,
			delay = 0,
			intervalTime = 30,
			maxIterations = 1,
			transformations = {xTransform = 430},
			onCompletion = function ()
				-- after the title animation, we will play the introduction sequences only
				ambientAnimationSequences[i]:play({autoLoop = true, intervalTime = 30, transformations = {xTransform = 430} });
			end
		});
	end

end

function scene.exitScene(self, event)
	local scene = self;
	-- we need to clear the animations from the screen
	if (titleAnimationSequences) then
		for i=1, titleAnimationSequences.numChildren do
			local anim = titleAnimationSequences[i];
			if (anim) then
				-- if (anim.isPlaying) then
					anim.dispose();
				-- end
				-- anim.remove();
			end
		end
		titleAnimationSequences = nil;
	end
	if (ambientAnimationSequences) then
		for i=1, ambientAnimationSequences.numChildren do
			local anim = ambientAnimationSequences[i];
			if (anim) then
				-- if (anim.isPlaying) then
					anim.dispose();
				-- end
				-- anim.remove();
			end
		end
		ambientAnimationSequences = nil;
	end
end

function scene.didExitScene(self, event)
	local scene = self;
	local view = scene.view;

	if (scene.actionBarMenu) then
		scene.actionBarMenu:dispose();
		scene.actionBarMenu = nil;
	end

	if (scene.settingsBarMenu) then
		scene.settingsBarMenu:dispose();
		scene.settingsBarMenu = nil;
	end

	storyboard.purgeScene("Scenes.ReadBook");
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;
