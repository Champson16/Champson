local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local math_random = math.random;

local animationXMLBase = 'FRC_Assets/GENU_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/GENU_Assets/Animation/Images/';
local introAnimationSequences = {};
local ambientAnimationSequences = {};

local braineryWebview;

local scene = storyboard.newScene();

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';


	-- SET UP ANIMATIONS

	local introAnimationFiles = {
	"GENU_Animation_global_Brainery_idle_h.xml",
	"GENU_Animation_global_Brainery_idle_g.xml",
	"GENU_Animation_global_Brainery_idle_f.xml",
	"GENU_Animation_global_Brainery_idle_e.xml",
	"GENU_Animation_global_Brainery_idle_d.xml",
	"GENU_Animation_global_Brainery_idle_c.xml",
	"GENU_Animation_global_Brainery_idle_b.xml",
	"GENU_Animation_global_Brainery_idle_a.xml"
	};
	-- preload the animation data (XML and images) early
	introAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(introAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(introAnimationSequences);
	view:insert(introAnimationSequences);

	FRC_AudioManager:newHandle({
		name = "BraineryIdle",
		path = "FRC_Assets/GENU_Assets/Audio/GENU_Animation_global_Brainery.mp3",
		group = "ambientMusic",
		useLoadSound = true
	});


	local bgGroup = display.newGroup();
	bgGroup.anchorChildren = false;
	bgGroup.anchorX = 0.5;
	bgGroup.anchorY = 0.5;

	bgGroup.x = display.contentCenterX;
	bgGroup.y = display.contentCenterY;
	view:insert(bgGroup);

	-- TEST addition to add background image
	local bg = display.newGroup();
	bg.anchorChildren = false;
	FRC_Layout.scaleToFit(bg);
	local bgImage = display.newImageRect(animationImageBase .. 'GENU_Animation_ComingSoonDialogueFrame.png', 1152, 768);
	bg:insert(bgImage);
	bgImage.x, bgImage.y = 0, 0;
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	view:insert(bg);

	--[[ local bgImage = display.newImageRect(animationImageBase .. 'GENU_Animation_ComingSoonDialogueFrame.png', 1152, 768);
	bgImage.anchorX = 0.5;
	bgImage.anchorY = 0.5;
	bgGroup:insert(bgImage);
	bgImage.x, bgImage.y = 0, 0;
	--]]

	-- lay in all of the map overlay buttons
	local moduleCloseButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Button_global_Ok_up.png',
		imageDown = imageBase .. 'GENU_Button_global_Ok_down.png',
		width = 213,
		height = 74,
		x = 940 - 576;
		y = 654 - 384;
		onRelease = function()
			storyboard.gotoScene('Scenes.Home', { effect="crossFade", time="250" });
		end
	});
	moduleCloseButton.anchorX = 0.5;
	moduleCloseButton.anchorY = 0.5;
	bgGroup:insert(moduleCloseButton);

	local function goHome()
		storyboard.gotoScene('Scenes.Home', { effect="crossFade", time="250" });
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
					webView:request("Help/GENU_FRC_WebOverlay_Help_Main.html", system.DocumentsDirectory);

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

	-- create settings bar menu at top left corner of screen
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
	local ambientMusic;

	native.setActivityIndicator(false);

	-- now let's animate everything!
	if introAnimationSequences then
		for i=1, introAnimationSequences.numChildren do
			introAnimationSequences[i]:play({
				showLastFrame = false,
				playBackward = false,
				autoLoop = true,
				palindromicLoop = false,
				delay = 3,
				intervalTime = 30,
				maxIterations = 1
			});
		end
		ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
		if ambientMusic then
			ambientMusic:stop();
			ambientMusic:play("BraineryIdle", {loops = -1});
			if (not FRC_AppSettings.get("ambientSoundOn")) then
				timer.performWithDelay(1, function()
					ambientMusic:pause();
					end, 1);
			end
		end
	end
	--[[
	-- alternate approach using a webview
	local screenW, screenH = FRC_Layout.getScreenDimensions();
	local xScale = screenW / 1152;
	local yScale = screenH / 768;
	local webviewProps = {};
	if (xScale > yScale) then
		webviewProps.xScale = xScale;
		webviewProps.yScale = xScale;
	else
		webviewProps.xScale = yScale;
		webviewProps.yScale = yScale;
	end
	local webviewTop = 0;
	local webviewLeft = 0;
	local webviewWidth = 921 * webviewProps.xScale;
	local webviewHeight = 615 * webviewProps.yScale;
	braineryWebview = native.newWebView(0, 0, webviewWidth, webviewHeight);
	braineryWebview.x = display.contentCenterX;
	braineryWebview.y = display.contentCenterY;
	braineryWebview:request("Help/GENU_FRC_WebOverlay_Brainery.html", system.DocumentsDirectory);
	--]]
end

function scene.exitScene(self, event)
	if braineryWebview then
		braineryWebview:removeSelf();
		braineryWebview = nil;
	end
	-- we need to clear the animations from the screen
	if (introAnimationSequences and introAnimationSequences.numChildren) then
		for i=1, introAnimationSequences.numChildren do
			local anim = introAnimationSequences[i];
			if (anim) then
				-- if (anim.isPlaying) then
				anim.dispose();
				-- end
				-- anim.remove();
			end
		end
		introAnimationSequences = nil;
	end
	if (ambientAnimationSequences and ambientAnimationSequences.numChildren) then
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
	local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		ambientMusic:stop();
	end
	ui:dispose();
end

function scene.didExitScene(self, event)
	local scene = self;
	scene.actionBarMenu:dispose();
	scene.actionBarMenu = nil;
	scene.settingsBarMenu:dispose();
	scene.settingsBarMenu = nil;
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;
