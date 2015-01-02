local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AnimationManager = require('FRC_Modules.FRC_AnimationManager.FRC_AnimationManager');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local math_random = math.random;

local animationSequences = {};
local animationXMLBase = 'FRC_Assets/GENU_Assets/Animation/XMLData/';
local animationImageBase = 'FRC_Assets/GENU_Assets/Animation/Images/';

local scene = storyboard.newScene();
local webView;

scene.backHandler = function()
	if (webView) then
		webView.closeButton:dispatchEvent({
			name = "release",
			target = webView.closeButton
		});
	else
		native.showAlert('Exit?', 'Are you sure you want to exit the app?', { "Cancel", "OK" }, function(event)
			if (event.index == 2) then
				native.requestExit();
			end
		end);
	end
end

function scene.playTheme1()
	-- DEBUG:
	print("playing THEME1");
	ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		ambientMusic:play("UofChewTheme1", { onComplete = function() scene.playTheme2(); end } );
		if (not FRC_AppSettings.get("ambientSoundOn")) then
			-- DEBUG:
			print("scene.playTheme1 - PAUSING AMBIENT MUSIC");
			ambientMusic:pause();
		end
	end
end

function scene.playTheme2()
	-- DEBUG:
	print("playing THEME2");
	ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
	if ambientMusic then
		ambientMusic:play("UofChewTheme2", { onComplete = function() scene.playTheme1(); end } );
		if (not FRC_AppSettings.get("ambientSoundOn")) then
			-- DEBUG:
			print("scene.playTheme2 - PAUSING AMBIENT MUSIC");
			ambientMusic:pause();
		end
	end
end

function scene.removeControls(self)
	local transArray = {};
	scene.buttonIsActive = true;
	-- transArray[ #transArray + 1 ] = transition.to( readButton, { time = 500, y = 460, alpha = 0 });
	transArray[ #transArray + 1 ] = transition.to( playButton, { time = 500, y = 460, alpha = 0 });
	transArray[ #transArray + 1 ] = transition.to( createButton, { time = 500, y = 460, alpha = 0 });
	transArray[ #transArray + 1 ] = transition.to( learnButton, { time = 500, y = 460, alpha = 0 });
	transArray[ #transArray + 1 ] = transition.to( discoverButton, { time = 500, y = 460, alpha = 0 });
	transArray[ #transArray + 1 ] = transition.to( aboutButton, { time = 500, y = 460, alpha = 0 });
	-- transArray[ #transArray + 1 ] = transition.to( shopButton, { time = 500, y = 460, alpha = 0 });
end

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';
	local videoBase = 'FRC_Assets/GENU_Assets/Videos/';

	-- animations for main navigation buttons at the bottom of the screen
	local transArray = {};
	local swingButtonLeft, swingButtonRight;
	function swingButtonLeft( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,400), rotation = 10, transition = easing.inOutQuad, onComplete = function() swingButtonRight( button ) end } )
	end

	function swingButtonRight( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,400), rotation = -10, transition = easing.inOutQuad, onComplete = function() swingButtonLeft( button ) end } )
	end

	-- set up the display of the background image and logo
	local bg = display.newGroup();
	bg.anchorChildren = false;
	bg.anchorX = 0.5;
	bg.anchorY = 0.5;

	-- set up the background
	local bgImage = display.newImageRect(animationImageBase .. 'GENU_Home_LandingPage_Background.png', 1152, 768);
	bg:insert(bgImage);
	bgImage.alpha = 0;
	FRC_Layout.scaleToFit(bgImage);
	bgImage.x, bgImage.y = 0, 0;

	transArray[ #transArray + 1 ] = transition.to( bgImage, { delay = 0, time = 300, alpha = 1, transition = easing.inOutQuad});
	-- setup the logo animation
	local bgLogo = display.newImageRect(animationImageBase .. 'GENU_Home_LandingPage_Logo.png', 1152, 768);
	bg:insert(bgLogo);

	bgLogo.xScale = 0.001;
	bgLogo.yScale = 0.001;
	bgLogo.rotation = math.random(-45, 45);
	local rotation = bgLogo.rotation * 0.25;

	-- set up the book logo
	local bookLogo = display.newImageRect(animationImageBase .. 'GENU_LandingPage_TitleSpaced.png', 1152, 768);
	bg:insert(bookLogo);
	bookLogo.alpha = 0;

	transArray[ #transArray + 1 ] = transition.to( bgLogo, { delay = 0, time = 750, y = -120, rotation = rotation, xScale = 1.25, yScale = 1.25, transition = easing.inOutQuad, onComplete = function()
		transArray[ #transArray + 1  ] = transition.to( bgLogo, { time = 250, rotation = 0, xScale = .75, yScale = .75, transition = easing.inExpo, onComplete = function()
			transArray[ #transArray + 1  ] = transition.to( bgLogo, { delay = 3000, time = 1000, alpha = 0, transition = easing.inExpo });
			transArray[ #transArray + 1  ] = transition.to( bookLogo, { delay = 3750, time = 1000, alpha = 1, transition = easing.inExpo })
		end })
	end
 })


	local button_xOffset = 96;

  -- this version of readButton plays a video

--	if (_G.APP_Settings.storybookOn) then
		-- play the storybook

--	end
	-- else
	--
	-- 	-- play the video
	-- 	local readButton = ui.button.new({
	-- 		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Read_up.png',
	-- 		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Read_down.png',
	-- 		width = 128,
	-- 		height = 64,
	-- 		x = -416 + button_xOffset,
	-- 		y = 340,
	-- 		onRelease = function()
	-- --			native.showAlert("U of Chew", "Coming Soon!", { "OK" });
	-- 			local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
	-- 			local scaleFactor = math.floor( deviceWidth / display.contentWidth )
	-- 			local videoDidPlay = false;
	-- 			local videoFile, learnVideo, videoDuration, onComplete;
	--
	-- 			local videoBg = display.newRect(0, 0, screenW, screenH);
	-- 			videoBg:setFillColor(0, 0, 0, 1.0);
	-- 			videoBg.x, videoBg.y = display.contentCenterX, display.contentCenterY;
	-- 			--videoBg:addEventListener('tap', function() return true; end);
	-- 			videoBg:addEventListener('touch', function()
	-- 				videoDidPlay = true;
	-- 				onComplete();
	-- 				return true;
	-- 			end);
	--
	-- 			if (_G.ANDROID_DEVICE) then
	-- 				videoFile = videoBase .. 'GENU_Promo_640x360iPad.mp4';
	-- 				videoDuration = 31798;
	-- 			else
	-- 				if scaleFactor == 2 then
	-- 					videoFile = videoBase .. 'GENU_Promo_1280x72024fps.mp4';
	-- 					videoDuration = 31792;
	-- 				else
	-- 					videoFile = videoBase .. 'GENU_Promo_640x360iPad.mp4';
	-- 					videoDuration = 31798;
	-- 				end
	-- 			end
	-- 			onComplete = function(event)
	-- 				audio.stop(1);
	-- 				if (videoBg) then
	-- 					videoBg:removeSelf();
	-- 					videoBg = nil;
	-- 				end
	-- 				if (learnVideo) then
	-- 					learnVideo:pause();
	-- 					learnVideo:removeSelf();
	-- 					learnVideo = nil;
	-- 				end
	-- 			end
	--			FRC_AudioManager:findGroup("ambientMusic"):pause();
	-- 			--media.playVideo(videoFile, true, onComplete);
	--
	-- 			if (system.getInfo("environment") == "simulator") then
	-- 				onComplete();
	-- 			end
	--
	-- 			learnVideo = native.newVideo(0, 0, screenW, screenH);
	-- 			learnVideo.x = display.contentWidth * 0.5;
	-- 			learnVideo.y = display.contentHeight * 0.5;
	-- 			learnVideo:addEventListener("video", function(event)
	-- 				if (event.phase == "ready") and (not videoDidPlay) then
	-- 					videoDidPlay = true;
	-- 					learnVideo:play();
	-- 					timer.performWithDelay(videoDuration, onComplete, 1);
	-- 				end
	-- 			end);
	-- 			learnVideo:load(videoFile);
	-- 		end
	-- 	});

	local playButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Play_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Play_down.png',
		width = 175,
		height = 54,
		x = -494 + button_xOffset,
		y = 330,
		onRelease = function()
			if scene.buttonIsActive then return; end
			scene.removeControls();
			storyboard.gotoScene('Scenes.Games');
		end
	});
	bg:insert(playButton);
	transArray[ #transArray + 1 ] = transition.from( playButton, { delay = math.random(1,500), time = 500, y = 420, alpha = 0, rotation = math.random( -15, 15 ) });
	swingButtonRight(playButton);
	-- transArray[ #transArray + 1 ] = transition.to( playButton, { delay = math.random(1,1500), onComplete = function() swingButtonRight(playButton) end } );

	local createButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Create_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Create_down.png',
		width = 175,
		height = 54,
		x = -287 + button_xOffset,
		y = 330,
		onRelease = function()
			scene.removeControls();
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			timer.performWithDelay(600, function() storyboard.gotoScene('Scenes.ArtCenter'); end, 1);
			-- storyboard.gotoScene('Scenes.ArtCenter');
		end
	});
	bg:insert(createButton);
	transArray[ #transArray + 1 ] = transition.from( createButton, { delay = math.random(1,500), time = 500, y = 420, alpha = 0, rotation = math.random( -15, 15 ) });
	swingButtonLeft(createButton);

	local discoverButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Discover_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Discover_down.png',
		width = 175,
		height = 54,
		x = -80 + button_xOffset,
		y = 330,
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
			-- DEBUG
			-- native.showAlert("Platform", devicePlatformName);
			-- webView:request("http://fatredcouch.com/page.php?t=products&p=" .. devicePlatformName);
			webView:request("http://genuwinhealth.com");


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
	bg:insert(discoverButton);
	transArray[ #transArray + 1 ] = transition.from( discoverButton, { delay = math.random(1,500), time = 500, y = 420, alpha = 0, rotation = math.random( -15, 15 ) });
	swingButtonRight(discoverButton);

	local learnButton = ui.button.new({
		imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_Learn_up.png',
		imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_Learn_down.png',
		width = 175,
		height = 54,
		x = 127 + button_xOffset,
		y = 330,
 		onRelease = function()
 			local deviceWidth = ( display.contentWidth - (display.screenOriginX * 2) ) / display.contentScaleX
 			local scaleFactor = math.floor( deviceWidth / display.contentWidth )
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
 			end);

 			if (_G.ANDROID_DEVICE) then
 				videoFile = videoBase .. 'GENU_Learn_LetsMove_SD.mp4';
 				videoDuration = 172000;
 			else
 				if scaleFactor == 2 then
 					videoFile = videoBase .. 'GENU_Learn_LetsMove_HD.mp4';
 					videoDuration = 172000;
 				else
 					videoFile = videoBase .. 'GENU_Learn_LetsMove_SD.mp4';
 					videoDuration = 172000;
 				end
 			end
 			onComplete = function(event)
 				audio.stop(1);
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

	});
	bg:insert(learnButton);
	transArray[ #transArray + 1 ] = transition.from( learnButton, { delay = math.random(1,500), time = 500, y = 420, alpha = 0, rotation = math.random( -15, 15 ) });
	swingButtonRight(learnButton);


	local aboutButton = ui.button.new({
	imageUp = imageBase .. 'GENU_LandingPage_NavigationButton_About_up.png',
	imageDown = imageBase .. 'GENU_LandingPage_NavigationButton_About_down.png',
	width = 175,
	height = 54,
	x = 334 + button_xOffset,
	y = 330,
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
		webView:request("Help/GENU_FRC_WebOverlay_Learn_Credits.html", system.DocumentsDirectory);

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
	});
	bg:insert(aboutButton);
	transArray[ #transArray + 1 ] = transition.from( aboutButton, { delay = math.random(1,500), time = 500, y = 420, alpha = 0, rotation = math.random( -15, 15 ) });
	swingButtonLeft(aboutButton);


	-- position background image at correct location
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;

	view:insert(bg);

	--if (not buildText) then
		local buildText = display.newEmbossedText(view, FRC_AppSettings.get("version") .. ' (' .. system.getInfo('build') .. ')', 0, 0, native.systemFontBold, 11);
		buildText:setFillColor(1, 1, 1);
		buildText.anchorX = 1.0;
		buildText.anchorY = 1.0;
		buildText.x = screenW - ((screenW - display.contentWidth) * 0.5) - 5;
		buildText.y = screenH - ((screenH - display.contentHeight) * 0.5); -- - 7;
	--end
	--]]

	-- setup array of animation sequences
	local titleAnimationFiles = {
		"Macho_Cheer_Loop.xml"
	};
	-- preload the animation data (XML and images) early
	titleAnimationSequences = FRC_AnimationManager.createAnimationClipGroup(titleAnimationFiles, animationXMLBase, animationImageBase);
	FRC_Layout.scaleToFit(titleAnimationSequences, 400, -100);
	-- titleAnimationSequences.y = titleAnimationSequences.y + bg.contentBounds.yMin;
	view:insert(titleAnimationSequences);


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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_down.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_FRC_up.png',
				onRelease = function(e)
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
	local musicButtonFocused = false;
	-- DEBUG:
	print("INIT ambientSoundOn: ", FRC_AppSettings.get("ambientSoundOn"));
	if (FRC_AppSettings.get("ambientSoundOn")) then musicButtonFocused = true; end
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
				isFocused = musicButtonFocused,
				onPress = function(event)
					local self = event.target;
					if (FRC_AppSettings.get("ambientSoundOn")) then
						self:setFocusState(false);
						FRC_AppSettings.set("ambientSoundOn", false);
						local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
						if ambientMusic then
							ambientMusic:pause();
						end
					else
						self:setFocusState(true);
						FRC_AppSettings.set("ambientSoundOn", true);
						local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
						if ambientMusic then
							ambientMusic:resume();
						end
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
	-- this should only happen the first time that the application is launched
	if (FRC_AppSettings.get("freshLaunch")) then
		for i=1, titleAnimationSequences.numChildren do
			titleAnimationSequences[i]:play({
				showLastFrame = false,
				playBackward = false,
				autoLoop = true,
				palindromicLoop = false,
				delay = 3,
				intervalTime = 30,
				maxIterations = 1,
				onCompletion = function ()
					-- after the title animation, we will play the introduction sequences only
					-- ambientAnimationSequences[i]:play({autoLoop = true, intervalTime = 30});
				end
			});
		end
	else

	end

	local ambientMusic = FRC_AudioManager:findGroup("ambientMusic");
  if (FRC_AppSettings.get("freshLaunch")) then
		FRC_AppSettings.set("freshLaunch", false);
		-- setup a delay for device playback
		if (system.getInfo("environment") == "simulator") then
			-- DEBUG:
			print("freshLaunch playing TitleAudio");
			-- DEBUG:
			print("ambientSoundOn: ",  FRC_AppSettings.get("ambientSoundOn"));
			ambientMusic:play("TitleAudio", { onComplete = function()
					scene.playTheme1();
				end, 1 } );
			if (not FRC_AppSettings.get("ambientSoundOn")) then
				-- DEBUG:
				print("ambientMusic:pause");
				timer.performWithDelay(1, function()
					ambientMusic:pause();
				end, 1);
			end
		else
			timer.performWithDelay(1000, function()
				ambientMusic:play("TitleAudio", { onComplete = function()
						scene.playTheme1();
					end } );
				if (not FRC_AppSettings.get("ambientSoundOn")) then
					-- DEBUG:
					print("ambientMusic:pause");
					timer.performWithDelay(1, function()
						ambientMusic:pause();
					end, 1);
				end
			end, 1);
		end

		-- set the volume to 1 just after starting up playback to avoid the "pop" heard when
		-- starting playback and then pausing it
		ambientMusic:setVolume(1.0);
	else
		-- DEBUG:
		print("HOME scene background audio");
		if (ambientMusic) then
			-- resume the background theme song that was playing when we left the Home scene
			if (not FRC_AppSettings.get("ambientSoundOn")) then
				-- DEBUG:
				print("ambientMusic:pause");
				ambientMusic:pause();
			else
				-- DEBUG:
				print("HOME scene RESUME background audio");
				ambientMusic:resume();
			end
		else
			-- fallback to restarting one of the background theme songs
			scene.playTheme1();
		end
	end

	-- show "Rate It" dialog
	-- TODO:  we need to move this so it doesn't happen until the user returns BACK to the Home scene from another scene
	require("FRC_Modules.FRC_Ratings.FRC_Ratings").ask();
end

function scene.exitScene(self, event)
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
	ui:dispose();
end

function scene.didExitScene(self, event)
	local scene = self;
	scene.buttonIsActive = false;
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
