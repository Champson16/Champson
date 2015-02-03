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


local scene = storyboard.newScene();

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';

	local moduleReplayButton, learnMoreButton; -- forward declarations

	-- SET UP ANIMATIONS

	local introAnimationFiles = {
		"GENU_Bodinator_Macho_h.xml",
		"GENU_Bodinator_Macho_g.xml",
		"GENU_Bodinator_Macho_f.xml",
		"GENU_Bodinator_Macho_e.xml",
		"GENU_Bodinator_Macho_d.xml",
		"GENU_Bodinator_Macho_c.xml",
		"GENU_Bodinator_Macho_b.xml",
		"GENU_Bodinator_Macho_a.xml"	};
	-- preload the animation data (XML and images) early
	introAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(introAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(introAnimationSequences);
	view:insert(introAnimationSequences);

	--[[ local ambientAnimationFiles = {
		"GENU_Animation_global_Brainery_idle_d.xml",
		"GENU_Animation_global_Brainery_idle_c.xml",
		"GENU_Animation_global_Brainery_idle_b.xml",
		"GENU_Animation_global_Brainery_idle_a.xml"
	};
	-- preload the animation data (XML and images) early
	ambientAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(ambientAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(ambientAnimationSequences);
	view:insert(ambientAnimationSequences);
	--]]

	-- setup scene audio

	FRC_AudioManager:newHandle({
		name = "BodinatorIntro",
		path = "FRC_Assets/GENU_Assets/Audio/GENU_Animation_global_Bodinator.mp3",
		group = "ambientMusic"
	});
	--[[ FRC_AudioManager:newHandle({
		name = "SugaryIdle",
		path = "FRC_Assets/GENU_Assets/Audio/ZAZOOTIME_Alarm_Kids-Bloobblubblub1.mp3",
		group = "ambientMusic"
	});
	--]]

	local bgGroup = display.newGroup();
	bgGroup.anchorChildren = false;
	bgGroup.anchorX = 0.5;
	bgGroup.anchorY = 0.5;

	bgGroup.x = display.contentCenterX;
	bgGroup.y = display.contentCenterY;
	view:insert(bgGroup);

	local bgOverlayGroup = display.newGroup();
	bgOverlayGroup.anchorChildren = false;
	bgOverlayGroup.anchorX = 0.5;
	bgOverlayGroup.anchorY = 0.5;

	bgOverlayGroup.x = display.contentCenterX;
	bgOverlayGroup.y = display.contentCenterY;
	view:insert(bgOverlayGroup);


	scene.playMainAnimation = function()
		if introAnimationSequences then
			for i=1, introAnimationSequences.numChildren do
				introAnimationSequences[i]:play({
					showLastFrame = true,
					playBackward = false,
					autoLoop = false,
					palindromicLoop = false,
					delay = 3,
					intervalTime = 30,
					maxIterations = 1,
					onCompletion = function ()
						-- display the Learn More and Replay buttons
						moduleReplayButton.alpha = 1;
						-- moduleReplayButton:toFront();
						learnMoreButton.alpha = 1;
						-- learnMoreButton:toFront();
					end
				});
			end
			ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
			if ambientMusic then
				ambientMusic:stop();
				ambientMusic:play("BodinatorIntro");
				if (not FRC_AppSettings.get("ambientSoundOn")) then
					timer.performWithDelay(1, function()
						ambientMusic:pause();
						end, 1);
					end
				end
		end
	end

	-- lay in all of the map overlay buttons
	moduleReplayButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Button_Replay_up.png',
		imageDown = imageBase .. 'GENU_Button_Replay_down.png',
		width = 320,
		height = 111,
		x = 798 - 576;
		y = 379 - 384;
		onRelease = function()
			-- hide buttons
			moduleReplayButton.alpha = 0;
			learnMoreButton.alpha = 0;
			-- replay animation
			scene.playMainAnimation();
		end
	});
	moduleReplayButton.anchorX = 0.5;
	moduleReplayButton.anchorY = 0.5;
	bgOverlayGroup:insert(moduleReplayButton);
	moduleReplayButton.alpha = 0;

	-- lay in all of the map overlay buttons
	learnMoreButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Button_LearnMore_up.png',
		imageDown = imageBase .. 'GENU_Button_LearnMore_down.png',
		width = 322,
		height = 171,
		x = 379 - 576;
		y = 379 - 384;
		onRelease = function()
			-- show HTML
			-- show HTML
			local screenRect = display.newRect(0, 0, screenW, screenH);
			screenRect.x = display.contentCenterX;
			screenRect.y = display.contentCenterY;
			screenRect:setFillColor(0, 0, 0, 0.75);
			screenRect:addEventListener('touch', function() return true; end);
			screenRect:addEventListener('tap', function() return true; end);

			local webView = native.newWebView(0, 0, screenW - 100, screenH - 55);
			webView.x = display.contentCenterX;
			webView.y = display.contentCenterY + 20;
			webView:request("http://www.letsmove.gov/obesity");
			-- webView:request("Help/GENU_FRC_WebOverlay_Bodinator.html", system.DocumentsDirectory);

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
	});
	learnMoreButton.anchorX = 0.5;
	learnMoreButton.anchorY = 0.5;
	bgOverlayGroup:insert(learnMoreButton);
	learnMoreButton.alpha = 0;


	local function goHome()
		ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
		if ambientMusic then
			ambientMusic:stop();
		end
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

	-- now let's animate everything!
	scene.playMainAnimation();
end

function scene.exitScene(self, event)
	-- we need to clear the animations from the screen
	if (introAnimationSequences) then
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
