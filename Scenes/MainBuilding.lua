local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local math_random = math.random;

local scene = storyboard.newScene();

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';
	local videoBase = 'FRC_Assets/GENU_Assets/Videos/';

	local transArray = {};
	local swingButtonLeft, swingButtonRight;
	local auditoriumButton, auditoriumBackground, auditoriumVideoButton; -- forward declarations
	local libraryButton, libraryBackground, appInfoButton, brandButton, castButton; -- forward declarations

	function swingButtonLeft( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,800), rotation = 10, transition = easing.inOutQuad, onComplete = function() swingButtonRight( button ) end } )
	end

	function swingButtonRight( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,800), rotation = -10, transition = easing.inOutQuad, onComplete = function() swingButtonLeft( button ) end } )
	end

	local bg = display.newGroup();
	bg.anchorChildren = false;
	bg.anchorX = 0.5;
	bg.anchorY = 0.5;

	local bgImage = display.newImageRect(imageBase .. 'GENU_MainBuilding_en_Background.png', 1152, 768);
	bg:insert(bgImage);

	FRC_Layout.scaleToFit(bgImage);
	bgImage.x, bgImage.y = 0, 0;

	-- bg.xScale = screenW / display.contentWidth;
	-- bg.yScale = bg.xScale;

	-- position background image at correct location
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;

	function playAuditoriumVideo()
		local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX;
		local scaleFactor = math.floor( deviceWidth / display.contentWidth );
		local videoDidPlay = false;
		local videoFile, learnVideo, videoDuration, onComplete;
		local videoBg = display.newRect(0, 0, screenW, screenH);
		videoBg:setFillColor(0, 0, 0, 1.0);
		videoBg.x, videoBg.y = display.contentCenterX, display.contentCenterY;
		--videoBg:addEventListener('tap', function() return true; end);
		videoBg:addEventListener('touch', function()
			videoDidPlay = true;
			onComplete();
			return true;
		end
		);

		if (_G.ANDROID_DEVICE) then
			videoFile = videoBase .. 'GENU_DrGerardRoberts_GenUwinHealthMission_SD.mp4';
			videoDuration = 62000;
		else
			if scaleFactor == 2 then
				videoFile = videoBase .. 'GENU_DrGerardRoberts_GenUwinHealthMission_HD.mp4';
				videoDuration = 62000;
			else
				videoFile = videoBase .. 'GENU_DrGerardRoberts_GenUwinHealthMission_SD.mp4';
				videoDuration = 62000;
			end
		end
		onComplete = function(event)
			audio.stop(1); -- ??
			if (videoBg) then
				videoBg:removeSelf();
				videoBg = nil;
			end
			if (learnVideo) then
				learnVideo:pause();
				learnVideo:removeSelf();
				learnVideo = nil;
			end
		end
		FRC_AudioManager:findGroup("ambientMusic"):pause();
		--media.playVideo(videoFile, true, onComplete);

    -- skip the video if we are on the Simulator
		if (system.getInfo("environment") == "simulator") then
			onComplete();
		end

		learnVideo = native.newVideo(0, 0, screenW, screenH);
		learnVideo.x = display.contentWidth * 0.5;
		learnVideo.y = display.contentHeight * 0.5;
		learnVideo:addEventListener("video", function(event)
			if (event.phase == "ready") and (not videoDidPlay) then
				videoDidPlay = true;
				learnVideo:play();
				timer.performWithDelay(videoDuration, onComplete, 1);
			end
			end);
			learnVideo:load(videoFile);
	end

	auditoriumButton = ui.button.new({
		imageUp = imageBase .. 'GENU_MainBuilding_en_Auditorium_up.png',
		imageDown = imageBase .. 'GENU_MainBuilding_en_Auditorium_down.png',
		width = 301,
		height = 371,
		x = 524 - 576,
		y = 307 - 368,
		onRelease = function()
			-- we need to cover the screen with a background, new video playback buttons and then respond to the button
			auditoriumBackground.alpha = 1; -- show it
			auditoriumVideoButton.alpha = 1;
		end
	});
	auditoriumButton.anchorX = 0.5;
	auditoriumButton.anchorY = 0.5;
	bg:insert(auditoriumButton);

	libraryButton = ui.button.new({
		imageUp = imageBase .. 'GENU_MainBuilding_en_Library_up.png',
		imageDown = imageBase .. 'GENU_MainBuilding_en_Library_down.png',
		width = 295,
		height = 328,
		x = 798 - 576,
		y = 324 - 368,
		onRelease = function()
			libraryBackground.alpha = 1; -- show it
			uOfChewCastButton.alpha = 1;
			tasteeTownCastButton.alpha = 1;
		end
	});
	libraryButton.anchorX = 0.5;
	libraryButton.anchorY = 0.5;
	bg:insert(libraryButton);

	auditoriumBackground = display.newImageRect(imageBase .. 'GENU_Theater_global_TheaterBackground.png', 1152, 768);
	bg:insert(auditoriumBackground);
	FRC_Layout.scaleToFit(auditoriumBackground);
	auditoriumBackground.x, auditoriumBackground.y = 0, 0;
	auditoriumBackground.alpha = 0; -- hide this by default

	auditoriumVideoButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Theater_global_TheaterPlayPreview_up.png',
		imageDown = imageBase .. 'GENU_Theater_global_TheaterPlayPreview_down.png',
		width = 844,
		height = 528,
		x = 1,
		y = 330 - 368,
		onRelease = function()
			playAuditoriumVideo();
		end
	});
	auditoriumVideoButton.alpha = 0; -- hide this by default
	auditoriumVideoButton.anchorX = 0.5;
	auditoriumVideoButton.anchorY = 0.5;
	bg:insert(auditoriumVideoButton);


	libraryBackground = display.newImageRect(imageBase .. 'GENU_Library_global_Background.png', 1152, 768);
	bg:insert(libraryBackground);
	FRC_Layout.scaleToFit(libraryBackground);
	libraryBackground.x, libraryBackground.y = 0, 0;
	libraryBackground.alpha = 0; -- hide this by default

	uOfChewCastButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Library_global_UofChewCast_up.png',
		imageDown = imageBase .. 'GENU_Library_global_UofChewCast_down.png',
		width = 384,
		height = 314,
		x = 340 - 578,
		y = 414 - 368,
		onRelease = function()
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
			local devicePlatformName = import("platform").detected;
			webView:request("Help/GENU_FRC_WebOverlay_Library_UofChewCast.html", system.DocumentsDirectory);

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
	uOfChewCastButton.alpha = 0; -- hide this by default
	uOfChewCastButton.anchorX = 0.5;
	uOfChewCastButton.anchorY = 0.5;
	bg:insert(uOfChewCastButton);

	tasteeTownCastButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Library_global_TasteeTownCast_up.png',
		imageDown = imageBase .. 'GENU_Library_global_TasteeTownCast_down.png',
		width = 384,
		height = 314,
		x = 813 - 578,
		y = 414 - 368,
		onRelease = function()
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
			local devicePlatformName = import("platform").detected;
			webView:request("Help/GENU_FRC_WebOverlay_Library_TasteeTownCast.html", system.DocumentsDirectory);

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
	tasteeTownCastButton.alpha = 0; -- hide this by default
	tasteeTownCastButton.anchorX = 0.5;
	tasteeTownCastButton.anchorY = 0.5;
	bg:insert(tasteeTownCastButton);

	view:insert(bg);

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
end

function scene.exitScene(self, event)
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
