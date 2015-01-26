local ui = require('FRC_Modules.FRC_UI.FRC_UI');
local storyboard = require('storyboard');
local FRC_Layout = require('FRC_Modules.FRC_Layout.FRC_Layout');
local FRC_MemoryGame = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame');
local FRC_MemoryGame_Settings = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Settings');
local FRC_MemoryGame_Chooser = require('FRC_Modules.FRC_MemoryGame.FRC_MemoryGame_Chooser');
local FRC_ActionBar = require('FRC_Modules.FRC_ActionBar.FRC_ActionBar');
local FRC_SettingsBar = require('FRC_Modules.FRC_SettingsBar.FRC_SettingsBar');
local FRC_AppSettings = require('FRC_Modules.FRC_AppSettings.FRC_AppSettings');
local FRC_AudioManager = require('FRC_Modules.FRC_AudioManager.FRC_AudioManager');

local scene = storyboard.newScene();
local triesVisible = true;
local restartNextGame = false;
local lastGame = nil;

local goldenCockerel = native.systemFontBold; --"Golden Cockerel ITC Std";
if (system.getInfo("platformName") == "Android") then
	goldenCockerel = native.systemFontBold; --"GoldenCockerelITCStd";
end

local imageBase = 'FRC_Assets/GENU_Assets/Images/';

-- preload memory game audios
local memoryEncouragementAudioPaths = {
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_Amazing.mp3',
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_Awesome.mp3',
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_GoodJob.mp3',
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_GreatJob.mp3',
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_IKnewYouCouldDoIt.mp3',
	'FRC_Assets/FRC_MemoryGame/Audio/GENU_en_VO_MemoryGameEncouragements_YayYouDidIt.mp3'
};

local memoryEncouragements = FRC_AudioManager:newGroup({
	name = "memory_encouragements",
	startChannel = FRC_AppSettings.get("VO_CHANNEL"),
	maxChannels = FRC_AppSettings.get("MAX_VO_CHANNELS")
});

local memorySFX = FRC_AudioManager:newGroup({
	name = "memory_sfx",
	startChannel = FRC_AppSettings.get("SFX_CHANNEL"),
	maxChannels = FRC_AppSettings.get("MAX_SFX_CHANNELS")
});

for i=1,#memoryEncouragementAudioPaths do
	FRC_AudioManager:newHandle({
		path = memoryEncouragementAudioPaths[i],
		group = memoryEncouragements
	});
end

local function beginNewGame(event)
	local scene = event.target;
	scene.chooser = nil;
	lastGame = {
		columns = event.columns,
		rows = event.rows
	};

	local game = FRC_MemoryGame.new(scene, event.columns, event.rows);
	game.anchorChildren = false;
	game.anchorX = 0.5;
	game.anchorY = 0.5;
	scene.view:insert(game);
	game.x = ((display.contentWidth - (game.contentWidth)) * 0.5) + (game[1].contentWidth * 0.5);
	game.y = ((display.contentHeight - (game.contentHeight)) * 0.5) + (game[1].contentHeight * 0.5) + 40;
	scene.game = game;

	scene.triesText = display.newEmbossedText(scene.view, "Tries: 0", 0, 0, goldenCockerel, 40);
	scene.triesText.x = display.contentCenterX;
	scene.triesText.y = (game.contentBounds.yMin * 0.5) + 5;
	scene.triesText:setFillColor(1.0, 1.0, 1.0, 1.0);
	scene.triesText.isVisible = triesVisible;

  -- enable the Options and Startover buttons
	scene.actionBarMenu.menuItems[3]:setDisabledState(false);
	scene.actionBarMenu.menuItems[5]:setDisabledState(false);

	if (triesVisible) then
		-- enabled the Tries settings button
		scene.settingsBarMenu.menuItems[3]:setDisabledState(false);
		scene.settingsBarMenu.menuItems[3]:setFocusState(true);
	end
end

local function showDifficultyChooser(event)
	-- DEBUG
	print("MEMORYGAME showDifficultyChooser");
	local scene = event.target;

	if (scene.triesText) and (scene.triesText.removeSelf) then
		scene.triesText:removeSelf();
		scene.triesText = nil;
	else
		scene.triesText = nil;
	end

  -- disable the Options and Startover buttons
	scene.actionBarMenu.menuItems[3]:setDisabledState(true);
	scene.actionBarMenu.menuItems[5]:setDisabledState(true);
	scene.settingsBarMenu.menuItems[3]:setDisabledState(true);
	scene.settingsBarMenu.menuItems[3]:setFocusState(false);

	local chooser = FRC_MemoryGame_Chooser.new(scene);
	chooser.anchorChildren = true;
	chooser.anchorX = 0.5;
	chooser.anchorY = 0.5;
	scene.view:insert(chooser);
	scene.chooser = chooser;
	chooser.x = display.contentCenterX;
	chooser.y = display.contentCenterY;
end

local function onMemoryGameOver(event)
	if (memoryEncouragements and not scene.chooser) then
		-- DEBUG:
		print("onMemoryGameOver start");
		memoryEncouragements:playRandom({ onComplete=function()
		  -- restartNextGame = false;
			-- DEBUG:
			print("onMemoryGameOver onComplete");
			showDifficultyChooser(event);
		end });
	else
		-- DEBUG
		print("WARNING: Memory game is missing encouragement audio!");
		showDifficultyChooser(event);
	end
end

function scene.createScene(self, event)
	local scene = self;
	local view = scene.view;
	local screenW, screenH = FRC_Layout.getScreenDimensions();

	local bg = display.newImageRect(view, FRC_MemoryGame_Settings.UI.SCENE_BACKGROUND, FRC_MemoryGame_Settings.UI.SCENE_BACKGROUND_WIDTH, FRC_MemoryGame_Settings.UI.SCENE_BACKGROUND_HEIGHT);
	local xScale = screenW / bg.contentWidth;
	local yScale = screenH / bg.contentHeight;
	if (xScale > yScale) then
		bg.xScale = xScale;
		bg.yScale = xScale;
	else
		bg.xScale = yScale;
		bg.yScale = yScale;
	end

	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;

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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_Options_disabled.png',
				isDisabled = true,
				onRelease = function()
					restartNextGame = false;
					storyboard.gotoScene('Scenes.MemoryGame', { useLoader=true });
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
				imageUp = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_up.png',
				imageDown = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_down.png',
				disabled = 'FRC_Assets/FRC_ActionBar/Images/FRC_ActionBar_Icon_StartOver_disabled.png',
				isDisabled = true,
				onRelease = function()
					-- restart memory game
					restartNextGame = true;
					storyboard.gotoScene('Scenes.MemoryGame', { useLoader=true });
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
					webView:request("Help/GENU_FRC_WebOverlay_Help_ConcentrationGame.html", system.DocumentsDirectory);

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
				imageUp = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_MatchCount_up.png',
				imageDown = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_MatchCount_up.png',
				focusState = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_MatchCount_focused.png',
				disabled = 'FRC_Assets/FRC_SettingsBar/Images/FRC_Settings_Icon_MatchCount_disabled.png',
				isDisabled = true,
				isFocused = false,
				onPress = function(event)
					local self = event.target;
					if (self.isDisabled) then return; end

					if (scene.triesText.isVisible) then
						self:setFocusState(false);
						scene.triesText.isVisible = false;
						triesVisible = false;
					else
						self:setFocusState(true);
						scene.triesText.isVisible = true;
						triesVisible = true;
					end
				end
			},
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

	if (not restartNextGame) then
		showDifficultyChooser({ target=scene });
	end
end

function scene.enterScene(self, event)
	local scene = self;
	local view = scene.view;
	native.setActivityIndicator(false);
	scene:addEventListener('memoryGameStart', beginNewGame);
	scene:addEventListener('memoryGameOver', onMemoryGameOver);

	if (restartNextGame) then
		restartNextGame = false;
		lastGame.target = scene;
		beginNewGame(lastGame);
	end
end

function scene.exitScene(self, event)

	-- dispose of audios
	local sfx = FRC_AudioManager:findGroup("memory_sfx");
	if sfx then
		sfx:stop();
		sfx:dispose();
	end
	local enc = FRC_AudioManager:findGroup("memory_encouragements");
	if enc then
		enc:stop();
		enc:dispose();
	end

	if (scene.game) then
		scene.game:dispose();
		scene.game = nil;
	end
end

function scene.didExitScene(self, event)
	local scene = self;
	local view = scene.view;

	scene.actionBarMenu:dispose();
	scene.actionBarMenu = nil;

	scene.settingsBarMenu:dispose();
	scene.settingsBarMenu = nil;

	scene:removeEventListener('memoryGameStart', beginNewGame);
	scene:removeEventListener('memoryGameOver', onMemoryGameOver);
end

scene:addEventListener('createScene');
scene:addEventListener('enterScene');
scene:addEventListener('exitScene');
scene:addEventListener('didExitScene');

return scene;
