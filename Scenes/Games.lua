local ui = require('ui');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local storyboard = require('storyboard');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local math_random = math.random;

local scene = storyboard.newScene();

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;

	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local imageBase = 'FRC_Assets/GENU_Assets/Images/';

	local transArray = {}
	local swingButtonLeft, swingButtonRight
	function swingButtonLeft( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,800), rotation = 10, transition = easing.inOutQuad, onComplete = function() swingButtonRight( button ) end } )
	end

	function swingButtonRight( button )
		transArray[ #transArray + 1] = transition.to( button, { time = 1200 + math.random(1,800), rotation = -10, transition = easing.inOutQuad, onComplete = function() swingButtonLeft( button ) end } )
	end

	local bg = display.newGroup();
	bg.anchorChildren = true;
	bg.anchorX = 0.5;
	bg.anchorY = 0.5;

	local bgImage = display.newImageRect(imageBase .. 'GENU_Games_LandingPageBackground.jpg', 1152, 768);
	bg:insert(bgImage);

	bg.xScale = screenW / display.contentWidth;
	bg.yScale = bg.xScale;

	-- position background image at correct location
	bgImage.x = display.contentCenterX;
	bgImage.y = display.contentCenterY;
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	view:insert(bg);

	local puzzleButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Games_NavigationButton_JigsawPuzzles_up.png',
		imageDown = imageBase .. 'GENU_Games_NavigationButton_JigsawPuzzles_down.png',
		width = 363,
		height = 94,
		x = display.contentCenterX - 100,
		y = display.contentCenterY - 80,
		onRelease = function()
			--audio.pause(1);
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			storyboard.gotoScene('Scenes.JigsawPuzzle');
		end
	});
	bg:insert(puzzleButton);
	timer.performWithDelay(math.random(1,1000), function() swingButtonLeft(puzzleButton); end, 1);

	local concentrationButton = ui.button.new({
		imageUp = imageBase .. 'GENU_Games_NavigationButton_Concentration_up.png',
		imageDown = imageBase .. 'GENU_Games_NavigationButton_Concentration_down.png',
		width = 363,
		height = 94,
		x = display.contentCenterX + 100,
		y = display.contentCenterY + 80,
		onRelease = function()
			--audio.pause(1);
			if (not _G.ANDROID_DEVICE) then native.setActivityIndicator(true); end
			storyboard.gotoScene('Scenes.MemoryGame');
		end
	});
	bg:insert(concentrationButton);
	timer.performWithDelay(math.random(1,1000), function() swingButtonRight(concentrationButton); end, 1);

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
						AudioManager:findGroup("ambientMusic"):pause();
					else
						self:setFocusState(true);
						FRC_AppSettings.set("ambientSoundOn", true);
						AudioManager:findGroup("ambientMusic"):resume();
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
